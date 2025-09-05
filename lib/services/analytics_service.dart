import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/analytics.dart';
import 'mock_api.dart';

// Provider สำหรับ Analytics Service
final analyticsServiceProvider = StateNotifierProvider<AnalyticsService, AnalyticsState>((ref) {
  return AnalyticsService();
});

class AnalyticsService extends StateNotifier<AnalyticsState> {
  AnalyticsService() : super(const AnalyticsState()) {
    loadAnalytics();
  }

  // โหลดข้อมูล Analytics ทั้งหมด
  Future<void> loadAnalytics() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: เรียก API จริง
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Mock Job Statistics
      final mockJobStats = JobStatistics(
        totalJobs: 156,
        todayJobs: 8,
        weeklyJobs: 24,
        monthlyJobs: 89,
        jobsByCategory: {
          'Technology': 45,
          'Sales': 38,
          'Marketing': 22,
          'Finance': 18,
          'HR': 15,
          'Operations': 12,
          'Design': 6,
        },
        jobsByProvince: {
          'Vientiane Capital': 98,
          'Savannakhet': 24,
          'Luang Prabang': 16,
          'Champasak': 12,
          'Khammouane': 6,
        },
        averageSalaryByCategory: {
          'Technology': 12500000.0,
          'Finance': 11000000.0,
          'Sales': 8500000.0,
          'Marketing': 9000000.0,
          'HR': 8000000.0,
          'Operations': 7500000.0,
          'Design': 10000000.0,
        },
        salaryTrends: [
          {'month': 'ม.ค.', 'average': 8200000.0},
          {'month': 'ก.พ.', 'average': 8500000.0},
          {'month': 'มี.ค.', 'average': 8800000.0},
          {'month': 'เม.ย.', 'average': 9100000.0},
          {'month': 'พ.ค.', 'average': 9400000.0},
          {'month': 'มิ.ย.', 'average': 9700000.0},
        ],
      );

      // Mock User Analytics
      final mockUserAnalytics = UserAnalytics(
        userId: 'user_001',
        profileViews: 127,
        applicationsSent: 23,
        messagesReceived: 45,
        applicationsByStatus: {
          'pending': 8,
          'reviewing': 5,
          'interview': 3,
          'accepted': 2,
          'rejected': 5,
        },
        activityHistory: [
          {
            'date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'action': 'profile_view',
            'count': 5,
          },
          {
            'date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
            'action': 'job_application',
            'count': 2,
          },
          {
            'date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
            'action': 'message_received',
            'count': 3,
          },
        ],
        lastUpdated: DateTime.now(),
      );
      
      state = state.copyWith(
        jobStats: mockJobStats,
        userAnalytics: mockUserAnalytics,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // รับสถิติงานตามหมวดหมู่
  Map<String, int> getJobsByCategory() {
    return state.jobStats?.jobsByCategory ?? {};
  }

  // รับสถิติงานตามจังหวัด
  Map<String, int> getJobsByProvince() {
    return state.jobStats?.jobsByProvince ?? {};
  }

  // รับข้อมูลเงินเดือนเฉลี่ยตามหมวดหมู่
  Map<String, double> getAverageSalaryByCategory() {
    return state.jobStats?.averageSalaryByCategory ?? {};
  }

  // รับแนวโน้มเงินเดือน
  List<Map<String, dynamic>> getSalaryTrends() {
    return state.jobStats?.salaryTrends ?? [];
  }

  // รับสถิติการสมัครงานของผู้ใช้
  Map<String, int> getUserApplicationStats() {
    return state.userAnalytics?.applicationsByStatus ?? {};
  }

  // รับประวัติกิจกรรมของผู้ใช้
  List<Map<String, dynamic>> getUserActivityHistory() {
    return state.userAnalytics?.activityHistory ?? [];
  }

  // อัพเดตสถิติผู้ใช้
  Future<void> updateUserStats({
    int? profileViews,
    int? applicationsSent,
    int? messagesReceived,
  }) async {
    if (state.userAnalytics == null) return;
    
    try {
      // TODO: เรียก API อัพเดตสถิติ
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedAnalytics = state.userAnalytics!.copyWith(
        profileViews: profileViews ?? state.userAnalytics!.profileViews,
        applicationsSent: applicationsSent ?? state.userAnalytics!.applicationsSent,
        messagesReceived: messagesReceived ?? state.userAnalytics!.messagesReceived,
        lastUpdated: DateTime.now(),
      );

      state = state.copyWith(userAnalytics: updatedAnalytics);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // เพิ่มกิจกรรมใหม่
  Future<void> addActivity(String action, int count) async {
    if (state.userAnalytics == null) return;
    
    try {
      final newActivity = {
        'date': DateTime.now().toIso8601String(),
        'action': action,
        'count': count,
      };

      final updatedHistory = [newActivity, ...state.userAnalytics!.activityHistory];
      
      // เก็บประวัติแค่ 30 รายการล่าสุด
      final limitedHistory = updatedHistory.take(30).toList();

      final updatedAnalytics = state.userAnalytics!.copyWith(
        activityHistory: limitedHistory,
        lastUpdated: DateTime.now(),
      );

      state = state.copyWith(userAnalytics: updatedAnalytics);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // รับสถิติแดชบอร์ดหลัก
  Map<String, dynamic> getDashboardStats() {
    final jobStats = state.jobStats;
    final userStats = state.userAnalytics;
    
    if (jobStats == null || userStats == null) {
      return {};
    }

    return {
      'totalJobs': jobStats.totalJobs,
      'todayJobs': jobStats.todayJobs,
      'weeklyJobs': jobStats.weeklyJobs,
      'monthlyJobs': jobStats.monthlyJobs,
      'profileViews': userStats.profileViews,
      'applicationsSent': userStats.applicationsSent,
      'messagesReceived': userStats.messagesReceived,
      'successRate': _calculateSuccessRate(),
    };
  }

  // คำนวณอัตราความสำเร็จในการสมัครงาน
  double _calculateSuccessRate() {
    final applications = state.userAnalytics?.applicationsByStatus ?? {};
    final total = applications.values.fold<int>(0, (sum, count) => sum + count);
    
    if (total == 0) return 0.0;
    
    final accepted = applications['accepted'] ?? 0;
    return (accepted / total) * 100;
  }

  // รับข้อมูลเปรียบเทียบกับผู้ใช้คนอื่น
  Map<String, dynamic> getBenchmarkData() {
    // TODO: เรียก API เปรียบเทียบข้อมูล
    return {
      'averageProfileViews': 85,
      'averageApplications': 18,
      'averageSuccessRate': 12.5,
      'yourRanking': {
        'profileViews': 'Top 25%',
        'applications': 'Average',
        'successRate': 'Top 15%',
      },
    };
  }

  // รับคำแนะนำสำหรับการปรับปรุง
  List<String> getImprovementSuggestions() {
    final userStats = state.userAnalytics;
    if (userStats == null) return [];

    final suggestions = <String>[];
    
    // แนะนำตามจำนวนการดูโปรไฟล์
    if (userStats.profileViews < 50) {
      suggestions.add('อัพเดตโปรไฟล์ให้สมบูรณ์เพื่อเพิ่มการมองเห็น');
    }
    
    // แนะนำตามจำนวนการสมัครงาน
    if (userStats.applicationsSent < 10) {
      suggestions.add('ลองสมัครงานให้มากขึ้นเพื่อเพิ่มโอกาส');
    }
    
    // แนะนำตามอัตราความสำเร็จ
    final successRate = _calculateSuccessRate();
    if (successRate < 10) {
      suggestions.add('ปรับปรุง CV และเตรียมตัวสำหรับการสัมภาษณ์');
    }

    return suggestions;
  }

  // รับข้อมูลกราฟสำหรับแสดงผล
  Map<String, List<Map<String, dynamic>>> getChartData() {
    return {
      'jobsByCategory': getJobsByCategory().entries.map((entry) => {
        'category': entry.key,
        'count': entry.value,
      }).toList(),
      'jobsByProvince': getJobsByProvince().entries.map((entry) => {
        'province': entry.key,
        'count': entry.value,
      }).toList(),
      'salaryTrends': getSalaryTrends(),
      'applicationStatus': getUserApplicationStats().entries.map((entry) => {
        'status': entry.key,
        'count': entry.value,
      }).toList(),
    };
  }

  // ล้างข้อผิดพลาด
  void clearError() {
    state = state.copyWith(error: null);
  }

  // รีเฟรชข้อมูล
  Future<void> refresh() async {
    await loadAnalytics();
  }

  // ส่งออกข้อมูลสถิติ
  Future<String> exportAnalytics(String format) async {
    try {
      // TODO: เรียก API ส่งออกข้อมูล
      await Future.delayed(const Duration(seconds: 2));
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'https://example.com/exports/analytics_$timestamp.$format';
    } catch (error) {
      throw Exception('ไม่สามารถส่งออกข้อมูลได้: $error');
    }
  }
}