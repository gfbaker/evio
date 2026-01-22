import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

/// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Estado de las notificaciones
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

/// Notifier para manejar el estado de notificaciones
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationRepository _repo;
  RealtimeChannel? _channel;
  String? _dbUserId;

  NotificationNotifier(this._repo) : super(const NotificationState());

  /// Inicializar y cargar notificaciones
  Future<void> init() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Cargar notificaciones y conteo en paralelo
      final results = await Future.wait([
        _repo.getAll(limit: 50),
        _repo.getUnreadCount(),
      ]);

      final notifications = results[0] as List<AppNotification>;
      final unreadCount = results[1] as int;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Suscribirse a cambios en tiempo real
  Future<void> subscribeToRealtime(String dbUserId) async {
    _dbUserId = dbUserId;
    
    // Cancelar suscripción anterior si existe
    if (_channel != null) {
      await _repo.unsubscribe(_channel!);
    }

    _channel = _repo.subscribeToChanges(
      dbUserId: dbUserId,
      onInsert: (notification) {
        // Agregar al inicio de la lista
        state = state.copyWith(
          notifications: [notification, ...state.notifications],
          unreadCount: state.unreadCount + 1,
        );
      },
      onUpdate: (notification) {
        // Actualizar en la lista
        final updated = state.notifications.map((n) {
          return n.id == notification.id ? notification : n;
        }).toList();

        // Recalcular unread count
        final unreadCount = updated.where((n) => n.isUnread).length;

        state = state.copyWith(
          notifications: updated,
          unreadCount: unreadCount,
        );
      },
      onDelete: (id) {
        final notification = state.notifications.firstWhere(
          (n) => n.id == id,
          orElse: () => state.notifications.first,
        );
        
        state = state.copyWith(
          notifications: state.notifications.where((n) => n.id != id).toList(),
          unreadCount: notification.isUnread 
              ? state.unreadCount - 1 
              : state.unreadCount,
        );
      },
    );
  }

  /// Marcar una notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repo.markAsRead(notificationId);

      // Actualizar estado local
      final updated = state.notifications.map((n) {
        if (n.id == notificationId && n.isUnread) {
          return n.markAsRead();
        }
        return n;
      }).toList();

      final unreadCount = updated.where((n) => n.isUnread).length;

      state = state.copyWith(
        notifications: updated,
        unreadCount: unreadCount,
      );
    } catch (e) {
      // Silenciar error, no es crítico
    }
  }

  /// Marcar todas como leídas
  Future<void> markAllAsRead() async {
    try {
      await _repo.markAllAsRead();

      // Actualizar estado local
      final updated = state.notifications.map((n) {
        return n.isUnread ? n.markAsRead() : n;
      }).toList();

      state = state.copyWith(
        notifications: updated,
        unreadCount: 0,
      );
    } catch (e) {
      // Silenciar error
    }
  }

  /// Refrescar notificaciones
  Future<void> refresh() async {
    await init();
  }

  /// Limpiar suscripción
  Future<void> dispose() async {
    if (_channel != null) {
      await _repo.unsubscribe(_channel!);
      _channel = null;
    }
  }
}

/// Provider principal de notificaciones
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repo);
});

/// Provider solo para el conteo de no leídas (para el badge)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// Provider para saber si hay notificaciones no leídas
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadNotificationCountProvider) > 0;
});
