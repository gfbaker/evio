import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:evio_core/evio_core.dart';

class LivePreviewCard extends StatelessWidget {
  final String title;
  final DateTime date;
  final String venue;
  final String city;
  final String price;
  final Uint8List? imageBytes;

  const LivePreviewCard({
    required this.title,
    required this.date,
    required this.venue,
    required this.city,
    required this.price,
    this.imageBytes,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Image
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              image: imageBytes != null
                  ? DecorationImage(
                      image: MemoryImage(imageBytes!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Gradient overlay
                if (imageBytes != null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                        ),
                      ),
                    ),
                  ),

                // Placeholder
                if (imageBytes == null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, color: Colors.white24, size: 48),
                        SizedBox(height: EvioSpacing.xs),
                        Text(
                          'Sin Imagen',
                          style: TextStyle(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ),
                  ),

                // Title
                Positioned(
                  bottom: EvioSpacing.md,
                  left: EvioSpacing.md,
                  right: EvioSpacing.md,
                  child: Text(
                    title.isEmpty ? 'Nombre del Evento' : title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(EvioSpacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.calendar_today,
                        title: 'Fecha',
                        value: DateFormat('d MMM yyyy').format(date),
                      ),
                    ),
                    SizedBox(width: EvioSpacing.md),
                    Expanded(
                      child: _InfoRow(
                        icon: Icons.access_time,
                        title: 'Hora',
                        value: DateFormat('HH:mm').format(date),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: EvioSpacing.md),
                _InfoRow(
                  icon: Icons.location_on,
                  title: 'Ubicación',
                  value: venue.isEmpty ? 'Venue' : venue,
                  subtitle: city,
                ),
                SizedBox(height: EvioSpacing.lg),
                Divider(height: 1, color: Colors.grey.shade100),
                SizedBox(height: EvioSpacing.md),

                // Price + CTA
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Precio desde',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          price.isEmpty ? '\$0' : '\$$price',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.confirmation_number, size: 14),
                      label: Text(
                        'Comprar Entradas',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: EvioSpacing.md,
                          vertical: EvioSpacing.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            EvioRadius.button,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(EvioSpacing.xs),
          decoration: BoxDecoration(
            color: Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(EvioRadius.button),
          ),
          child: Icon(icon, size: 16, color: Colors.black87),
        ),
        SizedBox(width: EvioSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(
                  subtitle!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
