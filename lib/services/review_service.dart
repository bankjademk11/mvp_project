import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import 'mock_api.dart';

// Provider สำหรับ Review Service
final reviewServiceProvider = StateNotifierProvider<ReviewService, ReviewState>((ref) {
  return ReviewService();
});

class ReviewService extends StateNotifier<ReviewState> {
  ReviewService() : super(const ReviewState()) {
    loadReviews();
  }

  // โหลดรีวิวทั้งหมด
  Future<void> loadReviews() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: เรียก API จริง
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockReviews = [
        CompanyReview(
          id: 'review_001',
          companyId: 'company_001',
          userId: 'user_001',
          userName: 'นายสมชาย',
          rating: 4.0,
          title: 'บริษัทดี มีโอกาสเติบโต',
          review: 'ทำงานที่นี่มา 2 ปี บรรยากาศดี เพื่อนร่วมงานช่วยเหลือกัน มีการฝึกอบรมเสมอ',
          pros: ['บรรยากาศดี', 'มีการฝึกอบรม', 'เพื่อนร่วมงานช่วยเหลือกัน'],
          cons: ['เงินเดือนอาจต่ำกว่าค่าเฉลี่ย'],
          ratings: {
            'workLife': 4.0,
            'salary': 3.5,
            'management': 4.0,
            'career': 4.5,
          },
          isCurrentEmployee: true,
          position: 'Sales Executive',
          workPeriod: DateTime(2022),
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          isVerified: true,
          helpfulCount: 8,
        ),
        CompanyReview(
          id: 'review_002',
          companyId: 'company_002',
          userId: 'user_002',
          userName: 'นางสาวมาลี',
          rating: 4.5,
          title: 'เป็นบริษัทเทคโนโลยีที่ทันสมัย',
          review: 'สภาพแวดล้อมการทำงานดีมาก ใช้เทคโนโลยีใหม่ๆ ได้เรียนรู้มาก หัวหน้าเข้าใจและให้คำแนะนำดี',
          pros: ['เทคโนโลยีทันสมัย', 'ได้เรียนรู้มาก', 'หัวหน้าดี', 'Work-life balance ดี'],
          cons: ['บางครั้งความกดดันจากโปรเจค'],
          ratings: {
            'workLife': 4.5,
            'salary': 4.0,
            'management': 5.0,
            'career': 4.5,
          },
          isCurrentEmployee: false,
          position: 'Flutter Developer',
          workPeriod: DateTime(2020),
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          isVerified: true,
          helpfulCount: 12,
        ),
        CompanyReview(
          id: 'review_003',
          companyId: 'company_003',
          userId: 'user_003',
          userName: 'นายบุญมี',
          rating: 3.5,
          title: 'งานมั่นคง แต่ค่อนข้างเครียด',
          review: 'งานมั่นคง มีประกันสุขภาพ แต่บางช่วงค่อนข้างเครียดเพราะปริมาณงานเยอะ',
          pros: ['งานมั่นคง', 'ประกันสุขภาพดี', 'เพื่อนร่วมงานดี'],
          cons: ['ปริมาณงานเยอะ', 'บางช่วงเครียด', 'OT บ่อย'],
          ratings: {
            'workLife': 3.0,
            'salary': 3.5,
            'management': 3.5,
            'career': 3.0,
          },
          isCurrentEmployee: true,
          position: 'Warehouse Supervisor',
          workPeriod: DateTime(2019),
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
          isVerified: false,
          helpfulCount: 5,
        ),
      ];
      
      state = state.copyWith(
        reviews: mockReviews,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // รับรีวิวของบริษัทเฉพาะ
  List<CompanyReview> getCompanyReviews(String companyId) {
    return state.reviews.where((review) => review.companyId == companyId).toList();
  }

  // เพิ่มรีวิวใหม่
  Future<void> addReview(CompanyReview review) async {
    try {
      // TODO: เรียก API เพิ่มรีวิว
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedReviews = [...state.reviews, review];
      state = state.copyWith(reviews: updatedReviews);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // อัพเดตรีวิว
  Future<void> updateReview(CompanyReview updatedReview) async {
    try {
      // TODO: เรียก API อัพเดตรีวิว
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedReviews = state.reviews.map((review) {
        return review.id == updatedReview.id ? updatedReview : review;
      }).toList();

      state = state.copyWith(reviews: updatedReviews);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ลบรีวิว
  Future<void> deleteReview(String reviewId) async {
    try {
      // TODO: เรียก API ลบรีวิว
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedReviews = state.reviews.where((review) => review.id != reviewId).toList();
      state = state.copyWith(reviews: updatedReviews);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // โหวตว่ารีวิวมีประโยชน์
  Future<void> markReviewHelpful(String reviewId) async {
    try {
      // TODO: เรียก API โหวต
      await Future.delayed(const Duration(milliseconds: 200));

      final updatedReviews = state.reviews.map((review) {
        if (review.id == reviewId) {
          return review.copyWith(helpfulCount: review.helpfulCount + 1);
        }
        return review;
      }).toList();

      state = state.copyWith(reviews: updatedReviews);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // รับค่าเฉลี่ยคะแนนของบริษัท
  double getCompanyAverageRating(String companyId) {
    return state.getAverageRating(companyId);
  }

  // รับสถิติรีวิวของบริษัท
  Map<String, dynamic> getCompanyReviewStats(String companyId) {
    final companyReviews = getCompanyReviews(companyId);
    
    if (companyReviews.isEmpty) {
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': <int, int>{},
        'categoryRatings': <String, double>{},
      };
    }

    final totalReviews = companyReviews.length;
    final averageRating = companyReviews.fold<double>(0.0, (sum, review) => sum + review.rating) / totalReviews;
    
    // การกระจายคะแนน (1-5 ดาว)
    final ratingDistribution = <int, int>{};
    for (int i = 1; i <= 5; i++) {
      ratingDistribution[i] = companyReviews.where((r) => r.rating.round() == i).length;
    }

    // คะแนนเฉลี่ยตามหมวดหมู่
    final categoryRatings = <String, double>{};
    final categories = ['workLife', 'salary', 'management', 'career'];
    
    for (final category in categories) {
      final ratings = companyReviews
          .where((r) => r.ratings.containsKey(category))
          .map((r) => r.ratings[category]!)
          .toList();
      
      if (ratings.isNotEmpty) {
        categoryRatings[category] = ratings.reduce((a, b) => a + b) / ratings.length;
      }
    }

    return {
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
      'categoryRatings': categoryRatings,
    };
  }

  // ค้นหารีวิว
  List<CompanyReview> searchReviews(String query) {
    if (query.isEmpty) return state.reviews;
    
    final lowerQuery = query.toLowerCase();
    return state.reviews.where((review) {
      return review.title.toLowerCase().contains(lowerQuery) ||
             review.review.toLowerCase().contains(lowerQuery) ||
             review.position.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // กรองรีวิวตามคะแนน
  List<CompanyReview> filterReviewsByRating(double minRating, double maxRating) {
    return state.reviews.where((review) {
      return review.rating >= minRating && review.rating <= maxRating;
    }).toList();
  }

  // เรียงรีวิวตามความใหม่
  List<CompanyReview> getRecentReviews({int limit = 10}) {
    final sorted = [...state.reviews];
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }

  // เรียงรีวิวตามความมีประโยชน์
  List<CompanyReview> getMostHelpfulReviews({int limit = 10}) {
    final sorted = [...state.reviews];
    sorted.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
    return sorted.take(limit).toList();
  }

  // ล้างข้อผิดพลาด
  void clearError() {
    state = state.copyWith(error: null);
  }

  // รีเฟรชข้อมูล
  Future<void> refresh() async {
    await loadReviews();
  }
}