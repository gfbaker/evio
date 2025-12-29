import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class EventProducerSection extends StatelessWidget {
  final Event event;

  const EventProducerSection({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // Si no hay organizerName, no mostrar nada
    if (event.organizerName == null || event.organizerName!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productora',
          style: TextStyle(
            color: EvioFanColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        Container(
          padding: EdgeInsets.all(EvioSpacing.md),
          decoration: BoxDecoration(
            color: EvioFanColors.card,
            borderRadius: BorderRadius.circular(EvioRadius.card),
            border: Border.all(color: EvioFanColors.border, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: EvioFanColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business,
                  color: EvioFanColors.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: EvioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.organizerName!,
                      style: TextStyle(
                        color: EvioFanColors.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Organizador del evento',
                      style: TextStyle(
                        color: EvioFanColors.mutedForeground,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
