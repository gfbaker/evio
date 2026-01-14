import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../../providers/saved_event_provider.dart';
import '../widgets/saved_event_card.dart';

/// Tab de eventos guardados/favoritos
class GuardadosTab extends ConsumerWidget {
  const GuardadosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedEventsAsync = ref.watch(savedEventsProvider);

    return savedEventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: EdgeInsets.all(EvioSpacing.lg),
          itemCount: events.length,
          separatorBuilder: (context, index) => SizedBox(height: EvioSpacing.md),
          itemBuilder: (context, index) {
            final event = events[index];
            return SavedEventCard(event: event);
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      ),
      error: (e, st) => _buildErrorState(e.toString()),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          left: EvioSpacing.xl,
          right: EvioSpacing.xl,
          top: EvioSpacing.xl,
          bottom: 120,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sin eventos guardados',
              style: EvioTypography.h3.copyWith(
                color: EvioFanColors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: EvioSpacing.sm),
            Text(
              'Guardá tus eventos favoritos\npara verlos rápidamente aquí',
              style: EvioTypography.bodyMedium.copyWith(
                color: EvioFanColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(EvioSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: EvioFanColors.error),
            SizedBox(height: EvioSpacing.lg),
            Text(
              'Error al cargar eventos',
              style: EvioTypography.h4.copyWith(color: EvioFanColors.foreground),
            ),
            SizedBox(height: EvioSpacing.sm),
            Text(
              error,
              style: EvioTypography.bodySmall.copyWith(
                color: EvioFanColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
