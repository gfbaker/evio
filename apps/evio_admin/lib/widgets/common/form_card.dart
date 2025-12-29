import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const FormCard({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: EvioLightColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              EvioSpacing.lg,
              EvioSpacing.md,
              EvioSpacing.lg,
              EvioSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: EvioSpacing.iconM,
                  color: EvioLightColors.foreground,
                ),
                SizedBox(width: EvioSpacing.sm),
                Text(title, style: EvioTypography.h3),
              ],
            ),
          ),
          Divider(height: 1, color: EvioLightColors.border),
          Padding(padding: EdgeInsets.all(EvioSpacing.lg), child: child),
        ],
      ),
    );
  }
}
