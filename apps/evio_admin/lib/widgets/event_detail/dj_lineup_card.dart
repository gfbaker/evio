import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'detail_card.dart';

/// Card de Line-up de DJs.
class DjLineupCard extends StatelessWidget {
  final Event event;

  const DjLineupCard({required this.event, super.key});

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Line-up',
      icon: Icons.music_note,
      child: event.lineup.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(EvioSpacing.lg),
                child: Text(
                  'No hay artistas en el line-up',
                  style: TextStyle(color: EvioLightColors.mutedForeground),
                ),
              ),
            )
          : Column(
              children: event.lineup
                  .map((artist) => _ArtistItem(artist: artist))
                  .toList(),
            ),
    );
  }
}

class _ArtistItem extends StatelessWidget {
  final LineupArtist artist;

  const _ArtistItem({required this.artist});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.sm),
      padding: EdgeInsets.all(EvioSpacing.sm),
      decoration: BoxDecoration(
        color: EvioLightColors.surface,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Row(
        children: [
          // Avatar
          if (artist.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                artist.imageUrl!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ArtistPlaceholder(),
              ),
            )
          else
            _ArtistPlaceholder(),
          
          SizedBox(width: EvioSpacing.sm),
          
          // Nombre
          Expanded(
            child: Text(
              artist.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: EvioLightColors.textPrimary,
              ),
            ),
          ),
          
          // Badge Headliner
          if (artist.isHeadliner)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: EvioLightColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Headliner',
                style: TextStyle(
                  color: EvioLightColors.accentForeground,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ArtistPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: EvioLightColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.person,
        size: 24,
        color: EvioLightColors.accent,
      ),
    );
  }
}
