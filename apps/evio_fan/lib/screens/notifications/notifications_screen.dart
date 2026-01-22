import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';
import 'widgets/notification_tile.dart';
import 'widgets/notification_empty_state.dart';

/// Pantalla minimalista de notificaciones
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        ref.read(notificationProvider.notifier).init();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: EvioFanColors.background,
      appBar: AppBar(
        backgroundColor: EvioFanColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: EvioFanColors.foreground,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: EvioFanColors.foreground,
          ),
        ),
        centerTitle: true,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
              },
              child: Text(
                'Leído',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: EvioFanColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(NotificationState state) {
    if (state.isLoading && state.notifications.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: EvioFanColors.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: EvioFanColors.mutedForeground,
            ),
            SizedBox(height: EvioSpacing.md),
            Text(
              'No se pudo cargar',
              style: TextStyle(
                fontSize: 15,
                color: EvioFanColors.mutedForeground,
              ),
            ),
            SizedBox(height: EvioSpacing.md),
            GestureDetector(
              onTap: () => ref.read(notificationProvider.notifier).refresh(),
              child: Text(
                'Reintentar',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: EvioFanColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return const NotificationEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(notificationProvider.notifier).refresh(),
      color: EvioFanColors.primary,
      backgroundColor: EvioFanColors.surface,
      child: ListView.separated(
        padding: EdgeInsets.only(
          top: EvioSpacing.xs,
          bottom: MediaQuery.of(context).padding.bottom + EvioSpacing.xl,
        ),
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.5,
          color: EvioFanColors.border.withValues(alpha: 0.3),
          indent: EvioSpacing.md + 48 + EvioSpacing.md, // Alineado con el texto
        ),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Marcar como leída
    if (notification.isUnread) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    // Navegar según el tipo
    switch (notification.type) {
      case NotificationType.purchaseConfirmed:
      case NotificationType.ticketReceived:
      case NotificationType.ticketTransferred:
      case NotificationType.invitationReceived:
        // Ir a mis tickets
        context.go('/tickets');
        break;

      case NotificationType.purchaseLinkReceived:
        // Ir a checkout con el purchase_link_id
        final linkId = notification.purchaseLinkId;
        if (linkId != null) {
          context.push('/checkout?purchase_link=$linkId');
        }
        break;

      case NotificationType.eventReminder:
      case NotificationType.eventUpdated:
      case NotificationType.eventCancelled:
        final eventId = notification.eventId;
        if (eventId != null) {
          context.push('/event/$eventId');
        }
        break;

      case NotificationType.general:
        break;
    }
  }
}
