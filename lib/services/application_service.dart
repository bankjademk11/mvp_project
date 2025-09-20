import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:appwrite/models.dart' as models;
import '../models/application.dart';
import 'appwrite_service.dart';
import 'auth_service.dart';

class ApplicationService {
  final AppwriteService _appwriteService;
  static const String _databaseId = '68bbb9e6003188d8686f';
  static const String _applicationsCollectionId = 'applications';

  ApplicationService(this._appwriteService);

  Future<List<JobApplication>> getApplications(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final response = await _appwriteService.databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _applicationsCollectionId,
        queries: [
          appwrite.Query.equal('userId', userId),
        ],
      );
      
      return response.documents
          .map((doc) => JobApplication.fromJson(doc.data))
          .toList();
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to fetch applications: ${e.message}');
    }
  }

  Future<List<models.Document>> getApplicationsForJob(String jobId) async {
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _applicationsCollectionId,
        queries: [
          appwrite.Query.equal('jobId', jobId),
          appwrite.Query.orderDesc('appliedAt'),
        ],
      );
      return response.documents;
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to fetch applications for job: ${e.message}');
    }
  }

  // New method to get a single application by ID
  Future<models.Document?> getApplicationById(String applicationId) async {
    try {
      final response = await _appwriteService.databases.getDocument(
        databaseId: _databaseId,
        collectionId: _applicationsCollectionId,
        documentId: applicationId,
      );

      // Extract applicant userId
      final applicantId = response.data['userId'] as String?;

      if (applicantId != null) {
        // Fetch applicant's profile to get avatar URL
        final authService = AuthService(_appwriteService); // Create an instance of AuthService
        final applicantProfile = await authService.getUserProfile(applicantId);

        if (applicantProfile != null) {
          String? applicantAvatarUrl;
          if (applicantProfile.role == 'employer') {
            applicantAvatarUrl = applicantProfile.companyLogoUrl;
          } else {
            applicantAvatarUrl = applicantProfile.avatarUrl;
          }

          // Create a new Document object with the added applicantAvatarUrl
          // This is a workaround as models.Document is immutable
          return models.Document(
            $id: response.$id,
            $collectionId: response.$collectionId,
            $databaseId: response.$databaseId,
            $createdAt: response.$createdAt,
            $updatedAt: response.$updatedAt,
            $permissions: response.$permissions,
            $sequence: response.$sequence, // Ensure $sequence is included
            data: {
              ...response.data,
              'applicantAvatarUrl': applicantAvatarUrl, // Add the avatar URL
            },
          );
        }
      }
      return response; // Return original response if no avatar found or applicantId is null
    } on appwrite.AppwriteException catch (e) {
      // If the document is not found, return null
      if (e.code == 404) {
        return null;
      }
      throw Exception('Failed to fetch application: ${e.message}');
    }
  }

  // This function calls the new cloud function to securely get applications for an employer
  Future<List<models.Document>> getApplicationsForEmployer(String jobId, String userId) async {
    try {
      final payload = {'jobId': jobId, 'callingUserId': userId};
      print('Calling getApplicationsForEmployer with jobId: $jobId, userId: $userId');
      
      final execution = await _appwriteService.functions.createExecution(
        functionId: '68c7ad6e002ccdeb7c17',
        body: jsonEncode(payload),
      );

      print('Cloud function execution status: ${execution.status}');
      print('Cloud function response: ${execution.responseBody}');

      if (execution.status == 'failed') {
        throw Exception('Cloud function execution failed: ${execution.responseBody}');
      }

      final responseData = jsonDecode(execution.responseBody);
      
      // Check if the response indicates success
      if (responseData is Map && responseData['success'] == false) {
        throw Exception('Cloud function error: ${responseData['message']}');
      }

      // แปลงข้อมูลที่ได้จาก Cloud function เป็น List<models.Document> อย่างระมัดระวัง
      if (responseData is Map && responseData.containsKey('documents')) {
        final List<dynamic> documentsData = responseData['documents'] as List<dynamic>;
        final List<models.Document> documents = [];

        // FINAL FIX: Manually parse the document from the cloud function response.
        // This avoids all issues with Document.fromMap() by building the object field-by-field,
        // guaranteeing the 'data' property is correctly populated.
        for (var docData in documentsData) {
          try {
            if (docData is Map<String, dynamic>) {
              // Ensure the nested 'data' map exists and is of the correct type.
              final Map<String, dynamic> dataMap = Map<String, dynamic>.from(docData['data'] ?? {});

              final document = models.Document(
                $id: docData['\$id'],
                $collectionId: docData['\$collectionId'],
                $databaseId: docData['\$databaseId'],
                $createdAt: docData['\$createdAt'],
                $updatedAt: docData['\$updatedAt'],
                $permissions: List<String>.from(docData['\$permissions']),
                // FIX: Add the required '\$sequence' parameter.
                // It's nested in the 'data' map from the cloud function's response.
                $sequence: dataMap['\$sequence'] as int? ?? 0,
                data: dataMap, // Directly assign the nested data map.
              );
              documents.add(document);
            }
          } catch (docError) {
            print('FATAL: Manual document parsing failed: $docError');
            print('Problematic docData: $docData');
            continue;
          }
        }
        
        print('Successfully fetched ${documents.length} applications');
        return documents;
      } else {
        // กรณีที่ข้อมูลไม่ได้อยู่ในรูปแบบที่คาดหวัง
        print('Unexpected response format: $responseData');
        return [];
      }

    } on appwrite.AppwriteException catch (e) {
      print('AppwriteException in getApplicationsForEmployer: ${e.message}');
      throw Exception('Failed to execute function: ${e.message}');
    } catch (e, stackTrace) {
      print('Exception in getApplicationsForEmployer: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to execute function: ${e.toString()}');
    }
  }

  // This function now calls the Appwrite Cloud Function
  Future<void> submitApplication({
    required String userId,
    required String applicantName,
    required String? teamId,
    required String jobId,
    required String jobTitle,
    required String companyName,
    String? coverLetter,
    String? resumeUrl,
  }) async {
    try {
      final payload = {
        'userId': userId,
        'applicantName': applicantName,
        'teamId': teamId,
        'jobId': jobId,
        'jobTitle': jobTitle,
        'companyName': companyName,
        'coverLetter': coverLetter,
        'resumeUrl': resumeUrl,
      };

      final execution = await _appwriteService.functions.createExecution(
        functionId: '68c54ec6000177bb4ead', // Use the Function ID, not the name
        body: jsonEncode(payload),
      );

      if (execution.status == 'failed') {
        throw Exception('Cloud function execution failed: ${execution.responseBody}');
      }

    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to execute function: ${e.message}');
    }
  }

  Future<JobApplication> updateApplicationStatus(
    String applicationId,
    ApplicationStatus newStatus,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final response = await _appwriteService.databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _applicationsCollectionId,
        documentId: applicationId,
        data: {
          'status': newStatus.value,
        },
      );
      
      return JobApplication.fromJson(response.data);
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to update application status: ${e.message}');
    }
  }

  Future<void> deleteApplication(String applicationId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await _appwriteService.databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _applicationsCollectionId,
        documentId: applicationId,
      );
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to delete application: ${e.message}');
    }
  }
  
  static final applicationServiceProvider = Provider<ApplicationService>((ref) {
    final appwriteService = ref.watch(appwriteServiceProvider);
    return ApplicationService(appwriteService);
  });
}

class ApplicationNotifier extends StateNotifier<AsyncValue<List<JobApplication>>> {
  final ApplicationService _service;
  String? _userId;
  
  ApplicationNotifier(this._service) : super(const AsyncValue.loading());

  void setUserId(String userId) {
    _userId = userId;
    if (_userId != null) {
      _loadApplications();
    }
  }

  Future<void> _loadApplications() async {
    if (_userId == null) return;
    
    try {
      final applications = await _service.getApplications(_userId!);
      state = AsyncValue.data(applications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> submitApplication({
    required String jobId,
    required String applicantName,
    required String employerId, // Keep for compatibility, but it's unused now
    required String? teamId,
    required String jobTitle,
    required String companyName,
    String? coverLetter,
    String? resumeUrl,
  }) async {
    if (_userId == null) {
      state = const AsyncValue.error('User not authenticated', StackTrace.empty);
      return;
    }
    
    try {
      await _service.submitApplication(
        userId: _userId!,
        applicantName: applicantName,
        teamId: teamId,
        jobId: jobId,
        jobTitle: jobTitle,
        companyName: companyName,
        coverLetter: coverLetter,
        resumeUrl: resumeUrl,
      );
      
      await _loadApplications();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateStatus(String applicationId, ApplicationStatus newStatus) async {
    try {
      await _service.updateApplicationStatus(applicationId, newStatus);
      await _loadApplications();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteApplication(String applicationId) async {
    try {
      await _service.deleteApplication(applicationId);
      await _loadApplications();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  void refresh() {
    _loadApplications();
  }
}

final applicationProvider = StateNotifierProvider<ApplicationNotifier, AsyncValue<List<JobApplication>>>((ref) {
  final service = ref.watch(ApplicationService.applicationServiceProvider);
  return ApplicationNotifier(service);
});