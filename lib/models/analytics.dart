// สถิติและ Analytics Model
class JobStatistics {
  final int totalJobs;
  final int todayJobs;
  final int weeklyJobs;
  final int monthlyJobs;
  final Map<String, int> jobsByCategory;
  final Map<String, int> jobsByProvince;
  final Map<String, double> averageSalaryByCategory;
  final List<Map<String, dynamic>> salaryTrends;

  const JobStatistics({
    this.totalJobs = 0,
    this.todayJobs = 0,
    this.weeklyJobs = 0,
    this.monthlyJobs = 0,
    this.jobsByCategory = const {},
    this.jobsByProvince = const {},
    this.averageSalaryByCategory = const {},
    this.salaryTrends = const [],
  });

  factory JobStatistics.fromJson(Map<String, dynamic> json) {
    return JobStatistics(
      totalJobs: json['totalJobs'] ?? 0,
      todayJobs: json['todayJobs'] ?? 0,
      weeklyJobs: json['weeklyJobs'] ?? 0,
      monthlyJobs: json['monthlyJobs'] ?? 0,
      jobsByCategory: Map<String, int>.from(json['jobsByCategory'] ?? {}),
      jobsByProvince: Map<String, int>.from(json['jobsByProvince'] ?? {}),
      averageSalaryByCategory: Map<String, double>.from(json['averageSalaryByCategory'] ?? {}),
      salaryTrends: List<Map<String, dynamic>>.from(json['salaryTrends'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalJobs': totalJobs,
      'todayJobs': todayJobs,
      'weeklyJobs': weeklyJobs,
      'monthlyJobs': monthlyJobs,
      'jobsByCategory': jobsByCategory,
      'jobsByProvince': jobsByProvince,
      'averageSalaryByCategory': averageSalaryByCategory,
      'salaryTrends': salaryTrends,
    };
  }
}

class UserAnalytics {
  final String userId;
  final int profileViews;
  final int applicationsSent;
  final int messagesReceived;
  final Map<String, int> applicationsByStatus;
  final List<Map<String, dynamic>> activityHistory;
  final DateTime lastUpdated;

  const UserAnalytics({
    required this.userId,
    this.profileViews = 0,
    this.applicationsSent = 0,
    this.messagesReceived = 0,
    this.applicationsByStatus = const {},
    this.activityHistory = const [],
    required this.lastUpdated,
  });

  factory UserAnalytics.fromJson(Map<String, dynamic> json) {
    return UserAnalytics(
      userId: json['userId'] ?? '',
      profileViews: json['profileViews'] ?? 0,
      applicationsSent: json['applicationsSent'] ?? 0,
      messagesReceived: json['messagesReceived'] ?? 0,
      applicationsByStatus: Map<String, int>.from(json['applicationsByStatus'] ?? {}),
      activityHistory: List<Map<String, dynamic>>.from(json['activityHistory'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'profileViews': profileViews,
      'applicationsSent': applicationsSent,
      'messagesReceived': messagesReceived,
      'applicationsByStatus': applicationsByStatus,
      'activityHistory': activityHistory,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  UserAnalytics copyWith({
    String? userId,
    int? profileViews,
    int? applicationsSent,
    int? messagesReceived,
    Map<String, int>? applicationsByStatus,
    List<Map<String, dynamic>>? activityHistory,
    DateTime? lastUpdated,
  }) {
    return UserAnalytics(
      userId: userId ?? this.userId,
      profileViews: profileViews ?? this.profileViews,
      applicationsSent: applicationsSent ?? this.applicationsSent,
      messagesReceived: messagesReceived ?? this.messagesReceived,
      applicationsByStatus: applicationsByStatus ?? this.applicationsByStatus,
      activityHistory: activityHistory ?? this.activityHistory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// State สำหรับ Analytics
class AnalyticsState {
  final JobStatistics? jobStats;
  final UserAnalytics? userAnalytics;
  final bool isLoading;
  final String? error;

  const AnalyticsState({
    this.jobStats,
    this.userAnalytics,
    this.isLoading = false,
    this.error,
  });

  AnalyticsState copyWith({
    JobStatistics? jobStats,
    UserAnalytics? userAnalytics,
    bool? isLoading,
    String? error,
  }) {
    return AnalyticsState(
      jobStats: jobStats ?? this.jobStats,
      userAnalytics: userAnalytics ?? this.userAnalytics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}