import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient? _client;

  /// Inicializar Supabase (llamar en main.dart)
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Cliente de Supabase
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase no inicializado. Llamá a SupabaseService.initialize() primero.',
      );
    }
    return _client!;
  }

  /// Usuario autenticado actual (null si no hay sesión)
  static User? get currentUser => client.auth.currentUser;

  /// ¿Hay sesión activa?
  static bool get isAuthenticated => currentUser != null;

  /// Stream de cambios de auth
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
