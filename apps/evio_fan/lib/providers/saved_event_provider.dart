import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

// ============================================
// REPOSITORY PROVIDER
// ============================================

final savedEventRepositoryProvider = Provider<SavedEventRepository>((ref) {
  return SavedEventRepository();
});

// ============================================
// SAVED EVENTS PROVIDER
// ============================================

/// Provider que obtiene los eventos guardados del usuario
final savedEventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.watch(savedEventRepositoryProvider);
  return repo.getMySavedEvents();
});

/// Provider que obtiene los IDs de eventos guardados (para checks rápidos)
final savedEventIdsProvider = FutureProvider<Set<String>>((ref) async {
  final repo = ref.watch(savedEventRepositoryProvider);
  return repo.getMySavedEventIds();
});

// ============================================
// SAVED EVENT ACTIONS
// ============================================

final savedEventActionsProvider = Provider<SavedEventActions>((ref) {
  return SavedEventActions(ref);
});

class SavedEventActions {
  final Ref ref;

  SavedEventActions(this.ref);

  /// Guardar o quitar evento de guardados
  Future<void> toggleSaveEvent(String eventId) async {
    final repo = ref.read(savedEventRepositoryProvider);
    final savedIds = await ref.read(savedEventIdsProvider.future);

    if (savedIds.contains(eventId)) {
      // Ya está guardado, quitar
      await repo.unsaveEvent(eventId);
    } else {
      // No está guardado, agregar
      await repo.saveEvent(eventId);
    }

    // Invalidar providers para refrescar
    ref.invalidate(savedEventsProvider);
    ref.invalidate(savedEventIdsProvider);
  }

  /// Guardar evento
  Future<void> saveEvent(String eventId) async {
    final repo = ref.read(savedEventRepositoryProvider);
    await repo.saveEvent(eventId);
    
    ref.invalidate(savedEventsProvider);
    ref.invalidate(savedEventIdsProvider);
  }

  /// Quitar evento guardado
  Future<void> unsaveEvent(String eventId) async {
    final repo = ref.read(savedEventRepositoryProvider);
    await repo.unsaveEvent(eventId);
    
    ref.invalidate(savedEventsProvider);
    ref.invalidate(savedEventIdsProvider);
  }

  /// Verificar si un evento está guardado
  Future<bool> isEventSaved(String eventId) async {
    final repo = ref.read(savedEventRepositoryProvider);
    return repo.isEventSaved(eventId);
  }
}
