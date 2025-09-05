import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bookmark.dart';
import 'mock_api.dart';

// Provider สำหรับ Bookmark Service
final bookmarkServiceProvider = StateNotifierProvider<BookmarkService, BookmarkState>((ref) {
  return BookmarkService();
});

class BookmarkService extends StateNotifier<BookmarkState> {
  BookmarkService() : super(const BookmarkState()) {
    loadBookmarks();
  }

  // โหลดบุ๊คมาร์คทั้งหมด
  Future<void> loadBookmarks() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: เรียก API จริง
      // ตอนนี้ใช้ Mock Data
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockBookmarks = [
        Bookmark(
          id: 'bookmark_001',
          jobId: 'job_001',
          userId: 'user_001',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          jobData: {
            'title': 'Sales Executive',
            'companyName': 'ODG Mall Co., Ltd.',
            'province': 'Vientiane Capital',
          },
        ),
        Bookmark(
          id: 'bookmark_002',
          jobId: 'job_002',
          userId: 'user_001',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          jobData: {
            'title': 'Flutter Developer',
            'companyName': 'NX Creations',
            'province': 'Vientiane Capital',
          },
        ),
      ];
      
      state = state.copyWith(
        bookmarks: mockBookmarks,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // เพิ่มบุ๊คมาร์ค
  Future<void> addBookmark(String jobId, Map<String, dynamic>? jobData) async {
    try {
      final newBookmark = Bookmark(
        id: 'bookmark_${DateTime.now().millisecondsSinceEpoch}',
        jobId: jobId,
        userId: 'user_001', // TODO: ใช้ user ID จริง
        createdAt: DateTime.now(),
        jobData: jobData,
      );

      // TODO: เรียก API เพิ่มบุ๊คมาร์ค
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedBookmarks = [...state.bookmarks, newBookmark];
      state = state.copyWith(bookmarks: updatedBookmarks);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ลบบุ๊คมาร์ค
  Future<void> removeBookmark(String jobId) async {
    try {
      // TODO: เรียก API ลบบุ๊คมาร์ค
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedBookmarks = state.bookmarks.where((bookmark) => bookmark.jobId != jobId).toList();
      state = state.copyWith(bookmarks: updatedBookmarks);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // สลับสถานะบุ๊คมาร์ค
  Future<void> toggleBookmark(String jobId, Map<String, dynamic>? jobData) async {
    if (state.isBookmarked(jobId)) {
      await removeBookmark(jobId);
    } else {
      await addBookmark(jobId, jobData);
    }
  }

  // ล้างข้อผิดพลาด
  void clearError() {
    state = state.copyWith(error: null);
  }

  // รีเฟรชข้อมูล
  Future<void> refresh() async {
    await loadBookmarks();
  }
}