import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class TierCard extends StatelessWidget {
  final TicketTier tier;
  final String categoryName;
  final int? categoryMaxPerPurchase;
  final bool isSelected;
  final int quantity;
  final Function(int) onQuantityChanged;

  const TierCard({
    super.key,
    required this.tier,
    required this.categoryName,
    required this.categoryMaxPerPurchase,
    required this.isSelected,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = tier.isSoldOut;
    final isAvailable = tier.isActive && !isSoldOut;
    final hasDescription = tier.description != null && tier.description!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Nombre del tier + Precio
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre del tier
            Expanded(
              child: Text(
                tier.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isAvailable 
                      ? EvioFanColors.foreground 
                      : EvioFanColors.mutedForeground,
                ),
              ),
            ),
            
            // Precio
            Text(
              tier.price == 0 ? 'GRATIS' : CurrencyFormatter.formatPrice(tier.price),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isAvailable
                    ? Colors.white
                    : EvioFanColors.mutedForeground.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        
        SizedBox(height: EvioSpacing.xs),
        
        // Row 2: Descripción (si existe) + Controles
        // SIEMPRE mostramos esta row para mantener consistencia visual
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Descripción del tier o espacio vacío (mantiene altura consistente)
            Expanded(
              child: hasDescription
                  ? Text(
                      tier.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: EvioFanColors.mutedForeground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox(height: 16), // Altura mínima para consistencia
            ),
            
            SizedBox(width: EvioSpacing.sm),
            
            // Controles: [-] cantidad [+] o badge de agotado
            _buildControls(isAvailable, isSoldOut),
          ],
        ),
        
        // Stock info (solo si está activo y low stock)
        if (isAvailable && tier.isLowStock) ...[
          SizedBox(height: EvioSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 14,
                color: EvioFanColors.warning,
              ),
              SizedBox(width: 4),
              Text(
                'Solo quedan ${tier.availableQuantity} disponibles',
                style: TextStyle(
                  fontSize: 11,
                  color: EvioFanColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildControls(bool isAvailable, bool isSoldOut) {
    if (isAvailable) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón [-]
          GestureDetector(
            onTap: quantity > 0 
                ? () => onQuantityChanged(quantity - 1)
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: quantity > 0
                    ? EvioFanColors.muted
                    : EvioFanColors.muted.withValues(alpha: 0.3),
                border: Border.all(
                  color: quantity > 0
                      ? EvioFanColors.border
                      : EvioFanColors.border.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                Icons.remove,
                size: 18,
                color: quantity > 0
                    ? EvioFanColors.foreground
                    : EvioFanColors.mutedForeground,
              ),
            ),
          ),
          
          SizedBox(width: EvioSpacing.sm),
          
          // Cantidad
          SizedBox(
            width: 24,
            child: Center(
              child: Text(
                quantity.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: EvioFanColors.foreground,
                ),
              ),
            ),
          ),
          
          SizedBox(width: EvioSpacing.sm),
          
          // Botón [+]
          GestureDetector(
            onTap: quantity < _getMaxQuantity()
                ? () => onQuantityChanged(quantity + 1)
                : null,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: quantity < _getMaxQuantity()
                    ? EvioFanColors.primary
                    : EvioFanColors.muted.withValues(alpha: 0.3),
              ),
              child: Icon(
                Icons.add,
                size: 18,
                color: quantity < _getMaxQuantity()
                    ? Colors.black
                    : EvioFanColors.mutedForeground,
              ),
            ),
          ),
        ],
      );
    } else if (isSoldOut) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: EvioSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(EvioRadius.button),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          'Agotado',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  int _getMaxQuantity() {
    // Prioridad: max de categoría > availableQuantity
    if (categoryMaxPerPurchase != null) {
      return categoryMaxPerPurchase! < tier.availableQuantity
          ? categoryMaxPerPurchase!
          : tier.availableQuantity;
    }
    return tier.availableQuantity;
  }
}
