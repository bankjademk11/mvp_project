import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../models/user.dart';
import 'appwrite_service.dart';
import 'language_service.dart';

// Add rate limiting utility
class RateLimiter {
  static final Map<String, DateTime> _lastCall = {};
  static final Map<String, Duration> _minIntervals = {};
  
  static bool canCall(String key, [Duration minInterval = const Duration(seconds: 1)]) {
    final now = DateTime.now();
    final last = _lastCall[key];
    _minIntervals[key] = minInterval;
    
    if (last == null || now.difference(last) >= minInterval) {
      _lastCall[key] = now;
      return true;
    }
    return false;
  }
  
  static Future<void> waitForCooldown(String key) async {
    final last = _lastCall[key];
    final minInterval = _minIntervals[key] ?? const Duration(seconds: 1);
    
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < minInterval) {
        await Future.delayed(minInterval - elapsed);
      }
    }
  }
  
  static void reset(String key) {
    _lastCall.remove(key);
  }
}

class AuthService {
  final AppwriteService _appwriteService;
  static const String _databaseId = '68bbb9e6003188d8686f';
  static const String _userProfilesCollectionId = 'user_profiles';
  
  // Add cache for user data
  models.User? _cachedUser;
  DateTime? _lastUserFetch;
  User? _mappedUser;
  DateTime? _lastMappedUserFetch;
  bool _isSessionValid = false; // Track session validity

  AuthService(this._appwriteService);

  // Method to clear cache and force refresh
  void forceRefresh() {
    _clearCache();
  }

  Future<User?> login(String email, String password) async {
    try {
      // Aggressively log out first to ensure a clean session state
      try {
        await logout();
      } catch (e) {
        // Ignore errors if already logged out
      }

      await _appwriteService.account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      final appwriteUser = await _appwriteService.account.get();
      
      // Mark session as valid
      _isSessionValid = true;
      
      // Clear cache when logging in
      _clearCache();
      
      // Cache the user data
      _cachedUser = appwriteUser;
      _lastUserFetch = DateTime.now();

      // Get user profile from database
      try {
        final profileDocument = await _appwriteService.databases.getDocument(
          databaseId: _databaseId,
          collectionId: _userProfilesCollectionId,
          documentId: appwriteUser.$id,
        );

        print('Debug: Retrieved profile document data during login: ${profileDocument.data}');
        final mappedUser = _mapAppwriteUserToUser(appwriteUser, profileDocument);
        _mappedUser = mappedUser;
        _lastMappedUserFetch = DateTime.now();
        return mappedUser;
      } catch (e) {
        print('Error retrieving profile document during login: $e');
        // If profile doesn't exist, return user with default values
        final mappedUser = _mapAppwriteUserToUser(appwriteUser);
        _mappedUser = mappedUser;
        _lastMappedUserFetch = DateTime.now();
        return mappedUser;
      }
    } on AppwriteException catch (e) {
      // Mark session as invalid
      _isSessionValid = false;
      
      // Map Appwrite exceptions to user-friendly messages or translation keys
      if (e.code == 401) {
        throw Exception('invalid_credentials');
      } else if (e.code == 400) {
        throw Exception('email_password_required');
      } else if (e.code == 429) {
        throw Exception('rate_limit_exceeded');
      }
      throw Exception(e.message ?? 'login_failed');
    } catch (e) {
      // Mark session as invalid
      _isSessionValid = false;
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
    String? companyLogoUrl,
  }) async {
    try {
      // Aggressively log out first to ensure a clean session state
      try {
        await logout();
      } catch (e) {
        // Ignore errors if already logged out
      }

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

      // If the user is an employer, create a team for them
      String? teamId;
      if (role == 'employer') {
        try {
          final newTeam = await _appwriteService.teams.create(
            teamId: ID.unique(),
            name: companyName ?? displayName,
          );
          teamId = newTeam.$id;

          // Add the employer to the team as an owner
          await _appwriteService.teams.createMembership(
            teamId: teamId,
            email: email, // Invite by email
            roles: ['owner'], // Assign owner role
            url: 'https://cloud.appwrite.io', // A placeholder URL is required
          );

        } on AppwriteException catch (e) {
          print('Error creating team: ${e.message}');
          // Decide how to handle team creation failure. For now, we'll proceed without a team.
        }
      }

      // Create user profile document in the database
      final profileData = {
        'userId': userId,
        'phone': phone ?? '',
        'province': province ?? '',
        'skills': skills,
        'bio': bio ?? '',
        'resumeUrl': resumeUrl ?? '',
        'avatarUrl': avatarUrl ?? '',
        'teamId': teamId, // Add teamId to profile
        // Employer-specific fields
        'companyName': companyName ?? '',
        'companySize': companySize ?? '',
        'industry': industry ?? '',
        'companyDescription': companyDescription ?? '',
        'website': website ?? '',
        'companyAddress': companyAddress ?? '',
        'companyLogoUrl': companyLogoUrl ?? '',
      };

      await _appwriteService.databases.createDocument(
        databaseId: _databaseId,
        collectionId: _userProfilesCollectionId,
        documentId: userId, // Use userId as documentId for easy linking
        data: profileData,
      );

      final appwriteUser = await _appwriteService.account.get();
      
      // Mark session as valid
      _isSessionValid = true;
      
      // Clear cache when registering
      _clearCache();
      
      // Cache the user data
      _cachedUser = appwriteUser;
      _lastUserFetch = DateTime.now();

      // Get user profile from database
      try {
        final profileDocument = await _appwriteService.databases.getDocument(
          databaseId: _databaseId,
          collectionId: _userProfilesCollectionId,
          documentId: userId,
        );

        print('Debug: Retrieved profile document data during registration: ${profileDocument.data}');
        final mappedUser = _mapAppwriteUserToUser(appwriteUser, profileDocument);
        _mappedUser = mappedUser;
        _lastMappedUserFetch = DateTime.now();
        return mappedUser;
      } catch (e) {
        print('Error retrieving profile document during registration: $e');
        // If profile doesn't exist, return user with default values
        final mappedUser = _mapAppwriteUserToUser(appwriteUser);
        _mappedUser = mappedUser;
        _lastMappedUserFetch = DateTime.now();
        return mappedUser;
      }
    } on AppwriteException catch (e) {
      // Mark session as invalid
      _isSessionValid = false;
      
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
      } else if (e.code == 429) {
        throw Exception('rate_limit_exceeded');
      }
      throw Exception(e.message ?? 'registration_failed');
    } catch (e) {
      // Mark session as invalid
      _isSessionValid = false;
      throw Exception('registration_failed');
    }
  }

  Future<void> logout() async {
    try {
      await _appwriteService.account.deleteSession(sessionId: 'current');
      
      // Mark session as invalid
      _isSessionValid = false;
      
      // Clear all cache
      _clearCache();
    } on AppwriteException catch (e) {
      // Mark session as invalid
      _isSessionValid = false;
      throw Exception(e.message ?? 'logout_failed');
    } catch (e) {
      // Mark session as invalid
      _isSessionValid = false;
      throw Exception('logout_failed');
    }
  }
  
  void _clearCache() {
    _cachedUser = null;
    _lastUserFetch = null;
    _mappedUser = null;
    _lastMappedUserFetch = null;
    
    // Clear rate limiters
    RateLimiter.reset('getCurrentUser');
    RateLimiter.reset('updateUserProfile');
  }

  Future<User?> getCurrentUser() async {
    // Check if we have a recently mapped user (less than 30 seconds old)
    if (_mappedUser != null && _lastMappedUserFetch != null) {
      final age = DateTime.now().difference(_lastMappedUserFetch!);
      if (age < const Duration(seconds: 30)) {
        print('Returning recently mapped user data');
        return _mappedUser;
      }
    }
    
    // Check rate limiting
    if (!RateLimiter.canCall('getCurrentUser', const Duration(seconds: 5))) {
      print('Rate limit: Skipping getCurrentUser call');
      // If we have cached user data, return it
      if (_cachedUser != null && _lastUserFetch != null) {
        final age = DateTime.now().difference(_lastUserFetch!);
        // Return cached data if it's less than 2 minutes old
        if (age < const Duration(minutes: 2)) {
          print('Returning cached user data');
          final mappedUser = _mapAppwriteUserToUser(_cachedUser!);
          _mappedUser = mappedUser;
          _lastMappedUserFetch = DateTime.now();
          return mappedUser;
        }
      }
      
      // Wait for cooldown and then proceed
      await RateLimiter.waitForCooldown('getCurrentUser');
    }
    
    try {
      // Check session validity before making API call
      if (!_isSessionValid) {
        try {
          // Try to validate session
          await _appwriteService.account.get();
          _isSessionValid = true;
        } catch (e) {
          _isSessionValid = false;
          // Clear cache
          _clearCache();
          return null;
        }
      }
      
      final appwriteUser = await _appwriteService.account.get();
      print('Debug: Retrieved Appwrite user account: ${appwriteUser.email}, ID: ${appwriteUser.$id}');
      
      // Cache the user data
      _cachedUser = appwriteUser;
      _lastUserFetch = DateTime.now();

      // Get user profile from database with retry logic
      try {
        models.Document? profileDocument;
        int retryCount = 0;
        const maxRetries = 3;
        
        while (retryCount <= maxRetries) {
          try {
            print('Debug: Attempting to retrieve profile document for user ${appwriteUser.$id}, attempt ${retryCount + 1}');
            profileDocument = await _appwriteService.databases.getDocument(
              databaseId: _databaseId,
              collectionId: _userProfilesCollectionId,
              documentId: appwriteUser.$id,
            );
            print('Debug: Successfully retrieved profile document: ${profileDocument.$id}');
            break; // Success, exit retry loop
          } catch (e) {
            retryCount++;
            print('Error retrieving profile document (attempt $retryCount): $e');
            if (retryCount > maxRetries) {
              print('Debug: Failed to retrieve profile document after $maxRetries attempts');
              rethrow; // Re-throw if max retries exceeded
            }
            // Wait before retry
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          }
        }

        print('Debug: Retrieved profile document data: ${profileDocument?.data}');
        final mappedUser = _mapAppwriteUserToUser(appwriteUser, profileDocument);
        print('Debug: Mapped user with profile data - companyName: ${mappedUser.companyName}, companyDescription: ${mappedUser.companyDescription}');
        _mappedUser = mappedUser;
        _lastMappedUserFetch = DateTime.now();
        return mappedUser;
      } catch (e) {
        print('Error retrieving profile document after retries: $e');
        print('Debug: Falling back to basic user data without profile');
        // Even if we can't get the profile document, we should still return the user
        // but with a flag indicating that profile data is not available
        final mappedUser = _mapAppwriteUserToUser(appwriteUser);
        print('Debug: Mapped user without profile data - companyName: ${mappedUser.companyName}, companyDescription: ${mappedUser.companyDescription}');
        _mappedUser = mappedUser;
        _lastMappedUserFetch = DateTime.now();
        return mappedUser;
      }
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        // User not logged in or session expired
        // Mark session as invalid
        _isSessionValid = false;
        // Clear cache
        _clearCache();
        return null;
      } else if (e.code == 429) {
        print('Rate limit exceeded when getting current user');
        // Return cached data if available
        if (_mappedUser != null) {
          return _mappedUser;
        }
        throw Exception('rate_limit_exceeded');
      }
      print('AppwriteException in getCurrentUser: ${e.message}, Code: ${e.code}');
      throw Exception(e.message ?? 'failed_to_get_current_user');
    } catch (e) {
      print('Unexpected error in getCurrentUser: $e');
      throw Exception('failed_to_get_current_user');
    }
  }

  // เพิ่มฟังก์ชันสำหรับอัปเดตโปรไฟล์ผู้ใช้ รวมถึง companyLogoUrl
  Future<User?> updateUserProfile({
    required String userId,
    String? phone,
    String? province,
    List<String>? skills,
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
    String? companyLogoUrl,
  }) async {
    // Check rate limiting
    if (!RateLimiter.canCall('updateUserProfile', const Duration(seconds: 1))) {
      print('Rate limit: Skipping updateUserProfile call');
      await RateLimiter.waitForCooldown('updateUserProfile');
    }
    
    try {
      // Check session validity before making API call
      if (!_isSessionValid) {
        try {
          // Try to validate session
          await _appwriteService.account.get();
          _isSessionValid = true;
        } catch (e) {
          _isSessionValid = false;
          throw Exception('session_expired');
        }
      }
      
      final profileData = <String, dynamic>{};

      // เพิ่มเฉพาะ field ที่ไม่ใช่ null
      if (phone != null) profileData['phone'] = phone;
      if (province != null) profileData['province'] = province;
      if (skills != null) profileData['skills'] = skills;
      if (bio != null) profileData['bio'] = bio;

      // Always include resumeUrl and avatarUrl if they are provided in the function call,
      // even if their value is null, to allow clearing them in Appwrite.
      profileData['resumeUrl'] = resumeUrl; // Always include if passed
      profileData['avatarUrl'] = avatarUrl; // Always include if passed

      if (companyName != null) profileData['companyName'] = companyName;
      if (companySize != null) profileData['companySize'] = companySize;
      if (industry != null) profileData['industry'] = industry;
      if (companyDescription != null) profileData['companyDescription'] = companyDescription;
      if (website != null) profileData['website'] = website;
      if (companyAddress != null) profileData['companyAddress'] = companyAddress;
      if (companyLogoUrl != null) profileData['companyLogoUrl'] = companyLogoUrl;

      print('Debug: Updating user profile with data: $profileData');

      final profileDocument = await _appwriteService.databases.updateDocument(
        databaseId: _databaseId,
        collectionId: _userProfilesCollectionId,
        documentId: userId,
        data: profileData,
      );

      print('Debug: Profile document updated successfully: ${profileDocument.$id}');

      // ดึงข้อมูลผู้ใช้ล่าสุด
      final appwriteUser = await _appwriteService.account.get();
      
      // Update cache
      _cachedUser = appwriteUser;
      _lastUserFetch = DateTime.now();
      
      return _mapAppwriteUserToUser(appwriteUser, profileDocument);
    } on AppwriteException catch (e) {
      print('Appwrite error when updating user profile: ${e.message}, Code: ${e.code}, Type: ${e.type}');
      if (e.code == 429) {
        throw Exception('rate_limit_exceeded');
      } else if (e.code == 401) {
        // Session expired
        _isSessionValid = false;
        throw Exception('session_expired');
      }
      throw Exception('Failed to update user profile: ${e.message} (Code: ${e.code})');
    } catch (e) {
      print('Unexpected error when updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
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
      companyLogoUrl: profileDocument?.data['companyLogoUrl'] as String?,
      teamId: profileDocument?.data['teamId'] as String?, // Add this
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
      String errorMessage;
      if (e.toString().contains('rate_limit_exceeded')) {
        errorMessage = 'ระบบถูกใช้งานมากเกินไป กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('session_expired')) {
        errorMessage = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
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
      String errorMessage;
      if (e.toString().contains('rate_limit_exceeded')) {
        errorMessage = 'ระบบถูกใช้งานมากเกินไป กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('session_expired')) {
        errorMessage = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = const AuthState();
  }

  Future<void> getCurrentUser() async {
    print('Debug: AuthNotifier.getCurrentUser() called');
    // Don't fetch if we're already loading
    if (state.isLoading) {
      print('Debug: AuthNotifier.getCurrentUser() - already loading, returning');
      return;
    }
    
    // If we have a user and the data is recent (less than 30 seconds old), don't fetch again
    if (state.user != null && state.user!.uid.isNotEmpty) {
      // Check if we have recent data (less than 30 seconds old)
      // In a real app, you might want to check the actual timestamp
      print('Debug: User data is recent, not fetching again');
      return;
    }
    
    print('Debug: AuthNotifier.getCurrentUser() - proceeding with fetch');
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = await _authService.getCurrentUser();
      print('Debug: AuthNotifier.getCurrentUser() - got user with companyLogoUrl: ${user?.companyLogoUrl}');
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('rate_limit_exceeded')) {
        errorMessage = 'ระบบถูกใช้งานมากเกินไป กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('session_expired')) {
        errorMessage = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
        // Clear user state when session expires
        state = const AuthState();
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  // Method to force refresh current user data
  Future<void> forceRefreshCurrentUser() async {
    print('Debug: Force refreshing current user data');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Force the auth service to clear its cache
      _authService.forceRefresh();
      
      // Get fresh user data
      final user = await _authService.getCurrentUser();
      print('Debug: forceRefreshCurrentUser returned user with companyLogoUrl: ${user?.companyLogoUrl}');
      print('Debug: forceRefreshCurrentUser returned user with companyName: ${user?.companyName}');
      print('Debug: forceRefreshCurrentUser returned user with companyDescription: ${user?.companyDescription}');
      state = state.copyWith(
        user: user,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('rate_limit_exceeded')) {
        errorMessage = 'ระบบถูกใช้งานมากเกินไป กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('session_expired')) {
        errorMessage = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
        // Clear user state when session expires
        state = const AuthState();
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  // เพิ่มเมธอดสำหรับอัปเดตโปรไฟล์ผู้ใช้
  Future<void> updateUserProfile({
    String? phone,
    String? province,
    List<String>? skills,
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
    String? companyLogoUrl,
  }) async {
    if (state.user == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = await _authService.updateUserProfile(
        userId: state.user!.uid,
        phone: phone,
        province: province,
        skills: skills,
        bio: bio,
        resumeUrl: resumeUrl,
        avatarUrl: avatarUrl,
        companyName: companyName,
        companySize: companySize,
        industry: industry,
        companyDescription: companyDescription,
        website: website,
        companyAddress: companyAddress,
        companyLogoUrl: companyLogoUrl,
      );

      print('Debug: updateUserProfile returned user with companyLogoUrl: ${updatedUser?.companyLogoUrl}');
      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      print('Error in updateUserProfile: $e');
      String errorMessage;
      if (e.toString().contains('rate_limit_exceeded')) {
        errorMessage = 'ระบบถูกใช้งานมากเกินไป กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('session_expired')) {
        errorMessage = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
        // Clear user state when session expires
        state = const AuthState();
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  Future<void> updateCurrentUserResume(String? newResumeUrl) async {
    if (state.user == null) {
      state = state.copyWith(error: 'User not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedUser = await _authService.updateUserProfile(
        userId: state.user!.uid,
        resumeUrl: newResumeUrl,
      );

      state = state.copyWith(
        user: updatedUser,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      String errorMessage;
      if (e.toString().contains('rate_limit_exceeded')) {
        errorMessage = 'ระบบถูกใช้งานมากเกินไป กรุณาลองใหม่อีกครั้ง';
      } else if (e.toString().contains('session_expired')) {
        errorMessage = 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
        state = const AuthState();
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  return AuthService(appwriteService);
});

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});