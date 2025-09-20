import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

Future<dynamic> main(final context) async {
  // Environment variables
  final String projectId = Platform.environment['APPWRITE_FUNCTION_PROJECT_ID']!;
  final String apiKey = Platform.environment['APPWRITE_API_KEY']!;
  final String databaseId = Platform.environment['APPWRITE_DATABASE_ID']!;
  final String jobsCollectionId = Platform.environment['APPWRITE_JOBS_COLLECTION_ID']!;
  final String applicationsCollectionId = Platform.environment['APPWRITE_APPLICATIONS_COLLECTION_ID']!;
  // เพิ่ม environment variable สำหรับ user profiles collection
  final String userProfilesCollectionId = Platform.environment['APPWRITE_USER_PROFILES_COLLECTION_ID'] ?? 'user_profiles';
  
  context.log('Function started. Project ID: $projectId, Database ID: $databaseId');
  
  // Initialize the Appwrite admin client with timeout
  final client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject(projectId)
      .setKey(apiKey)
      .setSelfSigned(status: true);

  final databases = Databases(client);

  try {
    // Add timeout handling
    final timeoutDuration = Duration(seconds: 25); // Slightly less than Appwrite's default 30s timeout
    
    context.log('Setting up timeout handler with $timeoutDuration duration');
    
    final result = await Future.any([
      _processRequest(context, databases, databaseId, jobsCollectionId, applicationsCollectionId, userProfilesCollectionId),
      Future.delayed(timeoutDuration, () {
        context.error('Function timeout handler triggered');
        return {
          'success': false,
          'message': 'Request timeout exceeded. Please try again.',
          'timeout': true
        };
      })
    ]);

    if (result is Map && result['timeout'] == true) {
      context.error('Function execution timed out after 25 seconds');
      return context.res.json({
        'success': false,
        'message': 'Synchronous function execution timed out. Use asynchronous execution instead, or ensure the execution duration doesn\'t exceed 30 seconds.',
      }, status: 408);
    }

    // If result is already a response object, return it directly
    if (result is Map && result.containsKey('success')) {
      context.log('Function completed successfully');
      return context.res.json(result);
    }

    context.log('Function completed successfully');
    return result;

  } catch (e, stackTrace) {
    context.error('Error in main function: $e\nStack trace: $stackTrace');
    return context.res.json({
      'success': false,
      'message': 'An error occurred: ${e.toString()}',
    }, status: 500);
  }
}

Future<dynamic> _processRequest(final context, final databases, final databaseId, 
    final jobsCollectionId, final applicationsCollectionId, final userProfilesCollectionId) async {
  try {
    context.log('Processing request...');
    
    // Get data from the request payload
    final payload = jsonDecode(context.req.body);
    context.log('Payload received: $payload');
    
    final String jobId = payload['jobId'];
    final String callingUserId = payload['callingUserId']; // Get from payload

    if (jobId.isEmpty || callingUserId.isEmpty) {
      context.error('Missing required parameters: jobId or callingUserId');
      return context.res.json({
        'success': false,
        'message': 'jobId and callingUserId are required.',
      }, status: 400);
    }

    context.log('Fetching job document for jobId: $jobId');
    // 1. Fetch the job document to verify ownership
    final jobDocument = await databases.getDocument(
      databaseId: databaseId,
      collectionId: jobsCollectionId,
      documentId: jobId,
    );
    context.log('Job document fetched successfully');

    // 2. Security Check: Verify that the user calling the function is the creator of the job
    final String? jobCreatorId = jobDocument.data['creatorUserId'];
    final String? jobCompanyId = jobDocument.data['companyId'];
    
    context.log('Security check: jobCreatorId=$jobCreatorId, jobCompanyId=$jobCompanyId, callingUserId=$callingUserId');
    
    // Check if the calling user is authorized (either creator or company owner)
    bool isAuthorized = false;
    if (jobCreatorId != null && jobCreatorId.isNotEmpty) {
      // Use creatorUserId if available (newer jobs)
      isAuthorized = jobCreatorId == callingUserId;
    } else if (jobCompanyId != null && jobCompanyId.isNotEmpty) {
      // Fallback to companyId for older jobs
      isAuthorized = jobCompanyId == callingUserId;
    }
    
    if (!isAuthorized) {
      context.error('Security Alert: User $callingUserId tried to access applications for job $jobId. Job creator: $jobCreatorId, Job company: $jobCompanyId');
      return context.res.json({
        'success': false,
        'message': 'You are not authorized to view applications for this job.',
        'jobCreatorId': jobCreatorId,
        'jobCompanyId': jobCompanyId,
        'callingUserId': callingUserId,
      }, status: 403); // 403 Forbidden
    }

    // 3. If security check passes, fetch the applications using admin rights
    context.log('User $callingUserId is authorized. Fetching applications for job $jobId.');
    context.log('Querying applications with jobId: $jobId');
    
    final startTime = DateTime.now();
    final applicationDocs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: applicationsCollectionId,
      queries: [
        Query.equal('jobId', jobId),
      ],
    );
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime).inMilliseconds;
    
    context.log('Applications fetched successfully in ${duration}ms. Total applications: ${applicationDocs.total}');

    // 4. Fetch user profiles for all applicants to get avatar URLs
    context.log('Fetching user profiles for applicants...');
    
    // Collect unique userIds from applications
    final Set<String> applicantUserIds = {};
    for (var appDoc in applicationDocs.documents) {
      final userId = appDoc.data['userId'];
      if (userId != null && userId is String) {
        applicantUserIds.add(userId);
      }
    }
    
    context.log('Found ${applicantUserIds.length} unique applicants. Fetching their profiles...');
    
    // Fetch all user profiles in batch
    final Map<String, dynamic> userProfileMap = {};
    if (applicantUserIds.isNotEmpty) {
      try {
        final profileDocs = await databases.listDocuments(
          databaseId: databaseId,
          collectionId: userProfilesCollectionId,
          queries: [
            Query.equal('\$id', applicantUserIds.toList()),
          ],
        );
        
        // Map profiles by userId
        for (var profileDoc in profileDocs.documents) {
          userProfileMap[profileDoc.$id] = profileDoc.data;
        }
        
        context.log('Successfully fetched ${profileDocs.total} user profiles.');
      } catch (profileError) {
        context.error('Error fetching user profiles: $profileError');
        // Continue with applications even if profile fetching fails
      }
    }

    // 5. Enrich applications with applicant avatar/company logo URLs
    final enrichedApplications = applicationDocs.documents.map((appDoc) {
      final appData = appDoc.data;
      final userId = appData['userId'] as String?;
      
      // Get profile data for this user
      final profileData = userId != null ? userProfileMap[userId] : null;
      
      // Determine avatar/company logo URL based on user role
      String? applicantAvatarUrl;
      if (profileData != null) {
        final role = profileData['role'] as String?;
        if (role == 'employer') {
          applicantAvatarUrl = profileData['companyLogoUrl'] as String?;
        } else {
          applicantAvatarUrl = profileData['avatarUrl'] as String?;
        }
      }
      
      // Create enriched application data
      final enrichedData = {
        ...appData,
        if (applicantAvatarUrl != null) 'applicantAvatarUrl': applicantAvatarUrl,
      };
      
      // Return enriched document - fix the DateTime conversion
      return {
        '\$id': appDoc.$id,
        '\$collectionId': appDoc.$collectionId,
        '\$databaseId': appDoc.$databaseId,
        '\$createdAt': appDoc.$createdAt is DateTime 
            ? (appDoc.$createdAt as DateTime).toIso8601String() 
            : appDoc.$createdAt.toString(),
        '\$updatedAt': appDoc.$updatedAt is DateTime 
            ? (appDoc.$updatedAt as DateTime).toIso8601String() 
            : appDoc.$updatedAt.toString(),
        '\$permissions': appDoc.$permissions,
        'data': enrichedData,
      };
    }).toList();

    // 6. Return the list of enriched applications
    context.log('Returning enriched applications data');
    return context.res.json({
      'success': true,
      'documents': enrichedApplications,
      'total': applicationDocs.total,
    });

  } catch (e, stackTrace) {
    context.error('Error fetching applications: $e\nStack trace: $stackTrace');
    // More specific error handling
    if (e.toString().contains('not found') || e.toString().contains('404')) {
      return context.res.json({
        'success': false,
        'message': 'Job not found.',
      }, status: 404);
    }
    
    if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
      return context.res.json({
        'success': false,
        'message': 'Database query timeout. Please try again.',
      }, status: 408);
    }
    
    return context.res.json({
      'success': false,
      'message': 'An error occurred while fetching applications: ${e.toString()}',
    }, status: 500);
  }
}