import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class EventInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String content;
  final String? secondary;

  const EventInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.content,
    this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: EvioFanColors.primary, size: EvioSpacing.iconM),
        SizedBox(width: EvioSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: EvioFanColors.mutedForeground.withValues(alpha: 0.6),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: EvioSpacing.xs),
              Text(
                content,
                style: TextStyle(
                  color: EvioFanColors.foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (secondary != null) ...[
                SizedBox(height: EvioSpacing.xxs),
                Text(
                  secondary!,
                  style: TextStyle(
                    color: EvioFanColors.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
