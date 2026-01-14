import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/follow_provider.dart';
import '../../providers/profile_provider.dart';

// Provider para búsqueda de usuarios
final searchUsersQueryProvider = StateProvider<String>((ref) => '');

final searchUsersProvider = FutureProvider.autoDispose<List<User>>((ref) async {
  final query = ref.watch(searchUsersQueryProvider);
  
  if (query.isEmpty) {
    return [];
  }
  
  final userRepo = ref.watch(userRepositoryProvider);
  
  try {
    // Buscar usuarios por nombre o email
    return await userRepo.searchUsers(query);
  } catch (e) {
    debugPrint('❌ Error buscando usuarios: $e');
    return [];
  }
});

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _searchController = TextEditingController();
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDisposed) {
      return Scaffold(
        backgroundColor: EvioFanColors.background,
        body: Center(
          child: CircularProgressIndicator(color: EvioFanColors.primary),
        ),
      );
    }
    
    final searchResults = ref.watch(searchUsersProvider);

    return Scaffold(
      backgroundColor: EvioFanColors.background,
      appBar: AppBar(
        backgroundColor: EvioFanColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: EvioFanColors.foreground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Buscar usuarios',
          style: EvioTypography.h3.copyWith(
            color: EvioFanColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(EvioSpacing.lg),
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
                          _searchController.clear();
                          ref.read(searchUsersQueryProvider.notifier).state = '';
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
                setState(() {}); // ✅ Actualizar UI para el clear button
                ref.read(searchUsersQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Results
          Expanded(
            child: searchResults.when(
              data: (users) {
                if (_searchController.text.isEmpty) {
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
                          'Buscá usuarios para seguir',
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
                ref.read(followActionsProvider).toggleFollow(user.id);
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
