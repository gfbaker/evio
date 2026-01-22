import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';

/// Ícono de campana con badge de notificaciones no leídas
class NotificationBell extends ConsumerWidget {
  final Color? iconColor;
  final double iconSize;

  const NotificationBell({
    this.iconColor,
    this.iconSize = 24,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ No mostrar si usuario no está logueado
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    if (!isAuthenticated) return const SizedBox.shrink();
    
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    final color = iconColor ?? EvioFanColors.foreground;

    return IconButton(
      onPressed: () => context.push('/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            unreadCount > 0
                ? Icons.notifications
                : Icons.notifications_none,
            size: iconSize,
            color: color,
          ),
          if (unreadCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: EdgeInsets.all(unreadCount > 9 ? 2 : 4),
                constraints: BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                decoration: BoxDecoration(
                  color: EvioFanColors.primary,
                  shape: unreadCount > 9 ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: unreadCount > 9
                      ? BorderRadius.circular(8)
                      : null,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: EvioFanColors.primaryForeground,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
