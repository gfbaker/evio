import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

/// Repository provider
final savedEventRepositoryProvider = Provider<SavedEventRepository>((ref) {
  return SavedEventRepository();
});

/// Provider de eventos guardados del usuario
final savedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.watch(savedEventRepositoryProvider);
  return repo.getMySavedEvents();
});

/// Provider de IDs de eventos guardados (para checks rápidos)
final savedEventIdsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(savedEventRepositoryProvider);
  return repo.getMySavedEventIds();
});

/// Provider para verificar si un evento específico está guardado
final isEventSavedProvider = FutureProvider.family<bool, String>((ref, eventId) async {
  final savedIds = await ref.watch(savedEventIdsProvider.future);
  return savedIds.contains(eventId);
});

/// Notifier para manejar guardar/desguardar eventos
class SavedEventsNotifier extends StateNotifier<AsyncValue<Set<String>>> {
  final Ref ref;

  SavedEventsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadSavedEvents();
  }

  Future<void> _loadSavedEvents() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(savedEventRepositoryProvider);
      final savedIds = await repo.getMySavedEventIds();
      state = AsyncValue.data(savedIds);
    } catch (e, st) {
      debugPrint('❌ [SavedEvents] Error loading: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// Guardar evento con optimistic update
  Future<void> saveEvent(String eventId) async {
    debugPrint('📌 [SavedEvents] Guardando evento: $eventId');
    
    // ⚡ Actualizar estado local PRIMERO (optimistic)
    final previousState = state.valueOrNull ?? {};
    state = AsyncValue.data({...previousState, eventId});

    try {
      final repo = ref.read(savedEventRepositoryProvider);
      await repo.saveEvent(eventId);
      
      debugPrint('✅ [SavedEvents] Evento guardado: $eventId');
      
      // Invalidar providers relacionados (en background, sin await)
      Future.microtask(() {
        ref.invalidate(savedEventsProvider);
        ref.invalidate(savedEventIdsProvider);
      });
    } catch (e, st) {
      debugPrint('❌ [SavedEvents] Error guardando: $e');
      // Revertir en caso de error
      state = AsyncValue.data(previousState);
      // No relanzar el error para evitar crashes en UI
    }
  }

  /// Desguardar evento con optimistic update
  Future<void> unsaveEvent(String eventId) async {
    debugPrint('📌 [SavedEvents] Quitando evento: $eventId');
    
    // ⚡ Actualizar estado local PRIMERO (optimistic)
    final previousState = state.valueOrNull ?? {};
    final newSet = Set<String>.from(previousState);
    newSet.remove(eventId);
    state = AsyncValue.data(newSet);

    try {
      final repo = ref.read(savedEventRepositoryProvider);
      await repo.unsaveEvent(eventId);
      
      debugPrint('✅ [SavedEvents] Evento quitado: $eventId');
      
      // Invalidar providers relacionados (en background, sin await)
      Future.microtask(() {
        ref.invalidate(savedEventsProvider);
        ref.invalidate(savedEventIdsProvider);
      });
    } catch (e, st) {
      debugPrint('❌ [SavedEvents] Error quitando: $e');
      // Revertir en caso de error
      state = AsyncValue.data(previousState);
      // No relanzar el error para evitar crashes en UI
    }
  }

  /// Toggle save/unsave
  Future<void> toggleSave(String eventId) async {
    try {
      final currentState = state.valueOrNull ?? {};
      if (currentState.contains(eventId)) {
        await unsaveEvent(eventId);
      } else {
        await saveEvent(eventId);
      }
    } catch (e) {
      debugPrint('❌ [SavedEvents] Error en toggleSave: $e');
      // Silenciar error para evitar crash
    }
  }
}

final savedEventsNotifierProvider = 
    StateNotifierProvider<SavedEventsNotifier, AsyncValue<Set<String>>>((ref) {
  return SavedEventsNotifier(ref);
});
