import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'mock_api.dart';
import 'language_service.dart'; // Added import for language service

class AuthService {
  static const String _mockEmail = 'demo@mvppackage.com';
  static const String _mockPassword = '123456';
  static const String _employerEmail = 'example1@gmail.com';
  static const String _employerPassword = '123456';

  Future<User?> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Mock validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('email_required'); // Changed to use translation key
    }
    
    if (!email.contains('@')) {
      throw Exception('email_invalid'); // Changed to use translation key
    }
    
    if (password.length < 6) {
      throw Exception('password_min_length'); // Changed to use translation key
    }
    
    // Check if this is employer login
    if (email == _employerEmail && password == _employerPassword) {
      final employerUser = User(
        uid: 'employer_001',
        email: email,
        displayName: 'ນາຍຈ້າງ ABC',
        role: 'employer',
        phone: '020-12345678',
        province: 'ນະຄອນຫຼວງວຽງຈັນ',
        skills: ['ບໍລິຫານ HR', 'ສະໝັກງານ', 'ພັດທະນາທຸລະກິດ'],
        bio: 'ບໍລິສັດຊັ້ນນໍາດ້ານເທັກໂນໂລຊີ ຊອກຫາຄົນເກັ່ງຮ່ວມງານ',
        companyName: 'ບໍລິສັດ ABC ເທັກໂນໂລຊີ ຈໍາກັດ',
        companySize: '51-200 ຄົນ',
        industry: 'ເທັກໂນໂລຊີສານສົນເທດ',
        companyDescription: 'ບໍລິສັດຊັ້ນນໍາດ້ານການພັດທະນາແອັບພລິເຄຊັນ ແລະ ລະບົບຂໍ້ມູນ',
        website: 'https://abc-tech.la',
        companyAddress: 'ບ້ານ ສີສັດຕະນາກ, ເມືອງ ສີສັດຕະນາກ, ນະຄອນຫຼວງວຽງຈັນ',
      );
      print('Debug AuthService - Creating employer user: ${employerUser.email}, Role: ${employerUser.role}');
      return employerUser;
    }
    
    // For demo purposes, accept any valid email/password format as job seeker
    // In real app, this would validate against backend
    final mockProfile = await MockApi.loadProfile();
    return User(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: mockProfile['displayName'] ?? 'ผู้ใช้งาน',
      role: 'seeker',
      phone: mockProfile['phone'],
      province: mockProfile['province'],
      skills: List<String>.from(mockProfile['skills'] ?? []),
      bio: mockProfile['bio'],
      resumeUrl: mockProfile['resumeUrl'],
    );
  }

  Future<User?> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Mock validation
    if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
      throw Exception('name_required'); // Changed to use translation key
    }
    
    if (!email.contains('@')) {
      throw Exception('email_invalid'); // Changed to use translation key
    }
    
    if (password.length < 6) {
      throw Exception('password_min_length'); // Changed to use translation key
    }
    
    if (displayName.length < 2) {
      throw Exception('name_min_length'); // Changed to use translation key
    }
    
    // Create new user
    return User(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      role: role,
      skills: role == 'seeker' ? ['Flutter', 'Mobile Development'] : ['Management', 'HR'],
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<User?> getCurrentUser() async {
    // In real app, this would check stored tokens/session
    return null;
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  
  AuthNotifier(this._authService) : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.login(email, password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});