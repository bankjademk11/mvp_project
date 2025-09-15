import 'package:appwrite/appwrite.dart' as appwrite;
import 'package:appwrite/models.dart' as models;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'appwrite_service.dart';
import 'auth_service.dart';

class JobService {
  final AppwriteService _appwriteService;
  static const String _databaseId = '68bbb9e6003188d8686f';
  static const String _jobsCollectionId = 'jobs';

  JobService(this._appwriteService);

  /// Create a new job
  Future<models.Document> createJob({
    required String title,
    required String companyName,
    String? province,
    String? type,
    String? description,
    int? salaryMin,
    int? salaryMax,
    List<String>? tags,
    String? companyId,
    String? teamId, // Add this
  }) async {
    try {
      // Get the current user to associate with the job
      final currentUser = await _appwriteService.account.get();

      final data = {
        'title': title,
        'companyName': companyName,
        'province': province ?? '',
        'type': type ?? '',
        'description': description ?? '',
        'salaryMin': salaryMin,
        'salaryMax': salaryMax,
        'tags': tags ?? [],
        'companyId': companyId ?? '',
        'creatorUserId': currentUser.$id, // Save the creator's user ID
        'teamId': teamId ?? '', // Add this
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      // Create the document with permissions
      final response = await _appwriteService.databases.createDocument(
        databaseId: _databaseId,
        collectionId: _jobsCollectionId,
        documentId: appwrite.ID.unique(),
        data: data,
        permissions: [
          appwrite.Permission.read(appwrite.Role.any()), // Anyone can read the job posting
          appwrite.Permission.update(appwrite.Role.user(currentUser.$id)), // Only the creator can update
          appwrite.Permission.delete(appwrite.Role.user(currentUser.$id)), // Only the creator can delete
        ],
      );
      return response;
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to create job: Code=${e.code}, Message=${e.message}, Type=${e.type}');
    }
  }

  /// Get all jobs
  Future<List<models.Document>> getJobs() async {
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _jobsCollectionId,
        queries: [
          appwrite.Query.equal('isActive', true),
        ],
      );

      return response.documents;
    } on appwrite.AppwriteException catch (e) {
      // Provide more detailed error information
      throw Exception('Failed to fetch jobs: Code=${e.code}, Message=${e.message}, Type=${e.type}');
    }
  }

  /// Get job by ID
  Future<models.Document> getJobById(String jobId) async {
    try {
      final response = await _appwriteService.databases.getDocument(
        databaseId: _databaseId,
        collectionId: _jobsCollectionId,
        documentId: jobId,
      );

      return response;
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to fetch job: ${e.message}');
    }
  }

  /// Update job
  Future<models.Document> updateJob({
    required String jobId,
    String? title,
    String? companyName,
    String? province,
    String? type,
    String? description,
    int? salaryMin,
    int? salaryMax,
    List<String>? tags,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (title != null) data['title'] = title;
      if (companyName != null) data['companyName'] = companyName;
      if (province != null) data['province'] = province;
      if (type != null) data['type'] = type;
      if (description != null) data['description'] = description;
      if (salaryMin != null) data['salaryMin'] = salaryMin;
      if (salaryMax != null) data['salaryMax'] = salaryMax;
      if (tags != null) data['tags'] = tags;
      if (isActive != null) data['isActive'] = isActive;
      
      data['updatedAt'] = DateTime.now().toIso8601String();

      final response = await _appwriteService.databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _jobsCollectionId,
        documentId: jobId,
        data: data,
      );

      return response;
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to update job: ${e.message}');
    }
  }

  /// Delete job (set isActive to false instead of actually deleting)
  Future<models.Document> deleteJob(String jobId) async {
    try {
      final response = await _appwriteService.databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _jobsCollectionId,
        documentId: jobId,
        data: {
          'isActive': false,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );

      return response;
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to delete job: ${e.message}');
    }
  }
  
  /// Search jobs by keyword
  Future<List<models.Document>> searchJobs(String keyword) async {
    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _jobsCollectionId,
        queries: [
          appwrite.Query.equal('isActive', true),
          appwrite.Query.search('title', keyword),
        ],
      );

      return response.documents;
    } on appwrite.AppwriteException catch (e) {
      throw Exception('Failed to search jobs: ${e.message}');
    }
  }
  
  /// Get jobs by company ID
  Future<List<models.Document>> getJobsByCompanyId(String companyId) async {
    try {
      print('Fetching jobs for company ID: $companyId');
      
      // First try with the companyId query
      try {
        final response = await _appwriteService.databases.listDocuments(
          databaseId: _databaseId,
          collectionId: _jobsCollectionId,
          queries: [
            appwrite.Query.equal('companyId', companyId),
            appwrite.Query.equal('isActive', true),
          ],
        );
        
        print('Found ${response.documents.length} jobs for company ID: $companyId (using companyId query)');
        for (var doc in response.documents) {
          print('Job ID: ${doc.$id}, Title: ${doc.data['title']}');
        }
        
        if (response.documents.isNotEmpty) {
          return response.documents;
        }
      } catch (e) {
        print('CompanyId query failed: $e');
      }
      
      // If that doesn't work, try getting all jobs and filtering manually
      print('Trying to fetch all jobs and filter manually...');
      final allJobsResponse = await _appwriteService.databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _jobsCollectionId,
        queries: [
          appwrite.Query.equal('isActive', true),
        ],
      );
      
      print('Found ${allJobsResponse.documents.length} total jobs');
      final filteredJobs = allJobsResponse.documents.where((job) {
        final jobCompanyId = job.data['companyId'] as String?;
        final matches = jobCompanyId == companyId;
        if (matches) {
          print('Found matching job: ${job.$id}, Title: ${job.data['title']}');
        }
        return matches;
      }).toList();
      
      print('Filtered to ${filteredJobs.length} jobs for company ID: $companyId');
      return filteredJobs;
    } on appwrite.AppwriteException catch (e) {
      print('AppwriteException in getJobsByCompanyId: ${e.message}, Code: ${e.code}, Type: ${e.type}');
      return []; // Return empty list instead of throwing exception
    } catch (e) {
      print('Unexpected error in getJobsByCompanyId: $e');
      return []; // Return empty list instead of throwing exception
    }
  }
  
  /// Provider for JobService
  static final jobServiceProvider = Provider<JobService>((ref) {
    final appwriteService = ref.watch(appwriteServiceProvider);
    return JobService(appwriteService);
  });
}
