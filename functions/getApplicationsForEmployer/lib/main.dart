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
  
  // Initialize the Appwrite admin client
  final client = Client()
      .setEndpoint('https://cloud.appwrite.io/v1')
      .setProject(projectId)
      .setKey(apiKey);

  final databases = Databases(client);

  try {
    // Get data from the request payload
    final payload = jsonDecode(context.req.body);
    final String jobId = payload['jobId'];
    final String callingUserId = payload['callingUserId']; // Get from payload

    if (jobId.isEmpty || callingUserId.isEmpty) {
      throw Exception('jobId and callingUserId are required.');
    }

    // 1. Fetch the job document to verify ownership
    final jobDocument = await databases.getDocument(
      databaseId: databaseId,
      collectionId: jobsCollectionId,
      documentId: jobId,
    );

    // 2. Security Check: Verify that the user calling the function is the creator of the job
    final String jobCreatorId = jobDocument.data['creatorUserId'];
    if (jobCreatorId != callingUserId) {
      context.error('Security Alert: User $callingUserId tried to access applications for job $jobId owned by $jobCreatorId.');
      return context.res.json({
        'success': false,
        'message': 'You are not authorized to view applications for this job.',
      }, status: 403); // 403 Forbidden
    }

    // 3. If security check passes, fetch the applications using admin rights
    context.log('User $callingUserId is authorized. Fetching applications for job $jobId.');
    final applicationDocs = await databases.listDocuments(
      databaseId: databaseId,
      collectionId: applicationsCollectionId,
      queries: [
        Query.equal('jobId', jobId),
      ],
    );

    // 4. Return the list of applications
    return context.res.json(applicationDocs.toMap());

  } catch (e) {
    context.error('Error fetching applications: $e');
    return context.res.json({
      'success': false,
      'message': 'An error occurred: ${e.toString()}',
    }, status: 500);
  }
}
