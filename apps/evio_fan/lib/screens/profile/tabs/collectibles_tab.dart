import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import '../widgets/collectible_card.dart';

/// Tab de coleccionables/totems
/// 
/// NOTA: El fondo DEBE ser transparente para heredar el gradiente del parent.
/// No usar Scaffold ni Container con color sólido.
class CollectiblesTab extends StatelessWidget {
  const CollectiblesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = mockCollectibles.where((c) => c.unlocked).length;
    final totalCount = mockCollectibles.length;
    final progress = unlockedCount / totalCount;

    // ⚡ CLAVE: SingleChildScrollView SIN container con color
    // El fondo lo provee el parent (ProfileScreen con gradiente)
    return SingleChildScrollView(
      padding: EdgeInsets.all(EvioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con progreso
          _buildProgressHeader(unlockedCount, totalCount, progress),

          SizedBox(height: EvioSpacing.xl),

          // Grid de coleccionables
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: EvioSpacing.md,
              mainAxisSpacing: EvioSpacing.md,
              childAspectRatio: 0.85,
            ),
            itemCount: mockCollectibles.length,
            itemBuilder: (context, index) {
              return CollectibleCard(collectible: mockCollectibles[index]);
            },
          ),

          // Espacio para bottom nav
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(int unlocked, int total, double progress) {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFA855F7).withValues(alpha: 0.2),
            const Color(0xFFEC4899).withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(
          color: const Color(0xFFA855F7).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: EvioFanColors.primary,
                size: 24,
              ),
              SizedBox(width: EvioSpacing.sm),
              Expanded(
                child: Text(
                  'La Fiesta Completa',
                  style: EvioTypography.h4.copyWith(
                    color: EvioFanColors.foreground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.xxs),
          Text(
            '(Edición Épica)',
            style: EvioTypography.bodySmall.copyWith(
              color: EvioFanColors.mutedForeground,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: EvioSpacing.md),

          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso',
                style: EvioTypography.labelMedium.copyWith(
                  color: EvioFanColors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$unlocked/$total',
                style: EvioTypography.labelMedium.copyWith(
                  color: EvioFanColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 8,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: EvioFanColors.muted.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFA855F7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
