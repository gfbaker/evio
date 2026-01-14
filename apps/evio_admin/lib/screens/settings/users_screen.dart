import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  bool _isDisposed = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    super.dispose();
  }

  void _showInviteDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final roleNotifier = ValueNotifier<UserRole>(UserRole.collaborator);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvioRadius.card),
        ),
        child: Container(
          width: 480,
          padding: EdgeInsets.all(EvioSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: EvioLightColors.accent,
                      borderRadius: BorderRadius.circular(EvioRadius.button),
                    ),
                    child: Icon(
                      Icons.person_add,
                      color: EvioLightColors.accentForeground,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invitar Usuario',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: EvioLightColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'El usuario aparecerá como pendiente hasta que cree su cuenta',
                          style: TextStyle(
                            fontSize: 13,
                            color: EvioLightColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: EvioSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _DialogField(
                      label: 'Nombre',
                      controller: firstNameController,
                      hint: 'Juan',
                    ),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  Expanded(
                    child: _DialogField(
                      label: 'Apellido',
                      controller: lastNameController,
                      hint: 'Pérez',
                    ),
                  ),
                ],
              ),
              SizedBox(height: EvioSpacing.md),
              _DialogField(
                label: 'Email',
                controller: emailController,
                hint: 'usuario@email.com',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: EvioSpacing.md),
              Text(
                'Rol',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EvioLightColors.textPrimary,
                ),
              ),
              SizedBox(height: EvioSpacing.xs),
              ValueListenableBuilder<UserRole>(
                valueListenable: roleNotifier,
                builder: (context, role, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: EvioLightColors.surface,
                      borderRadius: BorderRadius.circular(EvioRadius.input),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<UserRole>(
                        value: role,
                        isExpanded: true,
                        padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: EvioLightColors.mutedForeground,
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: EvioLightColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: EvioLightColors.card,
                        borderRadius: BorderRadius.circular(EvioRadius.card),
                        items: [
                          DropdownMenuItem(
                            value: UserRole.admin,
                            child: Text(UserRole.admin.displayName),
                          ),
                          DropdownMenuItem(
                            value: UserRole.collaborator,
                            child: Text(UserRole.collaborator.displayName),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) roleNotifier.value = value;
                        },
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: EvioSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  FilledButton.icon(
                    onPressed: () async {
                      final firstName = firstNameController.text.trim();
                      final lastName = lastNameController.text.trim();
                      final email = emailController.text.trim();

                      if (firstName.isEmpty || lastName.isEmpty || email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Todos los campos son requeridos'),
                            backgroundColor: EvioLightColors.destructive,
                          ),
                        );
                        return;
                      }

                      try {
                        final currentUser = await ref.read(currentUserProvider.future);
                        if (currentUser?.producerId == null || _isDisposed) return;

                        final repo = ref.read(userRepositoryProvider);
                        final invitation = UserInvitation(
                          id: '',
                          producerId: currentUser!.producerId!,
                          firstName: firstName,
                          lastName: lastName,
                          email: email,
                          role: roleNotifier.value,
                          status: UserInvitationStatus.pending,
                          createdAt: DateTime.now(),
                        );
                        await repo.createInvitation(invitation);

                        if (_isDisposed || !mounted) return;
                        Navigator.pop(context);
                        ref.invalidate(producerInvitationsProvider);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invitación creada para $firstName $lastName'),
                            backgroundColor: EvioLightColors.success,
                          ),
                        );
                      } catch (e) {
                        if (_isDisposed || !mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: EvioLightColors.destructive,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.person_add, size: 16),
                    label: Text('Agregar Usuario'),
                    style: FilledButton.styleFrom(
                      backgroundColor: EvioLightColors.accent,
                      foregroundColor: EvioLightColors.accentForeground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvioRadius.card),
        ),
        title: Text('Eliminar Usuario'),
        content: Text('¿Estás seguro de eliminar a ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: EvioLightColors.destructive,
              foregroundColor: EvioLightColors.destructiveForeground,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || _isDisposed) return;

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.deleteUser(user.id);

      if (_isDisposed || !mounted) return;
      ref.invalidate(producerUsersProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuario eliminado'),
          backgroundColor: EvioLightColors.success,
        ),
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: EvioLightColors.destructive),
      );
    }
  }

  Future<void> _deleteInvitation(UserInvitation invitation) async {
    if (_isDisposed) return;

    try {
      final repo = ref.read(userRepositoryProvider);
      await repo.deleteInvitation(invitation.id);

      if (_isDisposed || !mounted) return;
      ref.invalidate(producerInvitationsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitación eliminada'),
          backgroundColor: EvioLightColors.success,
        ),
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: EvioLightColors.destructive),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(producerUsersProvider);
    final invitationsAsync = ref.watch(producerInvitationsProvider);

    return Container(
      color: EvioLightColors.surface,
      child: Column(
        children: [
          _buildActionHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(EvioSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCards(usersAsync, invitationsAsync),
                  SizedBox(height: EvioSpacing.lg),
                  _buildSearchBar(),
                  SizedBox(height: EvioSpacing.lg),
                  usersAsync.when(
                    data: (users) {
                      final filteredUsers = users.where((user) {
                        if (_searchQuery.isEmpty) return true;
                        final query = _searchQuery.toLowerCase();
                        return user.fullName.toLowerCase().contains(query) ||
                            user.email.toLowerCase().contains(query);
                      }).toList();

                      final pendingInvitations = invitationsAsync.value ?? [];

                      if (filteredUsers.isEmpty && pendingInvitations.isEmpty) {
                        return _buildEmptyState();
                      }

                      return Column(
                        children: [
                          ...filteredUsers.map((user) => _buildUserCard(user)),
                          ...pendingInvitations.map((inv) => _buildInvitationCard(inv)),
                        ],
                      );
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(color: EvioLightColors.accent),
                    ),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg, vertical: EvioSpacing.md),
      color: EvioLightColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FilledButton.icon(
            onPressed: _showInviteDialog,
            icon: Icon(Icons.person_add, size: 18),
            label: Text('Invitar Usuario'),
            style: FilledButton.styleFrom(
              backgroundColor: EvioLightColors.accent,
              foregroundColor: EvioLightColors.accentForeground,
              padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg, vertical: EvioSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    AsyncValue<List<User>> usersAsync,
    AsyncValue<List<UserInvitation>> invitationsAsync,
  ) {
    final users = usersAsync.value ?? [];
    final invitations = invitationsAsync.value ?? [];

    final totalUsers = users.length;
    final activeUsers = users.where((u) => u.isActive).length;
    final pendingInvitations = invitations
        .where((i) => i.status == UserInvitationStatus.pending)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        return Wrap(
          spacing: EvioSpacing.md,
          runSpacing: EvioSpacing.md,
          children: [
            _StatCard(
              title: 'Total Usuarios',
              value: totalUsers.toString(),
              icon: Icons.people,
              color: EvioLightColors.accent,
              width: isDesktop ? (constraints.maxWidth - 32) / 3 : double.infinity,
            ),
            _StatCard(
              title: 'Activos',
              value: activeUsers.toString(),
              icon: Icons.check_circle,
              color: EvioLightColors.success,
              width: isDesktop ? (constraints.maxWidth - 32) / 3 : double.infinity,
            ),
            _StatCard(
              title: 'Pendientes',
              value: pendingInvitations.toString(),
              icon: Icons.pending,
              color: Colors.orange,
              width: isDesktop ? (constraints.maxWidth - 32) / 3 : double.infinity,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        if (_isDisposed) return;
        setState(() => _searchQuery = value);
      },
      decoration: InputDecoration(
        hintText: 'Buscar usuarios...',
        hintStyle: TextStyle(color: EvioLightColors.mutedForeground),
        prefixIcon: Icon(Icons.search, size: 20, color: EvioLightColors.mutedForeground),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, size: 20),
                onPressed: () {
                  if (_isDisposed) return;
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: EvioLightColors.card,
        contentPadding: EdgeInsets.symmetric(horizontal: EvioSpacing.md, vertical: EvioSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EvioRadius.input),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final currentUser = ref.watch(currentUserProvider).value;
    final isCurrentUser = currentUser?.id == user.id;

    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.sm),
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: EvioLightColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: EvioLightColors.accent),
          ),
          SizedBox(width: EvioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: EvioLightColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: EvioSpacing.xs),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isAdmin
                            ? EvioLightColors.accent
                            : EvioLightColors.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.role.displayName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: user.isAdmin
                              ? EvioLightColors.accentForeground
                              : EvioLightColors.mutedForeground,
                        ),
                      ),
                    ),
                    if (isCurrentUser) ...[
                      SizedBox(width: EvioSpacing.xs),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Tú',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          if (!isCurrentUser)
            IconButton(
              icon: Icon(Icons.delete_outline, color: EvioLightColors.destructive),
              onPressed: () => _deleteUser(user),
              tooltip: 'Eliminar',
            ),
        ],
      ),
    );
  }

  Widget _buildInvitationCard(UserInvitation invitation) {
    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.sm),
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.mail_outline, color: Colors.orange),
          ),
          SizedBox(width: EvioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      invitation.email,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: EvioLightColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: EvioSpacing.xs),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Pendiente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Rol: ${invitation.role.displayName}',
                  style: TextStyle(
                    fontSize: 13,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: EvioLightColors.destructive),
            onPressed: () => _deleteInvitation(invitation),
            tooltip: 'Eliminar invitación',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(EvioSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sin colaboradores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.textPrimary,
              ),
            ),
            SizedBox(height: EvioSpacing.xs),
            Text(
              'Invita colaboradores para gestionar\ntus eventos juntos',
              style: TextStyle(
                fontSize: 14,
                color: EvioLightColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EvioSpacing.lg),
            FilledButton.icon(
              onPressed: _showInviteDialog,
              icon: Icon(Icons.person_add, size: 18),
              label: Text('Invitar Primer Usuario'),
              style: FilledButton.styleFrom(
                backgroundColor: EvioLightColors.accent,
                foregroundColor: EvioLightColors.accentForeground,
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.xl, vertical: EvioSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS AUXILIARES
// -----------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.lg),
        decoration: BoxDecoration(
          color: EvioLightColors.card,
          borderRadius: BorderRadius.circular(EvioRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            SizedBox(width: EvioSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.label,
    required this.controller,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: EvioLightColors.textPrimary,
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: EvioLightColors.mutedForeground, fontSize: 14),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 18, color: EvioLightColors.mutedForeground)
                : null,
            filled: true,
            fillColor: EvioLightColors.surface,
            contentPadding: EdgeInsets.symmetric(horizontal: EvioSpacing.md, vertical: EvioSpacing.sm),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EvioRadius.input),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
