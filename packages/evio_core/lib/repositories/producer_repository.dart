import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/producer.dart';

class ProducerRepository {
  final SupabaseClient _client;

  ProducerRepository([SupabaseClient? client])
    : _client = client ?? Supabase.instance.client;

  /// Crear nueva productora
  Future<Producer> createProducer({
    required String name,
    required String userId,
    String? logoUrl,
    String? email,
    String? description,
  }) async {
    final response = await _client
        .from('producers')
        .insert({
          'name': name,
          'user_id': userId,
          'logo_url': logoUrl,
          'email': email,
          'description': description,
        })
        .select()
        .single();

    return Producer.fromJson(response);
  }

  /// Obtener productora por ID
  Future<Producer?> getProducerById(String id) async {
    final response = await _client
        .from('producers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Producer.fromJson(response);
  }

  /// Actualizar productora (solo admin)
  Future<Producer> updateProducer(Producer producer) async {
    final response = await _client
        .from('producers')
        .update(producer.toJson())
        .eq('id', producer.id)
        .select()
        .single();

    return Producer.fromJson(response);
  }

  /// Obtener todas las productoras
  Future<List<Producer>> getAllProducers() async {
    final response = await _client
        .from('producers')
        .select()
        .order('name');

    return (response as List)
        .map((json) => Producer.fromJson(json))
        .toList();
  }
}
