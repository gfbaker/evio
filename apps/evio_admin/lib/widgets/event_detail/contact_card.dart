import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'detail_card.dart';

/// Card de información de contacto y organizador.
class ContactCard extends StatelessWidget {
  final Event event;

  const ContactCard({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Información',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organizador
          _InfoItem(
            label: 'Organizador',
            value: event.organizerName ?? 'Evio Club',
            icon: Icons.business,
          ),
          SizedBox(height: EvioSpacing.md),
          
          // Dirección
          _InfoItem(
            label: 'Dirección',
            value: event.address,
            icon: Icons.location_on,
          ),
          
          // Ciudad (si está disponible)
          if (event.city.isNotEmpty) ...[
            SizedBox(height: EvioSpacing.md),
            _InfoItem(
              label: 'Ciudad',
              value: event.city,
              icon: Icons.place,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: EvioLightColors.muted,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: EvioLightColors.mutedForeground,
          ),
        ),
        SizedBox(width: EvioSpacing.sm),
        Expanded(
          child: Column(
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
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: EvioLightColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
