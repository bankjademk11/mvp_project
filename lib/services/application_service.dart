import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/application.dart';
import '../services/mock_api.dart';

class ApplicationService {
  // In-memory storage for demo purposes
  static final List<JobApplication> _applications = [];

  Future<List<JobApplication>> getApplications() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock applications if empty
    if (_applications.isEmpty) {
      _initializeMockApplications();
    }
    
    return List.from(_applications);
  }

  Future<JobApplication> submitApplication({
    required String jobId,
    required String jobTitle,
    required String companyName,
    String? coverLetter,
    String? resumeUrl,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final application = JobApplication(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      jobId: jobId,
      jobTitle: jobTitle,
      companyName: companyName,
      status: ApplicationStatus.pending,
      appliedAt: DateTime.now(),
      coverLetter: coverLetter,
      resumeUrl: resumeUrl,
    );
    
    _applications.insert(0, application); // Add to beginning
    return application;
  }

  Future<JobApplication> updateApplicationStatus(
    String applicationId,
    ApplicationStatus newStatus,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _applications.indexWhere((app) => app.id == applicationId);
    if (index != -1) {
      final updatedApp = _applications[index].copyWith(status: newStatus);
      _applications[index] = updatedApp;
      return updatedApp;
    }
    
    throw Exception('Application not found');
  }

  Future<void> deleteApplication(String applicationId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _applications.removeWhere((app) => app.id == applicationId);
  }

  void _initializeMockApplications() {
    final now = DateTime.now();
    _applications.addAll([
      JobApplication(
        id: 'app_001',
        jobId: 'job_001',
        jobTitle: 'Sales Executive',
        companyName: 'ODG Mall Co., Ltd.',
        status: ApplicationStatus.reviewing,
        appliedAt: now.subtract(const Duration(days: 2)),
        coverLetter: 'ຂ້ອຍສົນໃຈຕໍາແໜ່ງນີ້ຫຼາຍເຈົ້າ ມີປະສົບການດ້ານການຂາຍ 2 ປີ',
      ),
      JobApplication(
        id: 'app_002',
        jobId: 'job_002',
        jobTitle: 'Flutter Developer (Junior)',
        companyName: 'NX Creations',
        status: ApplicationStatus.interview,
        appliedAt: now.subtract(const Duration(days: 5)),
        interviewDate: now.add(const Duration(days: 1)),
        coverLetter: 'ຂ້ອຍເປັນນັກພັດທະນາ Flutter ມີປະສົບການສ້າງແອັບ MVP',
      ),
      JobApplication(
        id: 'app_003',
        jobId: 'job_003',
        jobTitle: 'Warehouse Supervisor',
        companyName: 'Odien Group',
        status: ApplicationStatus.pending,
        appliedAt: now.subtract(const Duration(days: 1)),
        coverLetter: 'ມີປະສົບການການຈັດການຄັງສິນຄ້າ 3 ປີ',
      ),
    ]);
  }
}

class ApplicationNotifier extends StateNotifier<AsyncValue<List<JobApplication>>> {
  final ApplicationService _service;
  
  ApplicationNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    try {
      final applications = await _service.getApplications();
      state = AsyncValue.data(applications);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> submitApplication({
    required String jobId,
    required String jobTitle,
    required String companyName,
    String? coverLetter,
    String? resumeUrl,
  }) async {
    try {
      await _service.submitApplication(
        jobId: jobId,
        jobTitle: jobTitle,
        companyName: companyName,
        coverLetter: coverLetter,
        resumeUrl: resumeUrl,
      );
      // Reload applications
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

final applicationServiceProvider = Provider<ApplicationService>((ref) {
  return ApplicationService();
});

final applicationProvider = StateNotifierProvider<ApplicationNotifier, AsyncValue<List<JobApplication>>>((ref) {
  final service = ref.watch(applicationServiceProvider);
  return ApplicationNotifier(service);
});