import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/auth_provider.dart';
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
    bool dialogDisposed = false;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: EvioLightColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.storefront,
                      color: EvioLightColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agregar Vendedor',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
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
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      emailController.dispose();
                      dialogDisposed = true;
                      Navigator.pop(context);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Email del usuario',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: EvioLightColors.foreground,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'usuario@email.com',
                  hintStyle: const TextStyle(
                    color: EvioLightColors.mutedForeground,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: EvioLightColors.mutedForeground,
                  ),
                  filled: true,
                  fillColor: EvioLightColors.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: EvioLightColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: EvioLightColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFD1D5DB),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      emailController.dispose();
                      dialogDisposed = true;
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final email = emailController.text.trim();

                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El email es requerido'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        // Buscar usuario por email
                        final userRepo = ref.read(userRepositoryProvider);
                        final users = await userRepo.searchUsers(email);

                        if (users.isEmpty) {
                          if (_isDisposed || !mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Usuario no encontrado'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        final user = users.first;

                        // Agregar como vendedor
                        await ref
                            .read(sellerActionsProvider)
                            .addSeller(user.id);

                        emailController.dispose();
                        dialogDisposed = true;

                        if (_isDisposed || !mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Vendedor agregado: ${user.fullName}',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (_isDisposed || !mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text(
                      'Agregar Vendedor',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EvioLightColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      elevation: 0,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar Vendedor'),
        content: Text(
          '¿Estás seguro de eliminar a ${sellerUser?.fullName ?? seller.userId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || _isDisposed) return;

    try {
      await ref.read(sellerActionsProvider).deleteSeller(seller.id);

      if (_isDisposed || !mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendedor eliminado'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellersAsync = ref.watch(producerSellersProvider);

    return Column(
      children: [
        _buildActionHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCards(sellersAsync),
                const SizedBox(height: 24),
                _buildSearchBar(),
                const SizedBox(height: 24),
                sellersAsync.when(
                  data: (sellers) {
                    if (sellers.isEmpty) {
                      return _buildEmptyState();
                    }

                    final filteredSellers = sellers.where((seller) {
                      if (_searchQuery.isEmpty) return true;
                      // TODO: Filter by user name/email when available
                      return true;
                    }).toList();

                    return Column(
                      children: filteredSellers
                          .map((seller) => _buildSellerCard(seller))
                          .toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: EvioLightColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton.icon(
            onPressed: _showAddSellerDialog,
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Agregar Vendedor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvioLightColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildStatCard(
              title: 'Total Vendedores',
              value: totalSellers.toString(),
              icon: Icons.storefront,
              color: EvioLightColors.primary,
              width: isDesktop
                  ? (constraints.maxWidth - 32) / 3
                  : double.infinity,
            ),
            _buildStatCard(
              title: 'Activos',
              value: activeSellers.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
              width: isDesktop
                  ? (constraints.maxWidth - 32) / 3
                  : double.infinity,
            ),
            _buildStatCard(
              title: 'Inactivos',
              value: inactiveSellers.toString(),
              icon: Icons.cancel,
              color: Colors.orange,
              width: isDesktop
                  ? (constraints.maxWidth - 32) / 3
                  : double.infinity,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: EvioLightColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        hintStyle: const TextStyle(color: EvioLightColors.mutedForeground),
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: EvioLightColors.mutedForeground,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  if (_isDisposed) return;
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EvioLightColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: EvioLightColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSellerCard(AuthorizedSeller seller) {
    // Usar el provider.family para evitar memory leaks
    final sellerUserAsync = ref.watch(sellerUserProvider(seller.userId));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: seller.isActive
              ? EvioLightColors.border
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: seller.isActive
                  ? EvioLightColors.muted
                  : Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.storefront,
              color: seller.isActive
                  ? EvioLightColors.mutedForeground
                  : Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: sellerUserAsync.when(
              data: (user) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user?.fullName ?? 'Cargando...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: seller.isActive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          seller.isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: seller.isActive ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              loading: () => const Text('Cargando...'),
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
            activeColor: Colors.green,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
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
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: EvioLightColors.muted,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.storefront,
                size: 64,
                color: EvioLightColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sin vendedores autorizados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega vendedores para que puedan vender tickets\nde tus eventos y ganar comisiones',
              style: TextStyle(
                fontSize: 14,
                color: EvioLightColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddSellerDialog,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Agregar Primer Vendedor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EvioLightColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
