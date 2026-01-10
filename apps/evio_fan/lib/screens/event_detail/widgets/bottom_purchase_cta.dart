import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

class BottomPurchaseCTA extends StatelessWidget {
  final AsyncValue<List<TicketCategory>> categoriesAsync;
  final Map<String, int> quantities;
  final GlobalKey ticketsSectionKey;
  final ScrollController scrollController;
  final VoidCallback onPurchase;

  const BottomPurchaseCTA({
    super.key,
    required this.categoriesAsync,
    required this.quantities,
    required this.ticketsSectionKey,
    required this.scrollController,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.maybeWhen(
      data: (categories) {
        final total = _calculateTotal(categories);
        final hasSelection = total > 0;

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  EvioFanColors.background.withValues(alpha: 0),
                  EvioFanColors.background.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.15],
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(EvioSpacing.md),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSelection) SizedBox(height: EvioSpacing.sm),
                    
                    // Total (solo visible si hasSelection)
                    if (hasSelection) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              color: EvioFanColors.mutedForeground,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.formatPrice(total),
                            style: TextStyle(
                              color: EvioFanColors.foreground,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: EvioSpacing.xxs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_getTotalTickets()} tickets',
                          style: TextStyle(
                            color: EvioFanColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      SizedBox(height: EvioSpacing.md),
                    ],
                    
                    // ✅ Botón AMARILLO siempre (altura fija)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        
                        if (hasSelection) {
                          // Si hay selección → Comprar
                          onPurchase();
                        } else {
                          // Si NO hay selección → Scroll a tickets
                          _scrollToTickets();
                        }
                      },
                      child: Container(
                        height: 60, // ✅ Altura fija siempre
                        decoration: BoxDecoration(
                          // ✅ AMARILLO SIEMPRE (primary)
                          color: EvioFanColors.primary,
                          borderRadius: BorderRadius.circular(EvioRadius.card),
                        ),
                        child: Center(
                          child: Text(
                            // ✅ Texto dinámico
                            hasSelection
                                ? 'Comprar tickets'
                                : 'Seleccionar tus tickets',
                            style: TextStyle(
                              color: Colors.black, // Texto negro sobre amarillo
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  // ============================================
  // SCROLL AUTOMÁTICO A TICKETS
  // ============================================

  void _scrollToTickets() {
    final context = ticketsSectionKey.currentContext;
    if (context != null) {
      // Obtener la posición del widget
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero).dy;
      
      // Calcular offset considerando el scroll actual
      final targetOffset = scrollController.offset + position - 100; // 100px de padding top
      
      // Scroll suave
      scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      
      debugPrint('🎯 [CTA] Scrolling to tickets section');
    }
  }

  int _calculateTotal(List<TicketCategory> categories) {
    int total = 0;
    for (final category in categories) {
      for (final tier in category.tiers) {
        final qty = quantities[tier.id] ?? 0;
        total += tier.price * qty;
      }
    }
    return total;
  }

  int _getTotalTickets() {
    return quantities.values.fold(0, (sum, qty) => sum + qty);
  }
}
