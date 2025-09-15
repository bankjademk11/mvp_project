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