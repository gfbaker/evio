import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/order_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/event_provider.dart';

/// Checkout screen que soporta:
/// - Flujo normal (carrito)
/// - Purchase link (entrada reservada con precio especial)
class CheckoutScreen extends ConsumerStatefulWidget {
  final String? purchaseLinkId;

  const CheckoutScreen({
    super.key,
    this.purchaseLinkId,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isDisposed = false;
  String? selectedPaymentMethod;

  // Purchase link state
  bool _loadingPurchaseLink = false;
  bool _processingPayment = false; // ✅ P2: Doble click protection
  PurchaseLink? _purchaseLink;
  String? _purchaseLinkError;

  final _purchaseLinkRepo = PurchaseLinkRepository();

  @override
  void initState() {
    super.initState();
    if (widget.purchaseLinkId != null) {
      _loadPurchaseLink();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadPurchaseLink() async {
    if (_isDisposed) return;

    setState(() {
      _loadingPurchaseLink = true;
      _purchaseLinkError = null;
    });

    try {
      final link = await _purchaseLinkRepo
          .getById(widget.purchaseLinkId!)
          .timeout(const Duration(seconds: 10));

      if (_isDisposed || !mounted) return;

      if (link == null) {
        setState(() {
          _loadingPurchaseLink = false;
          _purchaseLinkError = 'El link no existe o expiró';
        });
        return;
      }

      if (link.status != PurchaseLinkStatus.pending) {
        setState(() {
          _loadingPurchaseLink = false;
          _purchaseLinkError = link.status == PurchaseLinkStatus.used
              ? 'Esta entrada ya fue utilizada'
              : 'Este link ya no está disponible';
        });
        return;
      }

      // ✅ P4: Validar expiración por fecha
      if (link.isExpired) {
        setState(() {
          _loadingPurchaseLink = false;
          _purchaseLinkError = 'Este link ha expirado';
        });
        return;
      }

      setState(() {
        _loadingPurchaseLink = false;
        _purchaseLink = link;
      });
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        _loadingPurchaseLink = false;
        _purchaseLinkError = 'Error al cargar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dismiss keyboard al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });

    // ================================
    // MODO PURCHASE LINK
    // ================================
    if (widget.purchaseLinkId != null) {
      return _buildPurchaseLinkCheckout();
    }

    // ================================
    // MODO NORMAL (CARRITO)
    // ================================
    return _buildCartCheckout();
  }

  // ==========================================================================
  // PURCHASE LINK CHECKOUT
  // ==========================================================================

  Widget _buildPurchaseLinkCheckout() {
    // Loading
    if (_loadingPurchaseLink) {
      return Scaffold(
        body: Container(
          decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: EvioFanColors.primary),
                SizedBox(height: EvioSpacing.lg),
                Text(
                  'Cargando entrada reservada...',
                  style: EvioTypography.bodyMedium.copyWith(
                    color: EvioFanColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Error
    if (_purchaseLinkError != null) {
      return Scaffold(
        body: Container(
          decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: EvioFanColors.error,
                ),
                SizedBox(height: EvioSpacing.md),
                Text(
                  _purchaseLinkError!,
                  style: EvioTypography.h4.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: EvioSpacing.xl),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EvioFanColors.primary,
                    foregroundColor: EvioFanColors.primaryForeground,
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Link cargado
    final link = _purchaseLink!;
    final isFree = link.customPrice == 0;
    final total = (link.customPrice * link.quantity).toInt();

    return Scaffold(
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: Column(
          children: [
            // AppBar
            SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: EvioFanColors.foreground),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      isFree ? 'Invitación' : 'Entrada Reservada',
                      style: EvioTypography.h3.copyWith(
                        color: EvioFanColors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(EvioSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge especial
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: EvioSpacing.md,
                        vertical: EvioSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isFree
                            ? EvioFanColors.primary.withValues(alpha: 0.1)
                            : Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isFree ? Icons.card_giftcard : Icons.bookmark,
                            size: 16,
                            color: isFree ? EvioFanColors.primary : Colors.amber,
                          ),
                          SizedBox(width: EvioSpacing.xs),
                          Text(
                            isFree ? 'INVITACIÓN GRATIS' : 'PRECIO ESPECIAL',
                            style: EvioTypography.labelSmall.copyWith(
                              color: isFree ? EvioFanColors.primary : Colors.amber,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: EvioSpacing.lg),

                    // Evento
                    if (link.event != null) ...[
                      Text(
                        link.event!.title.toUpperCase(),
                        style: EvioTypography.labelSmall.copyWith(
                          color: EvioFanColors.mutedForeground,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: EvioSpacing.xs),
                      Text(
                        link.event!.title,
                        style: EvioTypography.h2.copyWith(
                          color: EvioFanColors.foreground,
                        ),
                      ),
                      SizedBox(height: EvioSpacing.lg),
                    ],

                    // Detalle de entrada
                    Container(
                      padding: EdgeInsets.all(EvioSpacing.md),
                      decoration: BoxDecoration(
                        color: EvioFanColors.surface,
                        borderRadius: BorderRadius.circular(EvioRadius.card),
                        border: Border.all(color: EvioFanColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nombre de la categoría (VIP, General, etc.)
                                if (link.tierCategoryName != null) ...[
                                  Text(
                                    link.tierCategoryName!.toUpperCase(),
                                    style: EvioTypography.labelSmall.copyWith(
                                      color: EvioFanColors.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  SizedBox(height: EvioSpacing.xxs),
                                ],
                                // Nombre del tier (Early Bird, Regular, etc.)
                                Text(
                                  link.tier?.name ?? 'Entrada',
                                  style: EvioTypography.bodyLarge.copyWith(
                                    color: EvioFanColors.foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Cantidad',
                                style: EvioTypography.labelSmall.copyWith(
                                  color: EvioFanColors.mutedForeground,
                                ),
                              ),
                              Text(
                                'x${link.quantity}',
                                style: EvioTypography.h4.copyWith(
                                  color: EvioFanColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: EvioSpacing.xl),

                    // Precio
                    if (!isFree) ...[
                      _buildPriceRow(
                        'Precio especial:',
                        total,
                        isBold: true,
                        highlight: true,
                      ),
                      SizedBox(height: EvioSpacing.sm),
                      if (link.tier != null)
                        Text(
                          'Precio normal: ${CurrencyFormatter.formatPrice(link.tier!.price * link.quantity)}',
                          style: EvioTypography.bodySmall.copyWith(
                            color: EvioFanColors.mutedForeground,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      SizedBox(height: EvioSpacing.xl),

                      // Métodos de pago
                      Text(
                        'OPCIONES DE PAGO',
                        style: EvioTypography.labelSmall.copyWith(
                          color: EvioFanColors.mutedForeground,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: EvioSpacing.md),
                      _buildPaymentMethod(
                        icon: Icons.credit_card,
                        title: 'Tarjeta de Crédito/Débito',
                        value: 'card',
                        logos: ['visa', 'mastercard', 'amex'],
                      ),
                      SizedBox(height: EvioSpacing.sm),
                      _buildPaymentMethod(
                        icon: Icons.account_balance_wallet,
                        title: 'Mercado Pago',
                        value: 'mercadopago',
                        color: const Color(0xFF009EE3),
                      ),
                    ] else ...[
                      // Gratis - mostrar mensaje
                      Container(
                        padding: EdgeInsets.all(EvioSpacing.lg),
                        decoration: BoxDecoration(
                          color: EvioFanColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(EvioRadius.card),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.celebration,
                              color: EvioFanColors.primary,
                              size: 32,
                            ),
                            SizedBox(width: EvioSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¡Es gratis!',
                                    style: EvioTypography.h4.copyWith(
                                      color: EvioFanColors.primary,
                                    ),
                                  ),
                                  Text(
                                    'Solo hacé click en "Obtener entrada" para recibir tu ticket.',
                                    style: EvioTypography.bodySmall.copyWith(
                                      color: EvioFanColors.foreground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Botón fijo
            Container(
              padding: EdgeInsets.all(EvioSpacing.lg),
              decoration: BoxDecoration(
                color: EvioFanColors.surface,
                border: Border(
                  top: BorderSide(color: EvioFanColors.border, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    // ✅ P2: Deshabilitar durante procesamiento
                    onPressed: _processingPayment
                        ? null
                        : (isFree || selectedPaymentMethod != null
                            ? () => _handlePurchaseLinkPayment(link)
                            : null),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EvioFanColors.primary,
                      foregroundColor: EvioFanColors.primaryForeground,
                      disabledBackgroundColor:
                          EvioFanColors.mutedForeground.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                    ),
                    child: Text(
                      isFree ? 'Obtener Entrada' : 'Pagar Ahora',
                      style: EvioTypography.button,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchaseLinkPayment(PurchaseLink link) async {
    // ✅ P2: Doble click protection
    if (_isDisposed || _processingPayment) return;

    setState(() => _processingPayment = true);

    final isFree = link.customPrice == 0;

    try {
      // Mostrar loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: EvioFanColors.primary),
        ),
      );

      // Verificar autenticación
      final authUser = ref.read(currentAuthUserProvider);
      if (authUser == null) {
        if (_isDisposed || !mounted) return;
        Navigator.of(context).pop();
        // ✅ P3: Verificar mounted antes de navegar
        if (!mounted) return;
        context.go('/auth/login?redirect=/checkout?purchase_link=${link.id}');
        return;
      }

      if (isFree) {
        // Entrada gratis → usar directamente
        // ✅ P1: Agregar timeout
        final result = await _purchaseLinkRepo
            .usePurchaseLink(link.id)
            .timeout(const Duration(seconds: 15));

        if (_isDisposed || !mounted) return;
        Navigator.of(context).pop();

        debugPrint('✅ Purchase link usado: $result');
        _showSuccessModal(isFree: true);
      } else {
        // Con pago → simular pago (TODO: Mercado Pago)
        await Future.delayed(const Duration(seconds: 2));

        if (_isDisposed || !mounted) return;

        // Marcar como usado después del pago
        // ✅ P1: Agregar timeout
        final result = await _purchaseLinkRepo
            .usePurchaseLink(link.id)
            .timeout(const Duration(seconds: 15));

        if (_isDisposed || !mounted) return;
        Navigator.of(context).pop();

        debugPrint('✅ Purchase link pagado y usado: $result');
        _showSuccessModal(isFree: false);
      }
    } on TimeoutException {
      debugPrint('❌ Timeout en purchase link payment');

      if (_isDisposed || !mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorDialog('La operación tardó demasiado. Intentá de nuevo.');
    } catch (e) {
      debugPrint('❌ Error en purchase link payment: $e');

      if (_isDisposed || !mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorDialog('Error: $e');
    } finally {
      // ✅ P2: Reset doble click protection
      if (!_isDisposed && mounted) {
        setState(() => _processingPayment = false);
      }
    }
  }

  // ==========================================================================
  // CART CHECKOUT (flujo normal existente)
  // ==========================================================================

  Widget _buildCartCheckout() {
    final cart = ref.watch(cartProvider);

    // Validar que haya datos en el carrito
    if (cart.eventId == null || cart.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: EvioFanColors.mutedForeground,
                ),
                SizedBox(height: EvioSpacing.md),
                Text(
                  'Carrito vacío',
                  style: EvioTypography.h3.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                ),
                SizedBox(height: EvioSpacing.lg),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final eventAsync = ref.watch(eventInfoProvider(cart.eventId!));
    final categoriesAsync = ref.watch(eventTicketCategoriesProvider(cart.eventId!));

    return Scaffold(
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: Column(
          children: [
            // AppBar
            SafeArea(
              bottom: false,
              child: Container(
                height: 56,
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: EvioFanColors.foreground),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      'Checkout',
                      style: EvioTypography.h3.copyWith(
                        color: EvioFanColors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Body
            Expanded(
              child: eventAsync.when(
                data: (event) {
                  if (event == null) {
                    return Center(
                      child: Text(
                        'Evento no encontrado',
                        style: EvioTypography.bodyLarge.copyWith(
                          color: EvioFanColors.foreground,
                        ),
                      ),
                    );
                  }

                  return categoriesAsync.when(
                    data: (categories) {
                      final allTiers =
                          categories.expand((category) => category.tiers).toList();
                      return _buildCartContent(event, allTiers);
                    },
                    loading: () => Center(
                      child: CircularProgressIndicator(color: EvioFanColors.primary),
                    ),
                    error: (e, st) => Center(
                      child: Text('Error: $e', style: TextStyle(color: EvioFanColors.error)),
                    ),
                  );
                },
                loading: () => Center(
                  child: CircularProgressIndicator(color: EvioFanColors.primary),
                ),
                error: (e, st) => Center(
                  child: Text('Error: $e', style: TextStyle(color: EvioFanColors.error)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(Event event, List<TicketTier> allTiers) {
    final cart = ref.watch(cartProvider);

    final selectedTiers = allTiers.where((t) => cart.items.containsKey(t.id)).toList();

    int subtotal = 0;
    for (final tier in selectedTiers) {
      final qty = cart.items[tier.id] ?? 0;
      subtotal += tier.price * qty;
    }

    const serviceFee = 350;
    final total = subtotal + serviceFee;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(EvioSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title.toUpperCase(),
                  style: EvioTypography.labelSmall.copyWith(
                    color: EvioFanColors.mutedForeground,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: EvioSpacing.lg),
                ...selectedTiers.map((tier) {
                  final qty = cart.items[tier.id] ?? 0;
                  return _buildTicketItem(tier, qty);
                }),
                SizedBox(height: EvioSpacing.xl),
                _buildPricingSummary(subtotal, serviceFee, total),
                SizedBox(height: EvioSpacing.xl),
                Text(
                  'OPCIONES DE PAGO',
                  style: EvioTypography.labelSmall.copyWith(
                    color: EvioFanColors.mutedForeground,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: EvioSpacing.md),
                _buildPaymentMethod(
                  icon: Icons.credit_card,
                  title: 'Tarjeta de Crédito/Débito',
                  value: 'card',
                  logos: ['visa', 'mastercard', 'amex'],
                ),
                SizedBox(height: EvioSpacing.sm),
                _buildPaymentMethod(
                  icon: Icons.account_balance_wallet,
                  title: 'Mercado Pago',
                  value: 'mercadopago',
                  color: const Color(0xFF009EE3),
                ),
                SizedBox(height: EvioSpacing.sm),
                _buildPaymentMethod(
                  icon: Icons.phone_android,
                  title: 'MODO',
                  value: 'modo',
                  color: const Color(0xFFB429F9),
                ),
                SizedBox(height: 100),
              ],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(EvioSpacing.lg),
          decoration: BoxDecoration(
            color: EvioFanColors.surface,
            border: Border(top: BorderSide(color: EvioFanColors.border, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    selectedPaymentMethod != null ? () => _handleCartPayment(total) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvioFanColors.primary,
                  foregroundColor: EvioFanColors.primaryForeground,
                  disabledBackgroundColor:
                      EvioFanColors.mutedForeground.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                ),
                child: Text('Pagar Ahora', style: EvioTypography.button),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleCartPayment(int total) async {
    if (_isDisposed) return;
    if (selectedPaymentMethod == null) return;

    final cart = ref.read(cartProvider);

    try {
      if (_isDisposed || !mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: EvioFanColors.primary),
        ),
      );

      final authUser = ref.read(currentAuthUserProvider);
      if (authUser == null) {
        throw Exception('Usuario no autenticado');
      }

      debugPrint('🟡 CHECKOUT: Iniciando pago');

      final userAsync = await ref.read(currentUserProvider.future);
      if (userAsync == null) {
        throw Exception('Usuario no encontrado en la base de datos');
      }

      await ref.read(checkoutProvider.notifier).processPayment(
            eventId: cart.eventId!,
            userId: userAsync.id,
            tierQuantities: cart.items,
          );

      final checkoutState = ref.read(checkoutProvider);

      if (_isDisposed || !mounted) return;
      Navigator.of(context).pop();

      if (checkoutState.error != null) {
        debugPrint('❌ ERROR EN CHECKOUT: ${checkoutState.error}');
        _showErrorDialog(checkoutState.error!);
        return;
      }

      debugPrint('✅ ORDEN CREADA EXITOSAMENTE');
      ref.read(cartProvider.notifier).clear();

      if (_isDisposed || !mounted) return;
      _showSuccessModal(isFree: false);
    } catch (e, stackTrace) {
      debugPrint('❌ EXCEPCIÓN EN CHECKOUT: $e');
      debugPrint('❌ STACK: $stackTrace');

      if (_isDisposed || !mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('Error inesperado: $e');
    }
  }

  // ==========================================================================
  // SHARED WIDGETS
  // ==========================================================================

  Widget _buildTicketItem(TicketTier tier, int quantity) {
    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.md),
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioFanColors.surface,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: EvioFanColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier.name,
                  style: EvioTypography.bodyLarge.copyWith(
                    color: EvioFanColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: EvioSpacing.xxs),
                Text(
                  'Precio: ${CurrencyFormatter.formatPrice(tier.price)}',
                  style: EvioTypography.bodySmall.copyWith(
                    color: EvioFanColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Cantidad',
                style: EvioTypography.labelSmall.copyWith(
                  color: EvioFanColors.mutedForeground,
                ),
              ),
              Text(
                'x$quantity',
                style: EvioTypography.h4.copyWith(color: EvioFanColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSummary(int subtotal, int serviceFee, int total) {
    return Column(
      children: [
        _buildPriceRow('Subtotal:', subtotal, isBold: false),
        SizedBox(height: EvioSpacing.sm),
        _buildPriceRow('Cargo por servicio:', serviceFee, isBold: false),
        SizedBox(height: EvioSpacing.md),
        Divider(color: EvioFanColors.border),
        SizedBox(height: EvioSpacing.md),
        _buildPriceRow('Total:', total, isBold: true),
      ],
    );
  }

  Widget _buildPriceRow(String label, int amount, {required bool isBold, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? EvioTypography.h4 : EvioTypography.bodyMedium).copyWith(
            color: EvioFanColors.foreground,
          ),
        ),
        Text(
          CurrencyFormatter.formatPrice(amount, includeDecimals: true),
          style: (isBold ? EvioTypography.h3 : EvioTypography.bodyLarge).copyWith(
            color: highlight || isBold ? EvioFanColors.primary : EvioFanColors.foreground,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
    List<String>? logos,
  }) {
    final isSelected = selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => selectedPaymentMethod = value),
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.md),
        decoration: BoxDecoration(
          color: EvioFanColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          border: Border.all(
            color: isSelected ? EvioFanColors.primary : EvioFanColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(EvioSpacing.sm),
                  decoration: BoxDecoration(
                    color: (color ?? EvioFanColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                  child: Icon(
                    icon,
                    color: color ?? EvioFanColors.primary,
                    size: EvioSpacing.iconM,
                  ),
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: EvioTypography.bodyLarge.copyWith(
                      color: EvioFanColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (logos != null) ...[
              SizedBox(height: EvioSpacing.sm),
              Row(
                children: logos.map((logo) {
                  return Padding(
                    padding: EdgeInsets.only(right: EvioSpacing.sm),
                    child: _buildCardLogo(logo),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardLogo(String brand) {
    Color color;
    switch (brand) {
      case 'visa':
        color = const Color(0xFF1A1F71);
        break;
      case 'mastercard':
        color = const Color(0xFFEB001B);
        break;
      case 'amex':
        color = const Color(0xFF006FCF);
        break;
      default:
        color = EvioFanColors.mutedForeground;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: EvioSpacing.xs, vertical: EvioSpacing.xxs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        brand.toUpperCase(),
        style: EvioTypography.labelSmall.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _showSuccessModal({required bool isFree}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: EvioFanColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvioRadius.card),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: EvioFanColors.primary, size: 64),
            SizedBox(height: EvioSpacing.lg),
            Text(
              isFree ? '¡Entrada obtenida!' : '¡Compra exitosa!',
              style: EvioTypography.h3.copyWith(color: EvioFanColors.foreground),
            ),
            SizedBox(height: EvioSpacing.sm),
            Text(
              isFree
                  ? 'Tu entrada fue agregada a tus tickets'
                  : 'Tus tickets fueron generados correctamente',
              style: EvioTypography.bodyMedium.copyWith(
                color: EvioFanColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EvioSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/tickets');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvioFanColors.primary,
                  foregroundColor: EvioFanColors.primaryForeground,
                ),
                child: const Text('Ver mis tickets'),
              ),
            ),
            SizedBox(height: EvioSpacing.sm),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/home');
              },
              child: Text(
                'Volver al inicio',
                style: TextStyle(color: EvioFanColors.mutedForeground),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String errorMessage) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: EvioFanColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvioRadius.card),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: EvioFanColors.error, size: 28),
            SizedBox(width: EvioSpacing.sm),
            Text(
              'Error',
              style: EvioTypography.h3.copyWith(color: EvioFanColors.foreground),
            ),
          ],
        ),
        content: Text(
          errorMessage,
          style: EvioTypography.bodyMedium.copyWith(
            color: EvioFanColors.mutedForeground,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cerrar', style: TextStyle(color: EvioFanColors.mutedForeground)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: EvioFanColors.primary,
              foregroundColor: EvioFanColors.primaryForeground,
            ),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
