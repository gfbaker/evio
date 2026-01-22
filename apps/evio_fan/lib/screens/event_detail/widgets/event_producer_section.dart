import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../../providers/event_provider.dart';

class EventProducerSection extends ConsumerWidget {
  final Event event;

  const EventProducerSection({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener info de la productora
    final producerAsync = ref.watch(producerInfoProvider(event.producerId));

    return producerAsync.when(
      data: (producer) {
        // Si no hay productora, no mostrar nada
        if (producer == null) return const SizedBox.shrink();

        // Usar organizerName si existe, sino el nombre de la productora
        final displayName = event.organizerName?.isNotEmpty == true 
            ? event.organizerName! 
            : producer.name;

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
                  // Logo de la productora
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: EvioFanColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: producer.logoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              producer.logoUrl!,
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              errorBuilder: (_, __, ___) => _buildFallbackIcon(producer.name),
                            ),
                          )
                        : _buildFallbackIcon(producer.name),
                  ),
                  SizedBox(width: EvioSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
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
      },
      loading: () => _buildLoadingState(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFallbackIcon(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: EvioFanColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
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
                  color: EvioFanColors.muted,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: EvioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: EvioFanColors.muted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: 80,
                      height: 12,
                      decoration: BoxDecoration(
                        color: EvioFanColors.muted,
                        borderRadius: BorderRadius.circular(4),
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
