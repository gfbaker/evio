import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/follow_provider.dart';
import '../../providers/profile_provider.dart';

// Provider para búsqueda de usuarios en BottomSheet
final searchUsersBottomSheetQueryProvider = StateProvider<String>((ref) => '');

final searchUsersBottomSheetProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final query = ref.watch(searchUsersBottomSheetQueryProvider);
  
  if (query.isEmpty || query.length < 2) {
    return [];
  }
  
  final userRepo = ref.watch(userRepositoryProvider);
  
  try {
    // ✅ Timeout de 10 segundos
    return await userRepo.searchUsers(query).timeout(
      Duration(seconds: 10),
      onTimeout: () {
        debugPrint('⏱️ Timeout en búsqueda de usuarios');
        return [];
      },
    );
  } catch (e) {
    debugPrint('❌ Error buscando usuarios: $e');
    return [];
  }
});

class SearchUsersBottomSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true, // ✅ Usar SafeArea
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const _SearchUsersContent(),
    );
  }
}

class _SearchUsersContent extends ConsumerStatefulWidget {
  const _SearchUsersContent();

  @override
  ConsumerState<_SearchUsersContent> createState() => _SearchUsersContentState();
}

class _SearchUsersContentState extends ConsumerState<_SearchUsersContent> {
  final _searchController = TextEditingController();
  bool _isDisposed = false;
  Timer? _debounceTimer; // ✅ Debounce para optimizar búsquedas

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    _searchController.dispose();
    // Limpiar query al cerrar
    Future.microtask(() {
      try {
        if (mounted) {
          ref.read(searchUsersBottomSheetQueryProvider.notifier).state = '';
        }
      } catch (e) {
        debugPrint('⚠️ Error limpiando query: $e');
      }
    });
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_isDisposed) return;
    
    // ✅ Cancelar timer anterior
    _debounceTimer?.cancel();
    
    // ✅ Debounce de 500ms para no hacer búsquedas en cada tecla
    _debounceTimer = Timer(Duration(milliseconds: 500), () {
      if (_isDisposed || !mounted) return;
      ref.read(searchUsersBottomSheetQueryProvider.notifier).state = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return SizedBox.shrink();
    }

    final searchResults = ref.watch(searchUsersBottomSheetProvider);

    return Container(
      height: MediaQuery.of(context).size.height, // ✅ 100% altura
      decoration: BoxDecoration(
        color: EvioFanColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EvioRadius.card + 4),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: EvioSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: EvioFanColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(EvioSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Buscar usuarios',
                    style: EvioTypography.h3.copyWith(
                      color: EvioFanColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: EvioFanColors.foreground),
                  onPressed: () {
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: EvioTypography.bodyMedium.copyWith(
                color: EvioFanColors.foreground,
              ),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o email...',
                hintStyle: EvioTypography.bodyMedium.copyWith(
                  color: EvioFanColors.mutedForeground,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: EvioFanColors.mutedForeground,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: EvioFanColors.mutedForeground,
                        ),
                        onPressed: () {
                          if (_isDisposed || !mounted) return;
                          _searchController.clear();
                          setState(() {});
                          _debounceTimer?.cancel();
                          ref.read(searchUsersBottomSheetQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                filled: true,
                fillColor: EvioFanColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioFanColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioFanColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioFanColors.primary, width: 2),
                ),
              ),
              onChanged: (value) {
                if (_isDisposed || !mounted) return;
                setState(() {}); // ✅ Actualizar UI para clear button
                _onSearchChanged(value); // ✅ Debounced search
              },
            ),
          ),

          SizedBox(height: EvioSpacing.lg),

          // Results
          Expanded(
            child: searchResults.when(
              data: (users) {
                if (_searchController.text.isEmpty || _searchController.text.length < 2) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 64,
                          color: EvioFanColors.mutedForeground.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: EvioSpacing.lg),
                        Text(
                          'Ingresá al menos 2 caracteres',
                          style: EvioTypography.bodyLarge.copyWith(
                            color: EvioFanColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: EvioFanColors.mutedForeground,
                        ),
                        SizedBox(height: EvioSpacing.lg),
                        Text(
                          'No se encontraron usuarios',
                          style: EvioTypography.h4.copyWith(
                            color: EvioFanColors.foreground,
                          ),
                        ),
                        SizedBox(height: EvioSpacing.sm),
                        Text(
                          'Intentá con otro nombre o email',
                          style: EvioTypography.bodyMedium.copyWith(
                            color: EvioFanColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserSearchCard(user: user);
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: EvioFanColors.primary),
              ),
              error: (e, st) => Center(
                child: Padding(
                  padding: EdgeInsets.all(EvioSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: EvioFanColors.error,
                      ),
                      SizedBox(height: EvioSpacing.lg),
                      Text(
                        'Error al buscar usuarios',
                        style: EvioTypography.h4.copyWith(
                          color: EvioFanColors.foreground,
                        ),
                      ),
                      SizedBox(height: EvioSpacing.sm),
                      Text(
                        e.toString(),
                        style: EvioTypography.bodySmall.copyWith(
                          color: EvioFanColors.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card de usuario en resultados de búsqueda
class _UserSearchCard extends ConsumerWidget {
  final User user;

  const _UserSearchCard({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followingIdsAsync = ref.watch(myFollowingIdsProvider);
    final isFollowing = followingIdsAsync.maybeWhen(
      data: (ids) => ids.contains(user.id),
      orElse: () => false,
    );

    return Container(
      padding: EdgeInsets.all(EvioSpacing.md),
      margin: EdgeInsets.only(bottom: EvioSpacing.sm),
      decoration: BoxDecoration(
        color: EvioFanColors.surface,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: EvioFanColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: EvioFanColors.primary.withValues(alpha: 0.2),
            backgroundImage:
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : null,
            child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                ? Text(
                    user.fullName[0].toUpperCase(),
                    style: TextStyle(
                      color: EvioFanColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  )
                : null,
          ),

          SizedBox(width: EvioSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: EvioTypography.labelLarge.copyWith(
                    color: EvioFanColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  user.email,
                  style: EvioTypography.bodySmall.copyWith(
                    color: EvioFanColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Botón Follow/Unfollow
          SizedBox(
            height: 36,
            child: OutlinedButton(
              onPressed: () {
                try {
                  ref.read(followActionsProvider).toggleFollow(user.id);
                } catch (e) {
                  debugPrint('❌ Error toggle follow: $e');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: isFollowing
                    ? EvioFanColors.mutedForeground
                    : EvioFanColors.primary,
                side: BorderSide(
                  color: isFollowing
                      ? EvioFanColors.border
                      : EvioFanColors.primary,
                ),
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
              ),
              child: Text(
                isFollowing ? 'Siguiendo' : 'Seguir',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
