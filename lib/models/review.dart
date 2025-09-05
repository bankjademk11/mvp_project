// รีวิวบริษัท Model
enum ReviewType {
  company,
  interview,
  salary,
}

class CompanyReview {
  final String id;
  final String companyId;
  final String userId;
  final String userName;
  final ReviewType type;
  final double rating;
  final String title;
  final String review;
  final List<String> pros;
  final List<String> cons;
  final Map<String, double> ratings; // เช่น workLife, salary, management
  final bool isCurrentEmployee;
  final String position;
  final DateTime workPeriod;
  final DateTime createdAt;
  final bool isVerified;
  final int helpfulCount;

  const CompanyReview({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.userName,
    this.type = ReviewType.company,
    required this.rating,
    required this.title,
    required this.review,
    this.pros = const [],
    this.cons = const [],
    this.ratings = const {},
    this.isCurrentEmployee = false,
    required this.position,
    required this.workPeriod,
    required this.createdAt,
    this.isVerified = false,
    this.helpfulCount = 0,
  });

  factory CompanyReview.fromJson(Map<String, dynamic> json) {
    return CompanyReview(
      id: json['id'] ?? '',
      companyId: json['companyId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      type: ReviewType.values.firstWhere(
        (e) => e.toString() == 'ReviewType.${json['type']}',
        orElse: () => ReviewType.company,
      ),
      rating: (json['rating'] ?? 0.0).toDouble(),
      title: json['title'] ?? '',
      review: json['review'] ?? '',
      pros: List<String>.from(json['pros'] ?? []),
      cons: List<String>.from(json['cons'] ?? []),
      ratings: Map<String, double>.from(json['ratings'] ?? {}),
      isCurrentEmployee: json['isCurrentEmployee'] ?? false,
      position: json['position'] ?? '',
      workPeriod: DateTime.parse(json['workPeriod'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      isVerified: json['isVerified'] ?? false,
      helpfulCount: json['helpfulCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'userId': userId,
      'userName': userName,
      'type': type.toString().split('.').last,
      'rating': rating,
      'title': title,
      'review': review,
      'pros': pros,
      'cons': cons,
      'ratings': ratings,
      'isCurrentEmployee': isCurrentEmployee,
      'position': position,
      'workPeriod': workPeriod.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
      'helpfulCount': helpfulCount,
    };
  }

  CompanyReview copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? userName,
    ReviewType? type,
    double? rating,
    String? title,
    String? review,
    List<String>? pros,
    List<String>? cons,
    Map<String, double>? ratings,
    bool? isCurrentEmployee,
    String? position,
    DateTime? workPeriod,
    DateTime? createdAt,
    bool? isVerified,
    int? helpfulCount,
  }) {
    return CompanyReview(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      type: type ?? this.type,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      review: review ?? this.review,
      pros: pros ?? this.pros,
      cons: cons ?? this.cons,
      ratings: ratings ?? this.ratings,
      isCurrentEmployee: isCurrentEmployee ?? this.isCurrentEmployee,
      position: position ?? this.position,
      workPeriod: workPeriod ?? this.workPeriod,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      helpfulCount: helpfulCount ?? this.helpfulCount,
    );
  }
}

// State สำหรับการจัดการรีวิว
class ReviewState {
  final List<CompanyReview> reviews;
  final bool isLoading;
  final String? error;

  const ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.error,
  });

  ReviewState copyWith({
    List<CompanyReview>? reviews,
    bool? isLoading,
    String? error,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  double getAverageRating(String companyId) {
    final companyReviews = reviews.where((r) => r.companyId == companyId).toList();
    if (companyReviews.isEmpty) return 0.0;
    
    final total = companyReviews.fold<double>(0.0, (sum, review) => sum + review.rating);
    return total / companyReviews.length;
  }
}