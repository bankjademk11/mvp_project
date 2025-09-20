import 'dart:convert'; // Add this import
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart' as appwrite;
import '../models/bookmark.dart';
import 'appwrite_service.dart';
import 'auth_service.dart';

// Provider for Bookmark Service
final bookmarkServiceProvider =
    StateNotifierProvider<BookmarkService, BookmarkState>((ref) {
  final appwriteService = ref.watch(appwriteServiceProvider);
  final authState = ref.watch(authProvider);
  return BookmarkService(appwriteService, authState.user?.uid);
});

class BookmarkService extends StateNotifier<BookmarkState> {
  final AppwriteService _appwriteService;
  final String? _userId;
  static const String _databaseId = '68bbb9e6003188d8686f';
  static const String _bookmarksCollectionId = 'bookmarks';

  BookmarkService(this._appwriteService, this._userId)
      : super(const BookmarkState()) {
    if (_userId != null) {
      loadBookmarks();
    }
  }

  Future<void> loadBookmarks() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true);

    try {
      final response = await _appwriteService.databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookmarksCollectionId,
        queries: [appwrite.Query.equal('userId', _userId!)],
      );

      final bookmarks = response.documents.map((doc) {
        final data = doc.data;
        data['id'] = doc.$id; // IMPORTANT: Pass document ID to model
        // Decode jobData from JSON string to Map
        if (data['jobData'] is String && data['jobData'].isNotEmpty) {
          data['jobData'] = jsonDecode(data['jobData']);
        }
        return Bookmark.fromJson(data);
      }).toList();

      state = state.copyWith(bookmarks: bookmarks, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> addBookmark(String jobId, Map<String, dynamic>? jobData) async {
    if (_userId == null) return;
    try {
      final newBookmarkDoc = await _appwriteService.databases.createDocument(
        databaseId: _databaseId,
        collectionId: _bookmarksCollectionId,
        documentId: appwrite.ID.unique(),
        data: {
          'userId': _userId,
          'jobId': jobId,
          'jobData': jsonEncode(jobData), // Encode map to JSON string
        },
        permissions: [appwrite.Permission.read(appwrite.Role.user(_userId!))],
      );

      final newBookmark = Bookmark.fromJson(newBookmarkDoc.data..['id'] = newBookmarkDoc.$id);
      final updatedBookmarks = [...state.bookmarks, newBookmark];
      state = state.copyWith(bookmarks: updatedBookmarks);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // Now removes by the bookmark's actual document ID for efficiency
  Future<void> removeBookmark(String bookmarkId) async {
    if (_userId == null) return;
    try {
      await _appwriteService.databases.deleteDocument(
        databaseId: _databaseId,
        collectionId: _bookmarksCollectionId,
        documentId: bookmarkId,
      );

      final updatedBookmarks =
          state.bookmarks.where((bookmark) => bookmark.id != bookmarkId).toList();
      state = state.copyWith(bookmarks: updatedBookmarks);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // สลับสถานะบุ๊คมาร์ค
  Future<void> toggleBookmark(
      String jobId, Map<String, dynamic>? jobData) async {
    final isAlreadyBookmarked = state.isBookmarked(jobId);

    if (isAlreadyBookmarked) {
      try {
        // Find the bookmark to get its document ID for deletion
        final bookmarkToRemove = state.bookmarks.firstWhere((b) => b.jobId == jobId);
        await removeBookmark(bookmarkToRemove.id);
      } catch (e) {
        // Handle case where bookmark is not found in state, though it should be
        print('Error finding bookmark to remove: $e');
      }
    } else {
      await addBookmark(jobId, jobData);
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await loadBookmarks();
  }

  // Clear all bookmarks for the current user
  Future<void> clearAllBookmarks() async {
    if (_userId == null) return;
    try {
      // Fetch all bookmark documents for the user
      final response = await _appwriteService.databases.listDocuments(
        databaseId: _databaseId,
        collectionId: _bookmarksCollectionId,
        queries: [appwrite.Query.equal('userId', _userId!)],
      );

      // Delete each document one by one
      for (final doc in response.documents) {
        await _appwriteService.databases.deleteDocument(
          databaseId: _databaseId,
          collectionId: _bookmarksCollectionId,
          documentId: doc.$id,
        );
      }

      // Update the local state to be empty
      state = state.copyWith(bookmarks: []);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }
}
