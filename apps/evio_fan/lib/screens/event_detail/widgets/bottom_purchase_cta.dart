import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

class BottomPurchaseCTA extends StatelessWidget {
  final AsyncValue<List<TicketType>> ticketsAsync;
  final Map<String, int> quantities;
  final VoidCallback onPurchase;

  const BottomPurchaseCTA({
    super.key,
    required this.ticketsAsync,
    required this.quantities,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return ticketsAsync.maybeWhen(
      data: (tickets) {
        final total = _calculateTotal(tickets);
        final hasSelection = total > 0;

        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250), // Animación suave
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
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: EvioFanColors.border.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Total (siempre visible si hasSelection)
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
                            '\$${(total / 100).toStringAsFixed(0)} ARS',
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
                    // Botón
                    GestureDetector(
                      onTap: hasSelection
                          ? () {
                              HapticFeedback.mediumImpact();
                              onPurchase();
                            }
                          : null,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: hasSelection
                              ? EvioFanColors.primary
                              : EvioFanColors.mutedForeground.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(EvioRadius.card),
                        ),
                        child: Center(
                          child: Text(
                            hasSelection
                                ? 'Comprar Tickets'
                                : 'Selecciona tus tickets',
                            style: TextStyle(
                              color: hasSelection
                                  ? Colors.black
                                  : EvioFanColors.mutedForeground,
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

  int _calculateTotal(List<TicketType> tickets) {
    int total = 0;
    for (final ticket in tickets) {
      final qty = quantities[ticket.id] ?? 0;
      total += ticket.price * qty;
    }
    return total;
  }

  int _getTotalTickets() {
    return quantities.values.fold(0, (sum, qty) => sum + qty);
  }
}
