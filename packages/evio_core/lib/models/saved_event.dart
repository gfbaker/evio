class SavedEvent {
  final String id;
  final String userId;
  final String eventId;
  final DateTime createdAt;

  const SavedEvent({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.createdAt,
  });

  factory SavedEvent.fromJson(Map<String, dynamic> json) {
    return SavedEvent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
