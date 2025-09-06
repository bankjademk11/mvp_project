import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart'; // Import connectivity service
import 'auth_service.dart'; // Import auth service for authProvider
export 'auth_service.dart'; // Export auth service for authProvider

// Jobs provider - NOW ONLINE ONLY
final jobsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  if (connectivity.value == ApiStatus.disconnected) {
    throw Exception('No Connection');
  }
  
  // This will need to be updated to use Appwrite
  // final jobs = await ApiService.fetchJobs();
  // return jobs.cast<Map<String, dynamic>>();
  return [];
});

// Job detail provider - NOW ONLINE ONLY
final jobDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, jobId) async {
  final connectivity = ref.watch(connectivityProvider);
  if (connectivity.value == ApiStatus.disconnected) {
    throw Exception('No Connection');
  }

  if (jobId == 'null' || jobId.isEmpty) {
    throw Exception('Invalid Job ID');
  }
  
  // This will need to be updated to use Appwrite
  // final job = await ApiService.fetchJobById(jobId);
  // if (job == null) {
  //   throw Exception('Job not found');
  // }
  // return job;
  return null;
});

// Profile provider - NOW ONLINE ONLY
final profileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  if (connectivity.value == ApiStatus.disconnected) {
    throw Exception('No Connection');
  }

  final authState = ref.watch(authProvider);
  if (authState.user == null) {
    // This case should be handled by router redirects, but as a safeguard:
    return null;
  }
  
  // Profile data is now fetched directly from the user object
  // which is populated from Appwrite
  return null;
});

// Applications provider - NOW ONLINE ONLY
final applicationsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  if (connectivity.value == ApiStatus.disconnected) {
    throw Exception('No Connection');
  }

  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];
  
  // This will need to be updated to use Appwrite
  // final applications = await ApiService.fetchUserApplications(authState.token!);
  // return applications.cast<Map<String, dynamic>>();
  return [];
});

// Bookmarks provider - NOW ONLINE ONLY
final bookmarksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  if (connectivity.value == ApiStatus.disconnected) {
    throw Exception('No Connection');
  }

  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];
  
  // This will need to be updated to use Appwrite
  // final bookmarks = await ApiService.fetchBookmarks(authState.token!);
  // return bookmarks.cast<Map<String, dynamic>>();
  return [];
});

// Chats provider - NOW ONLINE ONLY
final chatsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final connectivity = ref.watch(connectivityProvider);
  if (connectivity.value == ApiStatus.disconnected) {
    throw Exception('No Connection');
  }

  final authState = ref.watch(authProvider);
  if (authState.user == null) return [];
  
  // This will need to be updated to use Appwrite
  // final chats = await ApiService.fetchUserChats(authState.token!);
  // return chats.cast<Map<String, dynamic>>();
  return [];
});
