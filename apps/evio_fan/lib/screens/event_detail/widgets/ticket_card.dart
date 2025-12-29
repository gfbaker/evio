import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

import 'quantity_selector.dart';

class TicketCard extends StatelessWidget {
  final TicketType ticket;
  final bool isActive;
  final bool isSelected;
  final int quantity;
  final VoidCallback onTap;
  final Function(int) onQuantityChanged;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.isActive,
    required this.isSelected,
    required this.quantity,
    required this.onTap,
    required this.onQuantityChanged,
  });

  String _formatPrice(int priceInCents) {
    return '\$${(priceInCents / 100).toStringAsFixed(0)} ARS';
  }

  @override
  Widget build(BuildContext context) {
    // 🎯 Determinar si es "Próximamente" o "Agotado"
    final isComingSoon = !isActive && !ticket.isSoldOut;
    final isSoldOut = ticket.isSoldOut;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isActive ? Colors.white : EvioFanColors.muted.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(
          color: isSelected 
              ? EvioFanColors.primary 
              : isActive
                  ? EvioFanColors.border
                  : EvioFanColors.border.withValues(alpha: 0.4),
          width: isSelected ? 2 : 1.5,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? onTap : null,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          child: Padding(
            padding: EdgeInsets.all(EvioSpacing.md),
            child: Column(
              children: [
                // Main Row
                Row(
                  children: [
                    // Left: Ticket info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + Badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ticket.name,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isActive 
                                        ? EvioFanColors.foreground 
                                        : EvioFanColors.mutedForeground,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              SizedBox(width: EvioSpacing.xs),
                              // Badge de estado
                              if (isActive)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Disponible',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                )
                              else if (isComingSoon)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.orange.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 10,
                                        color: Colors.orange.shade700,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Próximamente',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else if (isSoldOut)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    'Agotado',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          
                          // Description
                          if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(
                              ticket.description!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isActive
                                    ? EvioFanColors.mutedForeground
                                    : EvioFanColors.mutedForeground.withValues(alpha: 0.7),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          
                          SizedBox(height: 8),
                          
                          // Max per purchase
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 14,
                                color: isActive
                                    ? EvioFanColors.mutedForeground
                                    : EvioFanColors.mutedForeground.withValues(alpha: 0.7),
                              ),
                              SizedBox(width: 4),
                              Text(
                                ticket.maxPerPurchase != null
                                    ? 'Máx. ${ticket.maxPerPurchase} por persona'
                                    : 'Sin límite por persona',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isActive
                                      ? EvioFanColors.mutedForeground
                                      : EvioFanColors.mutedForeground.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: EvioSpacing.md),
                    
                    // Right: Price + CTA
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          ticket.price == 0 ? 'GRATIS' : '\${ticket.price ~/ 100}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? EvioFanColors.primary
                                : EvioFanColors.mutedForeground.withValues(alpha: 0.6),
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (ticket.price > 0)
                          Text(
                            'ARS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? EvioFanColors.mutedForeground
                                  : EvioFanColors.mutedForeground.withValues(alpha: 0.5),
                            ),
                          ),
                        if (isActive) ...[
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? EvioFanColors.primary
                                  : EvioFanColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: EvioFanColors.primary,
                                      width: 1.5,
                                    ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? Icons.check : Icons.add,
                                  color: isSelected
                                      ? Colors.black
                                      : EvioFanColors.primary,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  isSelected ? 'Añadido' : 'Agregar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.black
                                        : EvioFanColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                
                // Quantity Selector (when selected)
                if (isSelected) ...[
                  SizedBox(height: EvioSpacing.md),
                  Container(
                    height: 1,
                    color: EvioFanColors.border,
                  ),
                  SizedBox(height: EvioSpacing.md),
                  QuantitySelector(
                    quantity: quantity,
                    maxQuantity: _getMaxQuantity(),
                    onQuantityChanged: onQuantityChanged,
                  ),
                ],
                
                // Low Stock Warning
                if (isActive && ticket.isLowStock) ...[
                  SizedBox(height: EvioSpacing.md),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: EvioSpacing.sm,
                      vertical: EvioSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: ticket.availableQuantity <= 5
                          ? EvioFanColors.error.withValues(alpha: 0.1)
                          : EvioFanColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: ticket.availableQuantity <= 5
                            ? EvioFanColors.error.withValues(alpha: 0.3)
                            : EvioFanColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ticket.availableQuantity <= 5
                              ? Icons.warning_amber_rounded
                              : Icons.info_outline,
                          size: 14,
                          color: ticket.availableQuantity <= 5
                              ? EvioFanColors.error
                              : EvioFanColors.warning,
                        ),
                        SizedBox(width: 6),
                        Text(
                          ticket.availableQuantity <= 5
                              ? 'Solo quedan ${ticket.availableQuantity} disponibles'
                              : 'Últimas ${ticket.availableQuantity} entradas',
                          style: TextStyle(
                            color: ticket.availableQuantity <= 5
                                ? EvioFanColors.error
                                : EvioFanColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getMaxQuantity() {
    final maxPerPurchase = ticket.maxPerPurchase ?? ticket.availableQuantity;
    return maxPerPurchase < ticket.availableQuantity
        ? maxPerPurchase
        : ticket.availableQuantity;
  }
}
