class Producer {
  final String id;
  final String name;
  final String? logoUrl;
  final String? email;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Producer({
    required this.id,
    required this.name,
    this.logoUrl,
    this.email,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  factory Producer.fromJson(Map<String, dynamic> json) {
    return Producer(
      id: json['id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      email: json['email'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'email': email,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Producer copyWith({
    String? id,
    String? name,
    String? logoUrl,
    String? email,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Producer(
      id: id ?? this.id,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      email: email ?? this.email,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
