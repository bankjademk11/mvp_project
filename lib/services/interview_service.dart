import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interview.dart';
import 'mock_api.dart';

// Provider สำหรับ Interview Service
final interviewServiceProvider = StateNotifierProvider<InterviewService, InterviewState>((ref) {
  return InterviewService();
});

class InterviewService extends StateNotifier<InterviewState> {
  InterviewService() : super(const InterviewState()) {
    loadInterviews();
  }

  // โหลดการนัดหมายสัมภาษณ์ทั้งหมด
  Future<void> loadInterviews() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: เรียก API จริง
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockInterviews = [
        Interview(
          id: 'interview_001',
          jobId: 'job_001',
          applicationId: 'app_001',
          employerId: 'emp_001',
          candidateId: 'user_001',
          type: InterviewType.videoCall,
          status: InterviewStatus.scheduled,
          scheduledTime: DateTime.now().add(const Duration(days: 2, hours: 2)),
          durationMinutes: 60,
          meetingUrl: 'https://meet.google.com/abc-defg-hij',
          notes: 'เตรียมการนำเสนอผลงานและ portfolio',
          preparation: {
            'documents': ['CV', 'Portfolio', 'Certificates'],
            'topics': ['Experience', 'Technical Skills', 'Project Examples'],
            'questions': [
              'บอกเล่าเกี่ยวกับตัวคุณ',
              'ทำไมคุณถึงสนใจตำแหน่งนี้',
              'จุดแข็งและจุดอ่อนของคุณคืออะไร',
            ],
          },
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Interview(
          id: 'interview_002',
          jobId: 'job_002',
          applicationId: 'app_002',
          employerId: 'emp_002',
          candidateId: 'user_001',
          type: InterviewType.inPerson,
          status: InterviewStatus.confirmed,
          scheduledTime: DateTime.now().add(const Duration(days: 5, hours: 10)),
          durationMinutes: 90,
          location: '123 Setthathirath Road, Vientiane Capital',
          notes: 'การสัมภาษณ์รอบสุดท้าย พบ CEO และ CTO',
          preparation: {
            'documents': ['CV', 'Reference Letters'],
            'dresscode': 'Business Formal',
            'topics': ['Leadership', 'Team Management', 'Company Vision'],
          },
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        Interview(
          id: 'interview_003',
          jobId: 'job_003',
          applicationId: 'app_003',
          employerId: 'emp_003',
          candidateId: 'user_001',
          type: InterviewType.phoneCall,
          status: InterviewStatus.completed,
          scheduledTime: DateTime.now().subtract(const Duration(days: 7)),
          durationMinutes: 30,
          notes: 'การสัมภาษณ์เบื้องต้น ผ่านไปด้วยดี',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          updatedAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
      ];

      // กรองการสัมภาษณ์ที่กำลังจะมาถึง
      final upcomingInterviews = mockInterviews.where((interview) {
        return interview.scheduledTime.isAfter(DateTime.now()) &&
               interview.status != InterviewStatus.cancelled &&
               interview.status != InterviewStatus.completed;
      }).toList();

      // เรียงตามเวลา
      upcomingInterviews.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
      
      state = state.copyWith(
        interviews: mockInterviews,
        upcomingInterviews: upcomingInterviews,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // สร้างการนัดหมายสัมภาษณ์ใหม่
  Future<void> scheduleInterview({
    required String jobId,
    required String applicationId,
    required String employerId,
    required InterviewType type,
    required DateTime scheduledTime,
    int durationMinutes = 60,
    String? location,
    String? meetingUrl,
    String? notes,
    Map<String, dynamic>? preparation,
  }) async {
    try {
      // TODO: เรียก API สร้างการนัดหมาย
      await Future.delayed(const Duration(milliseconds: 500));

      final newInterview = Interview(
        id: 'interview_${DateTime.now().millisecondsSinceEpoch}',
        jobId: jobId,
        applicationId: applicationId,
        employerId: employerId,
        candidateId: 'user_001', // TODO: ใช้ user ID จริง
        type: type,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
        location: location,
        meetingUrl: meetingUrl,
        notes: notes,
        preparation: preparation,
        createdAt: DateTime.now(),
      );

      final updatedInterviews = [...state.interviews, newInterview];
      
      // อัพเดตการสัมภาษณ์ที่กำลังจะมาถึง
      final upcomingInterviews = updatedInterviews.where((interview) {
        return interview.scheduledTime.isAfter(DateTime.now()) &&
               interview.status != InterviewStatus.cancelled &&
               interview.status != InterviewStatus.completed;
      }).toList();
      upcomingInterviews.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      state = state.copyWith(
        interviews: updatedInterviews,
        upcomingInterviews: upcomingInterviews,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // อัพเดตสถานะการสัมภาษณ์
  Future<void> updateInterviewStatus(String interviewId, InterviewStatus status) async {
    try {
      // TODO: เรียก API อัพเดตสถานะ
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedInterviews = state.interviews.map((interview) {
        if (interview.id == interviewId) {
          return interview.copyWith(
            status: status,
            updatedAt: DateTime.now(),
          );
        }
        return interview;
      }).toList();

      // อัพเดตการสัมภาษณ์ที่กำลังจะมาถึง
      final upcomingInterviews = updatedInterviews.where((interview) {
        return interview.scheduledTime.isAfter(DateTime.now()) &&
               interview.status != InterviewStatus.cancelled &&
               interview.status != InterviewStatus.completed;
      }).toList();
      upcomingInterviews.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      state = state.copyWith(
        interviews: updatedInterviews,
        upcomingInterviews: upcomingInterviews,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // เลื่อนการสัมภาษณ์
  Future<void> rescheduleInterview(String interviewId, DateTime newScheduledTime) async {
    try {
      // TODO: เรียก API เลื่อนการนัดหมาย
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedInterviews = state.interviews.map((interview) {
        if (interview.id == interviewId) {
          return interview.copyWith(
            scheduledTime: newScheduledTime,
            status: InterviewStatus.rescheduled,
            updatedAt: DateTime.now(),
          );
        }
        return interview;
      }).toList();

      // อัพเดตการสัมภาษณ์ที่กำลังจะมาถึง
      final upcomingInterviews = updatedInterviews.where((interview) {
        return interview.scheduledTime.isAfter(DateTime.now()) &&
               interview.status != InterviewStatus.cancelled &&
               interview.status != InterviewStatus.completed;
      }).toList();
      upcomingInterviews.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

      state = state.copyWith(
        interviews: updatedInterviews,
        upcomingInterviews: upcomingInterviews,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ยกเลิกการสัมภาษณ์
  Future<void> cancelInterview(String interviewId, String reason) async {
    try {
      // TODO: เรียก API ยกเลิกการนัดหมาย
      await Future.delayed(const Duration(milliseconds: 300));

      await updateInterviewStatus(interviewId, InterviewStatus.cancelled);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // รับการสัมภาษณ์ตาม jobId
  List<Interview> getInterviewsByJob(String jobId) {
    return state.interviews.where((interview) => interview.jobId == jobId).toList();
  }

  // รับการสัมภาษณ์ตามสถานะ
  List<Interview> getInterviewsByStatus(InterviewStatus status) {
    return state.interviews.where((interview) => interview.status == status).toList();
  }

  // รับการสัมภาษณ์ในวันที่กำหนด
  List<Interview> getInterviewsByDate(DateTime date) {
    return state.interviews.where((interview) {
      final interviewDate = interview.scheduledTime;
      return interviewDate.year == date.year &&
             interviewDate.month == date.month &&
             interviewDate.day == date.day;
    }).toList();
  }

  // รับการสัมภาษณ์ในสัปดาห์นี้
  List<Interview> getThisWeekInterviews() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return state.interviews.where((interview) {
      return interview.scheduledTime.isAfter(startOfWeek) &&
             interview.scheduledTime.isBefore(endOfWeek) &&
             interview.status != InterviewStatus.cancelled;
    }).toList();
  }

  // รับการแจ้งเตือนการสัมภาษณ์
  List<Interview> getUpcomingReminders() {
    final now = DateTime.now();
    final next24Hours = now.add(const Duration(hours: 24));

    return state.upcomingInterviews.where((interview) {
      return interview.scheduledTime.isAfter(now) &&
             interview.scheduledTime.isBefore(next24Hours);
    }).toList();
  }

  // เพิ่มเตรียมการสำหรับการสัมภาษณ์
  Future<void> updatePreparation(String interviewId, Map<String, dynamic> preparation) async {
    try {
      // TODO: เรียก API อัพเดตการเตรียมตัว
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedInterviews = state.interviews.map((interview) {
        if (interview.id == interviewId) {
          return interview.copyWith(
            preparation: preparation,
            updatedAt: DateTime.now(),
          );
        }
        return interview;
      }).toList();

      state = state.copyWith(interviews: updatedInterviews);
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // รับสถิติการสัมภาษณ์
  Map<String, dynamic> getInterviewStatistics() {
    final total = state.interviews.length;
    final completed = getInterviewsByStatus(InterviewStatus.completed).length;
    final upcoming = state.upcomingInterviews.length;
    final cancelled = getInterviewsByStatus(InterviewStatus.cancelled).length;

    return {
      'total': total,
      'completed': completed,
      'upcoming': upcoming,
      'cancelled': cancelled,
      'completionRate': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
    };
  }

  // ล้างข้อผิดพลาด
  void clearError() {
    state = state.copyWith(error: null);
  }

  // รีเฟรชข้อมูล
  Future<void> refresh() async {
    await loadInterviews();
  }
}