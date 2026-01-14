import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'detail_card.dart';

/// Card de ingresos actuales y potenciales.
class RevenueCard extends StatelessWidget {
  final EventStats stats;

  const RevenueCard({required this.stats, super.key});

  @override
  Widget build(BuildContext context) {
    final currentRevenue = stats.currentRevenue / 100;
    final potentialRevenue = stats.potentialRevenue / 100;
    final remaining = stats.remainingRevenue / 100;
    final avgPrice = stats.avgPrice / 100;

    return DetailCard(
      title: 'Ingresos',
      icon: Icons.attach_money,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ingresos actuales (destacado)
          Text(
            'Ingresos Actuales',
            style: TextStyle(
              fontSize: 12,
              color: EvioLightColors.mutedForeground,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '\$${currentRevenue.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: EvioLightColors.accent,
            ),
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
            child: Divider(color: EvioLightColors.border),
          ),
          
          // Detalles
          _RevenueRow(
            label: 'Precio promedio',
            value: '\$${avgPrice.toStringAsFixed(2)}',
          ),
          SizedBox(height: EvioSpacing.sm),
          _RevenueRow(
            label: 'Ingresos potenciales',
            value: '\$${potentialRevenue.toStringAsFixed(2)}',
          ),
          SizedBox(height: EvioSpacing.sm),
          _RevenueRow(
            label: 'Por vender',
            value: '\$${remaining.toStringAsFixed(2)}',
            valueColor: EvioLightColors.revenuePending,
          ),
        ],
      ),
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _RevenueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: EvioLightColors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? EvioLightColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
