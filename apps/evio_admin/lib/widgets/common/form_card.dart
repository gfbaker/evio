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
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(EvioSpacing.lg),
            child: Row(
              children: [
                // Icono con fondo amarillo
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: EvioLightColors.accent,
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: EvioLightColors.accentForeground,
                  ),
                ),
                SizedBox(width: EvioSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              EvioSpacing.lg,
              0,
              EvioSpacing.lg,
              EvioSpacing.lg,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
