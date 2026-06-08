// lib/features/notifications/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/models.dart';
import '../../bookings/controllers/booking_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'bid_accepted':    return Icons.check_circle;
      case 'bid_rejected':    return Icons.cancel;
      case 'outbid':          return Icons.gavel;
      case 'booking_confirmed': return Icons.confirmation_num;
      default:                return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'bid_accepted':    return AppColors.success;
      case 'bid_rejected':    return AppColors.error;
      case 'outbid':          return AppColors.warning;
      case 'booking_confirmed': return AppColors.primary;
      default:                return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final user = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Mark all as read button
          TextButton(
            onPressed: () async {
              if (user == null) return;
              await ref
                  .read(notificationRepositoryProvider)
                  .markAllAsRead(user.id);
              ref.invalidate(userNotificationsProvider);
              ref.invalidate(unreadNotificationCountProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.textTertiary),
              const SizedBox(height: 12),
              Text('Could not load notifications',
                  style: AppTextStyles.bodyMedium),
              TextButton(
                onPressed: () => ref.invalidate(userNotificationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No notifications yet',
                      style: AppTextStyles.headingSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Bid and booking updates will appear here',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userNotificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 70),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return _NotificationTile(
                  notification: n,
                  iconData: _iconForType(n.type),
                  iconColor: _colorForType(n.type),
                  onTap: () async {
                    if (!n.isRead) {
                      await ref
                          .read(notificationRepositoryProvider)
                          .markAsRead(n.id);
                      ref.invalidate(userNotificationsProvider);
                      ref.invalidate(unreadNotificationCountProvider);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final IconData iconData;
  final Color iconColor;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.iconData,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        color: notification.isRead
            ? Colors.transparent
            : AppColors.primaryLight.withValues(alpha: 0.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon circle
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Message + time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: notification.isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            // Unread dot
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
