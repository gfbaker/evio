import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class EventLineup extends StatelessWidget {
  final List<LineupArtist> lineup;

  const EventLineup({super.key, required this.lineup});

  @override
  Widget build(BuildContext context) {
    if (lineup.isEmpty) return const SizedBox.shrink();

    final headliners = lineup.where((a) => a.isHeadliner).toList();
    final supports = lineup.where((a) => !a.isHeadliner).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.music_note,
          color: EvioFanColors.primary,
          size: EvioSpacing.iconM,
        ),
        SizedBox(width: EvioSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LINE-UP',
                style: TextStyle(
                  color: EvioFanColors.mutedForeground.withValues(alpha: 0.6),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: EvioSpacing.xs),

              // Headliners (destacados)
              ...headliners.map(
                (artist) => Padding(
                  padding: EdgeInsets.only(bottom: EvioSpacing.xxs),
                  child: Text(
                    artist.name.toUpperCase(),
                    style: TextStyle(
                      color: EvioFanColors.foreground,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                ),
              ),

              if (supports.isNotEmpty) SizedBox(height: EvioSpacing.xs),

              // Support (secundarios)
              ...supports.map(
                (artist) => Padding(
                  padding: EdgeInsets.only(bottom: EvioSpacing.xxs),
                  child: Text(
                    artist.name,
                    style: TextStyle(
                      color: EvioFanColors.mutedForeground,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
