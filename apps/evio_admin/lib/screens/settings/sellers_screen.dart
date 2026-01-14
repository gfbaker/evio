import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/settings_provider.dart';
import '../../providers/seller_provider.dart';

class SellersScreen extends ConsumerStatefulWidget {
  const SellersScreen({super.key});

  @override
  ConsumerState<SellersScreen> createState() => _SellersScreenState();
}

class _SellersScreenState extends ConsumerState<SellersScreen> {
  bool _isDisposed = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSellerDialog() {
    final emailController = TextEditingController();

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
                      Icons.storefront,
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
                          'Agregar Vendedor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: EvioLightColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Busca un usuario registrado por su email',
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
                    onPressed: () {
                      emailController.dispose();
                      Navigator.pop(context);
                    },
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: EvioSpacing.lg),
              Text(
                'Email del usuario',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EvioLightColors.textPrimary,
                ),
              ),
              SizedBox(height: EvioSpacing.xs),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'usuario@email.com',
                  hintStyle: TextStyle(
                    color: EvioLightColors.mutedForeground,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: EvioLightColors.mutedForeground,
                  ),
                  filled: true,
                  fillColor: EvioLightColors.surface,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: EvioSpacing.md,
                    vertical: EvioSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.input),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: EvioSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      emailController.dispose();
                      Navigator.pop(context);
                    },
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  FilledButton.icon(
                    onPressed: () async {
                      final email = emailController.text.trim();

                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('El email es requerido'),
                            backgroundColor: EvioLightColors.destructive,
                          ),
                        );
                        return;
                      }

                      try {
                        final userRepo = ref.read(userRepositoryProvider);
                        final users = await userRepo.searchUsers(email);

                        if (users.isEmpty) {
                          if (_isDisposed || !mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Usuario no encontrado'),
                              backgroundColor: EvioLightColors.destructive,
                            ),
                          );
                          return;
                        }

                        final user = users.first;
                        await ref.read(sellerActionsProvider).addSeller(user.id);

                        emailController.dispose();

                        if (_isDisposed || !mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Vendedor agregado: ${user.fullName}'),
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
                    label: Text('Agregar Vendedor'),
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

  Future<void> _deleteSeller(AuthorizedSeller seller, User? sellerUser) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvioRadius.card),
        ),
        title: Text('Eliminar Vendedor'),
        content: Text(
          '¿Estás seguro de eliminar a ${sellerUser?.fullName ?? seller.userId}?',
        ),
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
      await ref.read(sellerActionsProvider).deleteSeller(seller.id);

      if (_isDisposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vendedor eliminado'),
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
    final sellersAsync = ref.watch(producerSellersProvider);

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
                  _buildStatsCards(sellersAsync),
                  SizedBox(height: EvioSpacing.lg),
                  _buildSearchBar(),
                  SizedBox(height: EvioSpacing.lg),
                  sellersAsync.when(
                    data: (sellers) {
                      if (sellers.isEmpty) {
                        return _buildEmptyState();
                      }

                      final filteredSellers = sellers.where((seller) {
                        if (_searchQuery.isEmpty) return true;
                        return true;
                      }).toList();

                      return Column(
                        children: filteredSellers
                            .map((seller) => _buildSellerCard(seller))
                            .toList(),
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
            onPressed: _showAddSellerDialog,
            icon: Icon(Icons.person_add, size: 18),
            label: Text('Agregar Vendedor'),
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

  Widget _buildStatsCards(AsyncValue<List<AuthorizedSeller>> sellersAsync) {
    final sellers = sellersAsync.value ?? [];

    final totalSellers = sellers.length;
    final activeSellers = sellers.where((s) => s.isActive).length;
    final inactiveSellers = sellers.where((s) => !s.isActive).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        return Wrap(
          spacing: EvioSpacing.md,
          runSpacing: EvioSpacing.md,
          children: [
            _StatCard(
              title: 'Total Vendedores',
              value: totalSellers.toString(),
              icon: Icons.storefront,
              color: EvioLightColors.accent,
              width: isDesktop ? (constraints.maxWidth - 32) / 3 : double.infinity,
            ),
            _StatCard(
              title: 'Activos',
              value: activeSellers.toString(),
              icon: Icons.check_circle,
              color: EvioLightColors.success,
              width: isDesktop ? (constraints.maxWidth - 32) / 3 : double.infinity,
            ),
            _StatCard(
              title: 'Inactivos',
              value: inactiveSellers.toString(),
              icon: Icons.cancel,
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
        hintText: 'Buscar vendedores...',
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

  Widget _buildSellerCard(AuthorizedSeller seller) {
    final sellerUserAsync = ref.watch(sellerUserProvider(seller.userId));

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
              color: seller.isActive
                  ? EvioLightColors.accent.withValues(alpha: 0.15)
                  : Colors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront,
              color: seller.isActive ? EvioLightColors.accent : Colors.orange,
            ),
          ),
          SizedBox(width: EvioSpacing.md),
          Expanded(
            child: sellerUserAsync.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user?.fullName ?? 'Cargando...',
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
                          color: seller.isActive
                              ? EvioLightColors.success.withValues(alpha: 0.15)
                              : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          seller.isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: seller.isActive ? EvioLightColors.success : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              loading: () => Text(
                'Cargando...',
                style: TextStyle(color: EvioLightColors.mutedForeground),
              ),
              error: (_, __) => Text('ID: ${seller.userId}'),
            ),
          ),
          Switch(
            value: seller.isActive,
            onChanged: (value) async {
              try {
                await ref
                    .read(sellerActionsProvider)
                    .toggleSellerStatus(seller.id, seller.isActive);
              } catch (e) {
                if (_isDisposed || !mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            activeColor: EvioLightColors.success,
          ),
          SizedBox(width: EvioSpacing.xs),
          IconButton(
            icon: Icon(Icons.delete_outline, color: EvioLightColors.destructive),
            onPressed: () {
              final user = sellerUserAsync.value;
              _deleteSeller(seller, user);
            },
            tooltip: 'Eliminar',
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
              'Sin vendedores autorizados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.textPrimary,
              ),
            ),
            SizedBox(height: EvioSpacing.xs),
            Text(
              'Agrega vendedores para que puedan vender tickets\nde tus eventos y ganar comisiones',
              style: TextStyle(
                fontSize: 14,
                color: EvioLightColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EvioSpacing.lg),
            FilledButton.icon(
              onPressed: _showAddSellerDialog,
              icon: Icon(Icons.person_add, size: 18),
              label: Text('Agregar Primer Vendedor'),
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
