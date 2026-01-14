import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

// ============================================
// COLLECTIBLE MODEL & DATA
// ============================================

enum CollectibleRarity {
  epic,
  rare,
  common,
}

class Collectible {
  final String id;
  final String name;
  final String emoji;
  final CollectibleRarity rarity;
  final bool unlocked;

  const Collectible({
    required this.id,
    required this.name,
    required this.emoji,
    required this.rarity,
    required this.unlocked,
  });
}

/// Mock data - 19 totems basados en la imagen
final List<Collectible> mockCollectibles = [
  // Epic (5 desbloqueados)
  const Collectible(id: '1', name: 'Disco Ball Melt', emoji: '🪩', rarity: CollectibleRarity.epic, unlocked: true),
  const Collectible(id: '2', name: 'Speaker Pulse', emoji: '🔊', rarity: CollectibleRarity.epic, unlocked: true),
  const Collectible(id: '3', name: 'Party Popper', emoji: '🎉', rarity: CollectibleRarity.epic, unlocked: true),
  const Collectible(id: '4', name: 'CDJ', emoji: '🎛️', rarity: CollectibleRarity.epic, unlocked: true),
  const Collectible(id: '5', name: 'Vinilo', emoji: '💿', rarity: CollectibleRarity.epic, unlocked: true),
  // Rare (bloqueados)
  const Collectible(id: '6', name: 'Ticket Stub', emoji: '🎫', rarity: CollectibleRarity.rare, unlocked: false),
  const Collectible(id: '7', name: 'Wristband', emoji: '🎗️', rarity: CollectibleRarity.rare, unlocked: false),
  const Collectible(id: '8', name: 'Keycard Access', emoji: '🔑', rarity: CollectibleRarity.rare, unlocked: false),
  const Collectible(id: '9', name: 'Lentes Facheros', emoji: '🕶️', rarity: CollectibleRarity.rare, unlocked: false),
  const Collectible(id: '10', name: 'Botella "Salvavidas"', emoji: '🍾', rarity: CollectibleRarity.rare, unlocked: false),
  const Collectible(id: '11', name: 'Labial Roto', emoji: '💄', rarity: CollectibleRarity.rare, unlocked: false),
  const Collectible(id: '12', name: 'Tótem Perdido', emoji: '🗿', rarity: CollectibleRarity.rare, unlocked: false),
  // Common (bloqueados)
  const Collectible(id: '13', name: 'Abanico Clack', emoji: '🪭', rarity: CollectibleRarity.common, unlocked: false),
  const Collectible(id: '14', name: 'Riñonera', emoji: '👝', rarity: CollectibleRarity.common, unlocked: false),
  const Collectible(id: '15', name: 'Cargador Portátil', emoji: '🔋', rarity: CollectibleRarity.common, unlocked: false),
  const Collectible(id: '16', name: 'Zapato Perdido', emoji: '👟', rarity: CollectibleRarity.common, unlocked: false),
  const Collectible(id: '17', name: 'Gafas de Sol Alien', emoji: '👽', rarity: CollectibleRarity.common, unlocked: false),
  const Collectible(id: '18', name: 'Fader de Mezcladora', emoji: '🎚️', rarity: CollectibleRarity.common, unlocked: false),
  const Collectible(id: '19', name: 'Bocina Bluetooth', emoji: '📻', rarity: CollectibleRarity.common, unlocked: false),
];

// ============================================
// COLLECTIBLE CARD WIDGET
// ============================================

/// Card para mostrar un coleccionable/totem en el grid
class CollectibleCard extends StatelessWidget {
  final Collectible collectible;

  const CollectibleCard({super.key, required this.collectible});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: collectible.unlocked
            ? LinearGradient(
                colors: [
                  const Color(0xFFA855F7).withValues(alpha: 0.2),
                  const Color(0xFFEC4899).withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: collectible.unlocked ? null : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(
          color: collectible.unlocked
              ? _getRarityColor(collectible.rarity).withValues(alpha: 0.3)
              : EvioFanColors.border,
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          // Contenido
          Padding(
            padding: EdgeInsets.all(EvioSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Emoji/Icon
                if (collectible.unlocked)
                  Text(collectible.emoji, style: const TextStyle(fontSize: 42))
                else
                  Opacity(
                    opacity: 0.4,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(collectible.emoji, style: const TextStyle(fontSize: 42)),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock,
                            color: EvioFanColors.mutedForeground,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: EvioSpacing.xxs),

                // Nombre
                Flexible(
                  child: Text(
                    collectible.name,
                    style: EvioTypography.labelSmall.copyWith(
                      color: collectible.unlocked
                          ? EvioFanColors.foreground
                          : EvioFanColors.mutedForeground,
                      fontWeight: collectible.unlocked ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 10,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Badge de rareza (solo si está desbloqueado)
          if (collectible.unlocked)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRarityColor(collectible.rarity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getRarityLabel(collectible.rarity),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRarityColor(CollectibleRarity rarity) {
    switch (rarity) {
      case CollectibleRarity.epic:
        return const Color(0xFFA855F7);
      case CollectibleRarity.rare:
        return const Color(0xFF3B82F6);
      case CollectibleRarity.common:
        return const Color(0xFF6B7280);
    }
  }

  String _getRarityLabel(CollectibleRarity rarity) {
    switch (rarity) {
      case CollectibleRarity.epic:
        return 'ÉPICO';
      case CollectibleRarity.rare:
        return 'RARO';
      case CollectibleRarity.common:
        return 'COMÚN';
    }
  }
}
