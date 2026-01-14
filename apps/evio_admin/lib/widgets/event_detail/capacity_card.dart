import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'detail_card.dart';

/// Card de capacidad y ventas con barra de progreso.
class CapacityCard extends StatelessWidget {
  final EventStats stats;

  const CapacityCard({required this.stats, super.key});

  @override
  Widget build(BuildContext context) {
    final sold = stats.soldCount;
    final total = stats.totalCapacity;
    final percentage = total > 0 ? (sold / total) : 0.0;
    final percentInt = (percentage * 100).round();

    final progressColor = _getProgressColor(percentInt);

    return DetailCard(
      title: 'Capacidad & Ventas',
      icon: Icons.bar_chart,
      child: Column(
        children: [
          // Vendidos / Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vendidos:',
                style: TextStyle(
                  fontSize: 14,
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              Text(
                '$sold / $total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: EvioLightColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.sm),
          
          // Barra de progreso
          Container(
            height: 32,
            width: double.infinity,
            decoration: BoxDecoration(
              color: EvioLightColors.muted,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: percentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$percentInt%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: EvioSpacing.xs),
          
          // Info adicional
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponibles: ${stats.availableCount}',
                style: TextStyle(
                  fontSize: 12,
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              if (percentInt >= 90)
                Text(
                  '¡Casi Agotado!',
                  style: TextStyle(
                    fontSize: 12,
                    color: EvioLightColors.destructive,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          
          Padding(
            padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
            child: Divider(color: EvioLightColors.border),
          ),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Capacidad Total',
                  value: total.toString(),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Tickets Vendidos',
                  value: sold.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int percent) {
    if (percent >= 90) return EvioLightColors.progressFull;
    if (percent >= 70) return EvioLightColors.progressHigh;
    if (percent >= 40) return EvioLightColors.progressMedium;
    return EvioLightColors.progressLow;
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: EvioLightColors.mutedForeground,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: EvioLightColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
