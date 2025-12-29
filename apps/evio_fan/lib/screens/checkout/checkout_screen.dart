import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/order_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../providers/ticket_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    // ✅ Dismiss keyboard al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });

    final cart = ref.watch(cartProvider);

    // Validar que haya datos en el carrito
    if (cart.eventId == null || cart.isEmpty) {
      return Scaffold(
        backgroundColor: EvioFanColors.background,
        appBar: AppBar(
          backgroundColor: EvioFanColors.background,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: EvioFanColors.foreground),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
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
      );
    }

    final eventAsync = ref.watch(eventInfoProvider(cart.eventId!));
    final ticketsAsync = ref.watch(ticketTypesProvider(cart.eventId!));

    // ✅ FIX CRÍTICO: Aquí faltaba el return del Scaffold principal
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
          'Checkout',
          style: EvioTypography.h3.copyWith(color: EvioFanColors.foreground),
        ),
      ),
      body: eventAsync.when(
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

          return ticketsAsync.when(
            data: (tickets) => _buildContent(event, tickets),
            loading: () => Center(
              child: CircularProgressIndicator(color: EvioFanColors.primary),
            ),
            error: (e, st) => Center(
              child: Text(
                'Error: $e',
                style: TextStyle(color: EvioFanColors.error),
              ),
            ),
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: EvioFanColors.primary),
        ),
        error: (e, st) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: EvioFanColors.error),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Event event, List<TicketType> allTickets) {
    final cart = ref.watch(cartProvider);

    // Filtrar solo los tickets seleccionados
    final selectedTickets = allTickets
        .where((t) => cart.items.containsKey(t.id))
        .toList();

    // Calcular totales
    int subtotal = 0;
    for (final ticket in selectedTickets) {
      final qty = cart.items[ticket.id] ?? 0;
      subtotal += ticket.price * qty;
    }

    const serviceFee = 350; // $3.50 en centavos
    final total = subtotal + serviceFee;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(EvioSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Evento info
                Text(
                  event.title.toUpperCase(),
                  style: EvioTypography.labelSmall.copyWith(
                    color: EvioFanColors.mutedForeground,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: EvioSpacing.lg),

                // Tickets seleccionados
                ...selectedTickets.map((ticket) {
                  final qty = cart.items[ticket.id] ?? 0;
                  return _buildTicketItem(ticket, qty);
                }),

                SizedBox(height: EvioSpacing.xl),

                // Resumen de precios
                _buildPricingSummary(subtotal, serviceFee, total),

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
                  subtitle: null,
                  value: 'card',
                  logos: ['visa', 'mastercard', 'amex'],
                ),
                SizedBox(height: EvioSpacing.sm),

                _buildPaymentMethod(
                  icon: Icons.account_balance_wallet,
                  title: 'Mercado Pago',
                  subtitle: null,
                  value: 'mercadopago',
                  color: const Color(0xFF009EE3),
                ),
                SizedBox(height: EvioSpacing.sm),

                _buildPaymentMethod(
                  icon: Icons.phone_android,
                  title: 'MODO',
                  subtitle: null,
                  value: 'modo',
                  color: const Color(0xFFB429F9),
                ),

                SizedBox(height: 100), // Espacio para el botón fixed
              ],
            ),
          ),
        ),

        // Botón fijo en el bottom
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
                onPressed: selectedPaymentMethod != null
                    ? () => _handlePayment(total)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EvioFanColors.primary,
                  foregroundColor: EvioFanColors.primaryForeground,
                  disabledBackgroundColor: EvioFanColors.mutedForeground
                      .withValues(alpha: 0.3),
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

  Widget _buildTicketItem(TicketType ticket, int quantity) {
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
                  ticket.name,
                  style: EvioTypography.bodyLarge.copyWith(
                    color: EvioFanColors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: EvioSpacing.xxs),
                Text(
                  'Precio: \$${(ticket.price / 100).toStringAsFixed(0)}',
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

  Widget _buildPriceRow(String label, int amount, {required bool isBold}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isBold ? EvioTypography.h4 : EvioTypography.bodyMedium)
              .copyWith(color: EvioFanColors.foreground),
        ),
        Text(
          '\$${(amount / 100).toStringAsFixed(2)}',
          style: (isBold ? EvioTypography.h3 : EvioTypography.bodyLarge)
              .copyWith(
                color: isBold
                    ? EvioFanColors.primary
                    : EvioFanColors.foreground,
              ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod({
    required IconData icon,
    required String title,
    String? subtitle,
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
            // Primera fila: icono + título
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(EvioSpacing.sm),
                  decoration: BoxDecoration(
                    color: (color ?? EvioFanColors.primary).withValues(
                      alpha: 0.1,
                    ),
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

            // Segunda fila: logos (solo si existen)
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
      padding: EdgeInsets.symmetric(
        horizontal: EvioSpacing.xs,
        vertical: EvioSpacing.xxs,
      ),
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

  Future<void> _handlePayment(int total) async {
    if (selectedPaymentMethod == null) return;

    final cart = ref.read(cartProvider);

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

      // ✅ CREAR ORDEN (con validación atómica)
      final authUser = ref.read(currentAuthUserProvider);
      if (authUser == null) {
        throw Exception('Usuario no autenticado');
      }

      print('🟡 CHECKOUT: Iniciando pago');
      print('🟡 User ID (Auth): ${authUser.id}');
      print('🟡 Event ID: ${cart.eventId}');
      print('🟡 Tickets: ${cart.items}');

      await ref.read(checkoutProvider.notifier).processPayment(
        eventId: cart.eventId!,
        userId: authUser.id,
        ticketQuantities: cart.items,
      );

      final checkoutState = ref.read(checkoutProvider);

      print('🟡 CHECKOUT: Respuesta recibida');
      print('🟡 Error: ${checkoutState.error}');
      print('🟡 Order: ${checkoutState.completedOrder?.id}');

      if (!mounted) return;

      // Cerrar loading
      Navigator.of(context).pop();

      if (checkoutState.error != null) {
        // ❌ Error - Mostrar Dialog
        print('❌ ERROR EN CHECKOUT: ${checkoutState.error}');
        _showErrorDialog(checkoutState.error!);
        return;
      }

      // ✅ Orden creada exitosamente
      print('✅ ORDEN CREADA EXITOSAMENTE');
      
      // Limpiar carrito
      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;

      // Mostrar success modal
      _showSuccessModal();
    } catch (e, stackTrace) {
      print('❌ EXCEPCIÓN EN CHECKOUT: $e');
      print('❌ STACK: $stackTrace');
      
      if (!mounted) return;
      
      // Cerrar loading si está abierto
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorDialog('Error inesperado: $e');
    }
  }

  void _showSuccessModal() {
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
              '¡Compra exitosa!',
              style: EvioTypography.h3.copyWith(
                color: EvioFanColors.foreground,
              ),
            ),
            SizedBox(height: EvioSpacing.sm),
            Text(
              'Tus tickets fueron generados correctamente',
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
                  Navigator.of(context).pop(); // Cerrar modal
                  context.go('/tickets'); // Ir a Tickets tab
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
                Navigator.of(context).pop(); // Cerrar modal
                context.go('/home'); // Volver al inicio
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
              style: EvioTypography.h3.copyWith(
                color: EvioFanColors.foreground,
              ),
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
            child: Text(
              'Cerrar',
              style: TextStyle(color: EvioFanColors.mutedForeground),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Cerrar dialog
              Navigator.of(context).pop(); // Volver atrás
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
