import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'auth_provider.dart';

// ============================================
// USER REPOSITORY PROVIDER
// ============================================

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

// ============================================
// CURRENT USER PROFILE
// ============================================

/// Provider que observa cambios en el usuario actual
/// Se invalida automáticamente cuando cambia la sesión
final currentUserProfileProvider = StreamProvider<User?>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  
  // Stream que escucha cambios en auth
  return supabaseClient.auth.onAuthStateChange.asyncMap((authState) async {
    if (authState.session?.user == null) return null;
    
    final userRepo = ref.read(userRepositoryProvider);
    return await userRepo.getCurrentUser();
  });
});

// ============================================
// PROFILE ACTIONS
// ============================================

/// Provider para acciones de perfil (update, upload avatar)
final profileActionsProvider = Provider<ProfileActions>((ref) {
  return ProfileActions(ref);
});

class ProfileActions {
  final Ref ref;
  
  ProfileActions(this.ref);
  
  /// Actualizar datos del perfil
  Future<User> updateProfile({
    required String userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? dni,
    DateTime? birthDate,
    String? gender,
  }) async {
    debugPrint('🔄 [ProfileActions] Actualizando perfil...');
    
    final userRepo = ref.read(userRepositoryProvider);
    
    // Obtener usuario actual de la DB
    final currentUser = await userRepo.getCurrentUser();
    
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    // Crear usuario actualizado
    final updatedUser = currentUser.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      dni: dni,
      birthDate: birthDate,
      gender: gender,
    );
    
    // Actualizar en DB
    final result = await userRepo.updateUser(updatedUser);
    
    debugPrint('✅ [ProfileActions] Perfil actualizado');
    
    // Invalidar provider de auth para refrescar
    ref.invalidate(currentUserProvider);
    
    return result;
  }
  
  /// Subir y actualizar avatar
  Future<String> uploadAvatar({
    required String userId,
    required File file,
  }) async {
    debugPrint('🔄 [ProfileActions] Subiendo avatar...');
    
    final userRepo = ref.read(userRepositoryProvider);
    
    // Leer bytes del archivo
    final bytes = await file.readAsBytes();
    
    // Subir a Supabase Storage
    final avatarUrl = await userRepo.uploadAvatar(
      userId: userId,
      filePath: file.path,
      fileBytes: bytes,
    );
    
    // Actualizar usuario con nueva URL
    await userRepo.updateAvatar(userId, avatarUrl);
    
    debugPrint('✅ [ProfileActions] Avatar actualizado: $avatarUrl');
    
    // Invalidar provider de auth para refrescar
    ref.invalidate(currentUserProvider);
    
    return avatarUrl;
  }
}
