import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';
import '../providers/session_provider.dart';
import '../models/notification_message.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const NotificationBadge({
    super.key,
    this.onTap,
    this.size = 24.0,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final currentUser = session.profile;

    if (currentUser == null) {
      return const SizedBox.shrink();
    }

    final notificationService = NotificationService();

    return StreamBuilder<List<NotificationMessage>>(
      stream: notificationService.watchUserNotifications(currentUser.uid),
      builder: (context, snapshot) {
        final unreadCount = snapshot.hasData 
            ? snapshot.data!.where((notification) => !notification.isRead).length
            : 0;

        if (unreadCount == 0) {
          return IconButton(
            onPressed: onTap,
            icon: const Icon(Icons.notifications_none),
            color: Colors.white,
          );
        }

        return Stack(
          children: [
            IconButton(
              onPressed: onTap,
              icon: const Icon(Icons.notifications),
              color: Colors.white,
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: backgroundColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minWidth: size,
                  minHeight: size,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
