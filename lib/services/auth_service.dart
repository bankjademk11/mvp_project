import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../models/user.dart';
import 'appwrite_service.dart'; // Import AppwriteService
import 'language_service.dart'; // Added import for language service

class AuthService {
  final AppwriteService _appwriteService;
  static const String _databaseId = '68bbb9e6003188d8686f';
  static const String _userProfilesCollectionId = 'user_profiles';

  AuthService(this._appwriteService); // Constructor to inject AppwriteService

  Future<User?> login(String email, String password) async {
    try {
      await _appwriteService.account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      final appwriteUser = await _appwriteService.account.get();
      return _mapAppwriteUserToUser(appwriteUser);
    } on AppwriteException catch (e) {
      // Map Appwrite exceptions to user-friendly messages or translation keys
      if (e.code == 401) {
        throw Exception('invalid_credentials');
      } else if (e.code == 400) {
        throw Exception('email_password_required');
      }
      throw Exception(e.message ?? 'login_failed');
    } catch (e) {
      throw Exception('login_failed');
    }
  }

  Future<User?> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
    // Additional fields for user profile
    String? phone,
    String? province,
    List<String> skills = const [],
    String? bio,
    String? resumeUrl,
    String? avatarUrl,
    // Employer-specific fields
    String? companyName,
    String? companySize,
    String? industry,
    String? companyDescription,
    String? website,
    String? companyAddress,
  }) async {
    try {
      // Create user account
      final userId = ID.unique();
      await _appwriteService.account.create(
        userId: userId,
        email: email,
        password: password,
        name: displayName,
      );

      // Log in the user immediately after registration
      await _appwriteService.account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Update user preferences with role
      await _appwriteService.account.updatePrefs(
        prefs: {'role': role},
      );

      // Create user profile document in the database
      final profileData = {
        'userId': userId,
        'phone': phone ?? '',
        'province': province ?? '',
        'skills': skills,
        'bio': bio ?? '',
        'resumeUrl': resumeUrl ?? '',
        'avatarUrl': avatarUrl ?? '',
        // Employer-specific fields
        'companyName': companyName ?? '',
        'companySize': companySize ?? '',
        'industry': industry ?? '',
        'companyDescription': companyDescription ?? '',
        'website': website ?? '',
        'companyAddress': companyAddress ?? '',
      };

      await _appwriteService.databases.createDocument(
        databaseId: _databaseId,
        collectionId: _userProfilesCollectionId,
        documentId: userId, // Use userId as documentId for easy linking
        data: profileData,
      );

      final appwriteUser = await _appwriteService.account.get();
      return _mapAppwriteUserToUser(appwriteUser);
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        throw Exception('email_already_registered');
      } else if (e.code == 400) {
        // ตรวจสอบข้อความข้อผิดพลาดเพิ่มเติม
        if (e.message?.contains('password') == true) {
          throw Exception('password_requirements_not_met');
        } else if (e.message?.contains('email') == true) {
          throw Exception('email_invalid');
        } else {
          throw Exception('invalid_registration_data');
        }
      }
      throw Exception(e.message ?? 'registration_failed');
    } catch (e) {
      throw Exception('registration_failed');
    }
  }

  Future<void> logout() async {
    try {
      await _appwriteService.account.deleteSession(sessionId: 'current');
    } on AppwriteException catch (e) {
      throw Exception(e.message ?? 'logout_failed');
    } catch (e) {
      throw Exception('logout_failed');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      final appwriteUser = await _appwriteService.account.get();

      // Get user profile from database
      try {
        final profileDocument = await _appwriteService.databases.getDocument(
          databaseId: _databaseId,
          collectionId: _userProfilesCollectionId,
          documentId: appwriteUser.$id,
        );

        return _mapAppwriteUserToUser(appwriteUser, profileDocument);
      } catch (e) {
        // If profile doesn't exist, return user with default values
        return _mapAppwriteUserToUser(appwriteUser);
      }
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        // User not logged in or session expired
        // Check if the error is related to missing scopes
        if (e.type == 'general_unauthorized_scope') {
          // This might indicate that the session is not properly established
          // or the user is not authenticated
          return null;
        }
        return null;
      }
      throw Exception(e.message ?? 'failed_to_get_current_user');
    } catch (e) {
      throw Exception('failed_to_get_current_user');
    }
  }

  User _mapAppwriteUserToUser(models.User appwriteUser,
      [models.Document? profileDocument]) {
    // Extract role from preferences, default to 'seeker' if not found
    final role = appwriteUser.prefs.data.containsKey('role')
        ? appwriteUser.prefs.data['role'] as String
        : 'seeker';

    return User(
      uid: appwriteUser.$id,
      email: appwriteUser.email,
      displayName: appwriteUser.name,
      role: role,
      // Map profile data if available
      phone: profileDocument?.data['phone'] as String?,
      province: profileDocument?.data['province'] as String?,
      skills: List<String>.from(profileDocument?.data['skills'] as List? ?? []),
      bio: profileDocument?.data['bio'] as String?,
      resumeUrl: profileDocument?.data['resumeUrl'] as String?,
      avatarUrl: profileDocument?.data['avatarUrl'] as String?,
      // Employer-specific fields
      companyName: profileDocument?.data['companyName'] as String?,
      companySize: profileDocument?.data['companySize'] as String?,
      industry: profileDocument?.data['industry'] as String?,
      companyDescription:
          profileDocument?.data['companyDescription'] as String?,
      website: profileDocument?.data['website'] as String?,
      companyAddress: profileDocument?.data['companyAddress'] as String?,
    );
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

  Future<void> getCurrentUser() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.getCurrentUser();
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

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final appwriteServiceProvider = Provider<AppwriteService>((ref) {
  return AppwriteService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return AuthService(appwriteService);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
