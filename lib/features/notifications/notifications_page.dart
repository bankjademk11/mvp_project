import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';
import '../../services/language_service.dart';
import '../../models/notification.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลการแจ้งเตือนเมื่อเปิดหน้า
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationServiceProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationServiceProvider);
    final languageState = ref.watch(languageProvider);
    final t = (key) => AppLocalizations.translate(key, languageState.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('notifications')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          if (notificationState.notifications.isNotEmpty) ...[
            IconButton(
              onPressed: () {
                ref.read(notificationServiceProvider.notifier).markAllAsRead();
              },
              icon: const Icon(Icons.mark_email_read),
              tooltip: t('mark_all_read'),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showClearAllDialog();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.clear_all, size: 20),
                      const SizedBox(width: 8),
                      Text(t('clear_notifications')),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationServiceProvider.notifier).refresh();
        },
        child: _buildBody(notificationState, t),
      ),
    );
  }

  Widget _buildBody(notificationState, Function t) {
    if (notificationState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (notificationState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              notificationState.error!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(notificationServiceProvider.notifier).refresh();
              },
              child: Text(t('try_again')),
            ),
          ],
        ),
      );
    }

    if (notificationState.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              t('no_notifications'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              t('no_notifications_desc'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notificationState.notifications.length,
      itemBuilder: (context, index) {
        final notification = notificationState.notifications[index];
        return _buildNotificationItem(notification, t);
      },
    );
  }

  Widget _buildNotificationItem(AppNotification notification, Function t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: notification.isRead ? 1 : 3,
        color: notification.isRead 
            ? Colors.white
            : Theme.of(context).colorScheme.primary.withOpacity(0.05),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNotificationIcon(notification),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatNotificationTime(notification.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          _buildPriorityBadge(notification.priority),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleNotificationAction(value, notification),
                  itemBuilder: (context) => [
                    if (!notification.isRead)
                      PopupMenuItem(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read, size: 18),
                            const SizedBox(width: 8),
                            Text(t('mark_as_read')),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 18),
                          const SizedBox(width: 8),
                          Text(t('delete')),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(AppNotification notification) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.newJob:
        iconData = Icons.work_outline;
        iconColor = Colors.blue;
        break;
      case NotificationType.jobApplication:
        iconData = Icons.assignment_outlined;
        iconColor = Colors.green;
        break;
      case NotificationType.chatMessage:
        iconData = Icons.message_outlined;
        iconColor = Colors.orange;
        break;
      case NotificationType.interviewSchedule:
        iconData = Icons.schedule_outlined;
        iconColor = Colors.purple;
        break;
      case NotificationType.applicationStatus:
        iconData = Icons.update_outlined;
        iconColor = Colors.teal;
        break;
      case NotificationType.systemUpdate:
        iconData = Icons.system_update_outlined;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildPriorityBadge(NotificationPriority priority) {
    if (priority == NotificationPriority.low || priority == NotificationPriority.medium) {
      return const SizedBox.shrink();
    }

    Color badgeColor;
    String text;

    switch (priority) {
      case NotificationPriority.high:
        badgeColor = Colors.orange;
        text = 'สำคัญ';
        break;
      case NotificationPriority.critical:
        badgeColor = Colors.red;
        text = 'เร่งด่วน';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // ทำเครื่องหมายว่าอ่านแล้ว
    if (!notification.isRead) {
      ref.read(notificationServiceProvider.notifier).markAsRead(notification.id);
    }

    // นำทางไปยังหน้าที่เกี่ยวข้อง
    if (notification.actionUrl != null) {
      context.push(notification.actionUrl!);
    }
  }

  void _handleNotificationAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        ref.read(notificationServiceProvider.notifier).markAsRead(notification.id);
        break;
      case 'delete':
        ref.read(notificationServiceProvider.notifier).deleteNotification(notification.id);
        break;
    }
  }

  void _showClearAllDialog() {
    final t = (key) => AppLocalizations.translate(key, ref.read(languageProvider).languageCode);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('clear_notifications')),
        content: Text('คุณต้องการล้างการแจ้งเตือนทั้งหมดหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t('cancel')),
          ),
          FilledButton(
            onPressed: () {
              ref.read(notificationServiceProvider.notifier).clearAllNotifications();
              Navigator.pop(context);
            },
            child: Text(t('clear_notifications')),
          ),
        ],
      ),
    );
  }

  String _formatNotificationTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final languageCode = ref.read(languageProvider).languageCode;
    
    if (difference.inMinutes < 1) {
      return 'เมื่อสักครู่';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays == 1) {
      return AppLocalizations.translate('yesterday', languageCode);
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${AppLocalizations.translate('days_ago', languageCode)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}