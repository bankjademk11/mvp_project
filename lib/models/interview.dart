// การนัดหมายสัมภาษณ์ Model
enum InterviewStatus {
  scheduled,
  confirmed,
  cancelled,
  completed,
  rescheduled,
}

enum InterviewType {
  inPerson,
  videoCall,
  phoneCall,
}

class Interview {
  final String id;
  final String jobId;
  final String applicationId;
  final String employerId;
  final String candidateId;
  final InterviewType type;
  final InterviewStatus status;
  final DateTime scheduledTime;
  final int durationMinutes;
  final String? location;
  final String? meetingUrl;
  final String? notes;
  final Map<String, dynamic>? preparation;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Interview({
    required this.id,
    required this.jobId,
    required this.applicationId,
    required this.employerId,
    required this.candidateId,
    required this.type,
    this.status = InterviewStatus.scheduled,
    required this.scheduledTime,
    this.durationMinutes = 60,
    this.location,
    this.meetingUrl,
    this.notes,
    this.preparation,
    required this.createdAt,
    this.updatedAt,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      applicationId: json['applicationId'] ?? '',
      employerId: json['employerId'] ?? '',
      candidateId: json['candidateId'] ?? '',
      type: InterviewType.values.firstWhere(
        (e) => e.toString() == 'InterviewType.${json['type']}',
        orElse: () => InterviewType.inPerson,
      ),
      status: InterviewStatus.values.firstWhere(
        (e) => e.toString() == 'InterviewStatus.${json['status']}',
        orElse: () => InterviewStatus.scheduled,
      ),
      scheduledTime: DateTime.parse(json['scheduledTime'] ?? DateTime.now().toIso8601String()),
      durationMinutes: json['durationMinutes'] ?? 60,
      location: json['location'],
      meetingUrl: json['meetingUrl'],
      notes: json['notes'],
      preparation: json['preparation'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'applicationId': applicationId,
      'employerId': employerId,
      'candidateId': candidateId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'scheduledTime': scheduledTime.toIso8601String(),
      'durationMinutes': durationMinutes,
      'location': location,
      'meetingUrl': meetingUrl,
      'notes': notes,
      'preparation': preparation,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Interview copyWith({
    String? id,
    String? jobId,
    String? applicationId,
    String? employerId,
    String? candidateId,
    InterviewType? type,
    InterviewStatus? status,
    DateTime? scheduledTime,
    int? durationMinutes,
    String? location,
    String? meetingUrl,
    String? notes,
    Map<String, dynamic>? preparation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Interview(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      applicationId: applicationId ?? this.applicationId,
      employerId: employerId ?? this.employerId,
      candidateId: candidateId ?? this.candidateId,
      type: type ?? this.type,
      status: status ?? this.status,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      meetingUrl: meetingUrl ?? this.meetingUrl,
      notes: notes ?? this.notes,
      preparation: preparation ?? this.preparation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// State สำหรับการจัดการการสัมภาษณ์
class InterviewState {
  final List<Interview> interviews;
  final List<Interview> upcomingInterviews;
  final bool isLoading;
  final String? error;

  const InterviewState({
    this.interviews = const [],
    this.upcomingInterviews = const [],
    this.isLoading = false,
    this.error,
  });

  InterviewState copyWith({
    List<Interview>? interviews,
    List<Interview>? upcomingInterviews,
    bool? isLoading,
    String? error,
  }) {
    return InterviewState(
      interviews: interviews ?? this.interviews,
      upcomingInterviews: upcomingInterviews ?? this.upcomingInterviews,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}