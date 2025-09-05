// การแจ้งเตือน Model
enum NotificationType {
  newJob,
  jobApplication,
  chatMessage,
  interviewSchedule,
  applicationStatus,
  systemUpdate,
}

enum NotificationPriority {
  low,
  medium,
  high,
  critical,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // ข้อมูลเพิ่มเติม
  final String? actionUrl; // สำหรับการนำทาง

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.medium,
    this.isRead = false,
    required this.createdAt,
    this.data,
    this.actionUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.systemUpdate,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == 'NotificationPriority.${json['priority']}',
        orElse: () => NotificationPriority.medium,
      ),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      data: json['data'],
      actionUrl: json['actionUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
      'actionUrl': actionUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

// State สำหรับการจัดการการแจ้งเตือน
class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}