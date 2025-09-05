import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';

// Provider สำหรับ Notification Service
final notificationServiceProvider = StateNotifierProvider<NotificationService, NotificationState>((ref) {
  return NotificationService();
});

class NotificationService extends StateNotifier<NotificationState> {
  NotificationService() : super(const NotificationState()) {
    loadNotifications();
  }

  // โหลดการแจ้งเตือนทั้งหมด
  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // TODO: เรียก API จริง
      await Future.delayed(const Duration(milliseconds: 500));
      
      final mockNotifications = [
        AppNotification(
          id: 'notif_001',
          title: 'งานใหม่ที่คุณอาจสนใจ',
          message: 'มี Flutter Developer ใหม่ที่ NX Creations',
          type: NotificationType.newJob,
          priority: NotificationPriority.medium,
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          data: {'jobId': 'job_002'},
          actionUrl: '/jobs/job_002',
        ),
        AppNotification(
          id: 'notif_002',
          title: 'ข้อความใหม่',
          message: 'HR จาก ODG Mall ส่งข้อความถึงคุณ',
          type: NotificationType.chatMessage,
          priority: NotificationPriority.high,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          data: {'chatId': 'chat_001'},
          actionUrl: '/chats/chat_001',
        ),
        AppNotification(
          id: 'notif_003',
          title: 'สถานะใบสมัครอัพเดต',
          message: 'ใบสมัครของคุณอยู่ในขั้นตอน "กำลังพิจารณา"',
          type: NotificationType.applicationStatus,
          priority: NotificationPriority.medium,
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          data: {'applicationId': 'app_001'},
          actionUrl: '/applications',
        ),
      ];
      
      final unreadCount = mockNotifications.where((n) => !n.isRead).length;
      
      state = state.copyWith(
        notifications: mockNotifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  // เพิ่มการแจ้งเตือนใหม่
  Future<void> addNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) async {
    try {
      final newNotification = AppNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        type: type,
        priority: priority,
        createdAt: DateTime.now(),
        data: data,
        actionUrl: actionUrl,
      );

      // TODO: เรียก API เพิ่มการแจ้งเตือน
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedNotifications = [newNotification, ...state.notifications];
      final newUnreadCount = state.unreadCount + 1;
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ทำเครื่องหมายว่าอ่านแล้ว
  Future<void> markAsRead(String notificationId) async {
    try {
      // TODO: เรียก API อัพเดตสถานะ
      await Future.delayed(const Duration(milliseconds: 200));

      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId && !notification.isRead) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      final newUnreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ทำเครื่องหมายทั้งหมดว่าอ่านแล้ว
  Future<void> markAllAsRead() async {
    try {
      // TODO: เรียก API อัพเดตสถานะทั้งหมด
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ลบการแจ้งเตือน
  Future<void> deleteNotification(String notificationId) async {
    try {
      // TODO: เรียก API ลบการแจ้งเตือน
      await Future.delayed(const Duration(milliseconds: 300));

      final now = DateTime.now();
      final notificationToDelete = state.notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => AppNotification(
          id: '',
          title: '',
          message: '',
          type: NotificationType.systemUpdate,
          createdAt: now,
        ),
      );

      final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
      final newUnreadCount = notificationToDelete.isRead ? state.unreadCount : state.unreadCount - 1;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ล้างการแจ้งเตือนทั้งหมด
  Future<void> clearAllNotifications() async {
    try {
      // TODO: เรียก API ล้างการแจ้งเตือนทั้งหมด
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        notifications: [],
        unreadCount: 0,
      );
    } catch (error) {
      state = state.copyWith(error: error.toString());
    }
  }

  // ล้างข้อผิดพลาด
  void clearError() {
    state = state.copyWith(error: null);
  }

  // รีเฟรชข้อมูล
  Future<void> refresh() async {
    await loadNotifications();
  }

  // ส่งการแจ้งเตือนตามประเภท
  Future<void> sendJobNotification(String jobTitle, String companyName, String jobId) async {
    await addNotification(
      title: 'งานใหม่ที่คุณอาจสนใจ',
      message: 'มี $jobTitle ใหม่ที่ $companyName',
      type: NotificationType.newJob,
      data: {'jobId': jobId},
      actionUrl: '/jobs/$jobId',
    );
  }

  Future<void> sendApplicationNotification(String status, String jobTitle) async {
    await addNotification(
      title: 'สถานะใบสมัครอัพเดต',
      message: 'ใบสมัครสำหรับตำแหน่ง $jobTitle อยู่ในขั้นตอน "$status"',
      type: NotificationType.applicationStatus,
      priority: NotificationPriority.high,
      actionUrl: '/applications',
    );
  }

  Future<void> sendChatNotification(String senderName, String message, String chatId) async {
    await addNotification(
      title: 'ข้อความใหม่',
      message: '$senderName: $message',
      type: NotificationType.chatMessage,
      priority: NotificationPriority.high,
      data: {'chatId': chatId},
      actionUrl: '/chats/$chatId',
    );
  }
}