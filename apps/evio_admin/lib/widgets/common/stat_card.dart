import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvioRadius.stats),
        side: BorderSide(color: EvioLightColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: EvioTypography.bodySmall.copyWith(
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: EvioTypography.titleLarge.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EvioLightColors.surface,
                borderRadius: BorderRadius.circular(EvioRadius.lg),
              ),
              child: Icon(icon, size: EvioSpacing.iconL),
            ),
          ],
        ),
      ),
    );
  }
}
