import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';

class NotificationBadge extends ConsumerWidget {
  final Widget child;
  final bool showBadge;

  const NotificationBadge({
    super.key,
    required this.child,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showBadge) return child;

    final notificationState = ref.watch(notificationServiceProvider);
    final unreadCount = notificationState.unreadCount;

    if (unreadCount == 0) return child;

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class NotificationIcon extends ConsumerWidget {
  final VoidCallback? onTap;
  final double? size;
  final Color? color;

  const NotificationIcon({
    super.key,
    this.onTap,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NotificationBadge(
      child: IconButton(
        onPressed: onTap ?? () => context.push('/notifications'),
        icon: Icon(
          Icons.notifications_outlined,
          size: size,
          color: color,
        ),
      ),
    );
  }
}

class NotificationButton extends ConsumerWidget {
  final String? text;
  final VoidCallback? onPressed;
  final bool isCompact;

  const NotificationButton({
    super.key,
    this.text,
    this.onPressed,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationServiceProvider);
    final unreadCount = notificationState.unreadCount;

    if (isCompact) {
      return NotificationBadge(
        child: IconButton(
          onPressed: onPressed ?? () => context.push('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
        ),
      );
    }

    return NotificationBadge(
      child: TextButton.icon(
        onPressed: onPressed ?? () => context.push('/notifications'),
        icon: const Icon(Icons.notifications_outlined),
        label: Text(text ?? 'ການແຈ້ງເຕືອນ'),
      ),
    );
  }
}