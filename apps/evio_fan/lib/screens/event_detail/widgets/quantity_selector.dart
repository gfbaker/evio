import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final Function(int) onQuantityChanged;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.maxQuantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Cantidad',
          style: TextStyle(color: EvioFanColors.foreground, fontSize: 14),
        ),
        Row(
          children: [
            // Decrement Button
            _QuantityButton(
              icon: Icons.remove,
              onTap: quantity > 1
                  ? () => onQuantityChanged(quantity - 1)
                  : null,
              isPrimary: false,
            ),

            SizedBox(width: EvioSpacing.sm),

            // Current Quantity
            Text(
              '$quantity',
              style: TextStyle(color: EvioFanColors.foreground, fontSize: 16),
            ),

            SizedBox(width: EvioSpacing.sm),

            // Increment Button
            _QuantityButton(
              icon: Icons.add,
              onTap: quantity < maxQuantity
                  ? () => onQuantityChanged(quantity + 1)
                  : null,
              isPrimary: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isPrimary;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isPrimary && !isDisabled
              ? EvioFanColors.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(EvioRadius.button),
          border: !isPrimary
              ? Border.all(
                  color: EvioFanColors.primary.withValues(
                    alpha: isDisabled ? 0.3 : 1.0,
                  ),
                  width: 2,
                )
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: isPrimary
              ? EvioFanColors.primaryForeground.withValues(
                  alpha: isDisabled ? 0.3 : 1.0,
                )
              : EvioFanColors.primary.withValues(alpha: isDisabled ? 0.3 : 1.0),
        ),
      ),
    );
  }
}
