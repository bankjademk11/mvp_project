// บุ๊คมาร์ค/บันทึกงาน Model
class Bookmark {
  final String id;
  final String jobId;
  final String userId;
  final DateTime createdAt;
  final Map<String, dynamic>? jobData; // เก็บข้อมูลงานเบื้องต้น

  const Bookmark({
    required this.id,
    required this.jobId,
    required this.userId,
    required this.createdAt,
    this.jobData,
  });

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      userId: json['userId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      jobData: json['jobData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'jobData': jobData,
    };
  }

  Bookmark copyWith({
    String? id,
    String? jobId,
    String? userId,
    DateTime? createdAt,
    Map<String, dynamic>? jobData,
  }) {
    return Bookmark(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      jobData: jobData ?? this.jobData,
    );
  }
}

// State สำหรับการจัดการ Bookmarks
class BookmarkState {
  final List<Bookmark> bookmarks;
  final bool isLoading;
  final String? error;

  const BookmarkState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
  });

  BookmarkState copyWith({
    List<Bookmark>? bookmarks,
    bool? isLoading,
    String? error,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool isBookmarked(String jobId) {
    return bookmarks.any((bookmark) => bookmark.jobId == jobId);
  }
}