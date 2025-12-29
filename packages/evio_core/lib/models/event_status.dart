// packages/evio_core/lib/models/event_status.dart

enum EventStatus {
  draft,
  upcoming,
  cancelled;

  String get displayName {
    switch (this) {
      case EventStatus.draft:
        return 'Borrador';
      case EventStatus.upcoming:
        return 'Próximo';
      case EventStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get name {
    switch (this) {
      case EventStatus.draft:
        return 'draft';
      case EventStatus.upcoming:
        return 'upcoming';
      case EventStatus.cancelled:
        return 'cancelled';
    }
  }
}
