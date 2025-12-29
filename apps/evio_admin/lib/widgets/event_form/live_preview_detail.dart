import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'package:intl/intl.dart';

class LivePreviewDetail extends StatelessWidget {
  final String title;
  final String mainArtist;
  final DateTime date;
  final String venueName;
  final String city;
  final String? description;
  final List<LineupArtist> lineup;
  final List<TicketType> ticketTypes;
  final bool showAllTicketTypes;
  final List<String> features;
  final Uint8List? imageBytes;
  final String? videoUrl;
  final double? lat;
  final double? lng;

  const LivePreviewDetail({
    required this.title,
    required this.mainArtist,
    required this.date,
    required this.venueName,
    required this.city,
    this.description,
    required this.lineup,
    required this.ticketTypes,
    this.showAllTicketTypes = false,
    required this.features,
    this.imageBytes,
    this.videoUrl,
    this.lat,
    this.lng,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EvioFanColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHero(),
                    Padding(
                      padding: EdgeInsets.all(EvioSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateLocation(),
                          if (description != null && description!.isNotEmpty) ...[
                            SizedBox(height: EvioSpacing.xl),
                            _buildDescription(),
                          ],
                          if (lineup.isNotEmpty) ...[
                            SizedBox(height: EvioSpacing.xl),
                            _buildLineup(),
                          ],
                          if (ticketTypes.isNotEmpty) ...[
                            SizedBox(height: EvioSpacing.xl),
                            _buildTickets(),
                          ],
                          SizedBox(height: EvioSpacing.xl),
                          _buildLocation(),
                          if (features.isNotEmpty) ...[
                            SizedBox(height: EvioSpacing.xl),
                            _buildFeatures(),
                          ],
                          if (videoUrl != null && videoUrl!.isNotEmpty) ...[
                            SizedBox(height: EvioSpacing.xl),
                            _buildVideo(),
                          ],
                          SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildCTA(),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 450,
      child: Stack(
        children: [
          // Background Image
          if (imageBytes != null)
            Positioned.fill(
              child: Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
              ),
            )
          else
            Positioned.fill(
              child: Container(
                color: Colors.grey.shade800,
                child: Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          
          // GRADIENT OVERLAY (IDÉNTICO AL REAL)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 40,
            left: EvioSpacing.md,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          
          // Title at bottom
          Positioned(
            bottom: EvioSpacing.xl,
            left: EvioSpacing.lg,
            right: EvioSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Título del evento' : '$title @ ${venueName.isNotEmpty ? venueName : "Venue"}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: EvioSpacing.xs),
                Container(
                  height: 3,
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [EvioFanColors.primary, EvioFanColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateLocation() {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: EvioFanColors.primary),
            SizedBox(width: EvioSpacing.sm),
            Text(
              DateFormat('EEE, d MMM • HH:mm', 'es').format(date),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: EvioFanColors.foreground,
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.sm),
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: EvioFanColors.primary),
            SizedBox(width: EvioSpacing.sm),
            Expanded(
              child: Text(
                city.isNotEmpty ? city : 'Ciudad',
                style: TextStyle(
                  fontSize: 15,
                  color: EvioFanColors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sobre el evento',
          style: TextStyle(
            fontSize: 18, // ✅ Reducido de 20
            fontWeight: FontWeight.bold,
            color: EvioFanColors.foreground,
          ),
        ),
        SizedBox(height: EvioSpacing.sm),
        Text(
          description!,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: EvioFanColors.mutedForeground,
          ),
        ),
      ],
    );
  }

  Widget _buildLineup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line Up',
          style: TextStyle(
            fontSize: 18, // ✅ Reducido de 20
            fontWeight: FontWeight.bold,
            color: EvioFanColors.foreground,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        Wrap(
          spacing: EvioSpacing.lg,
          runSpacing: EvioSpacing.lg,
          children: lineup.map((artist) {
            // TODO: Usar artist.imageUrl cuando esté disponible
            final hasSpotifyImage = artist.imageUrl != null && artist.imageUrl!.isNotEmpty;
            
            return Column(
              children: [
                CircleAvatar(
                  radius: 40, // Más pequeño (era 45)
                  backgroundColor: artist.isHeadliner
                      ? EvioFanColors.primary
                      : EvioFanColors.card,
                  backgroundImage: hasSpotifyImage 
                      ? NetworkImage(artist.imageUrl!) 
                      : null,
                  child: !hasSpotifyImage
                      ? Text(
                          artist.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: artist.isHeadliner
                                ? Colors.white
                                : EvioFanColors.primary,
                          ),
                        )
                      : null,
                ),
                SizedBox(height: EvioSpacing.xs),
                SizedBox(
                  width: 80,
                  child: Text(
                    artist.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: EvioFanColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTickets() {
    // Filtrar tandas según showAllTicketTypes (mismo comportamiento que evio_fan)
    final visibleTickets = showAllTicketTypes
        ? ticketTypes
        : ticketTypes.where((t) => t.isActive).toList();
    
    final activeTickets = visibleTickets.where((t) => t.isActive).toList();
    final inactiveTickets = visibleTickets.where((t) => !t.isActive).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecciona tus Tickets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: EvioFanColors.foreground,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        
        // Tandas activas
        ...activeTickets.map((ticket) {
          return Container(
            margin: EdgeInsets.only(bottom: EvioSpacing.sm),
            padding: EdgeInsets.all(EvioSpacing.md),
            decoration: BoxDecoration(
              color: EvioFanColors.card,
              borderRadius: BorderRadius.circular(EvioRadius.card),
              border: Border.all(color: EvioFanColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row: Nombre + Precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Expanded(
                      child: Text(
                        ticket.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: EvioFanColors.foreground,
                        ),
                      ),
                    ),
                    // Precio
                    Text(
                      '\$ ${ticket.price ~/ 100} ARS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                
                // Descripción + Botones
                if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                  SizedBox(height: EvioSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Descripción
                      Expanded(
                        flex: 2,
                        child: Text(
                          ticket.description!,
                          style: TextStyle(
                            fontSize: 11,
                            color: EvioFanColors.mutedForeground,
                          ),
                        ),
                      ),
                      
                      SizedBox(width: EvioSpacing.sm),
                      
                      // Botones [-] 0 [+]
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Botón menos
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: EvioFanColors.muted,
                              shape: BoxShape.circle,
                              border: Border.all(color: EvioFanColors.border),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: EvioFanColors.mutedForeground,
                              size: 16,
                            ),
                          ),
                          
                          SizedBox(width: EvioSpacing.sm),
                          
                          // Cantidad
                          Text(
                            '0',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: EvioFanColors.foreground,
                            ),
                          ),
                          
                          SizedBox(width: EvioSpacing.sm),
                          
                          // Botón más
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: EvioFanColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
                
                // Máximo por persona (abajo de descripción)
                if (ticket.maxPerPurchase != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'Máx. ${ticket.maxPerPurchase} por persona',
                    style: TextStyle(
                      fontSize: 11,
                      color: EvioFanColors.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
        
        // Divisor + Tandas inactivas (si showAllTicketTypes = true)
        if (showAllTicketTypes && inactiveTickets.isNotEmpty) ...[
          SizedBox(height: EvioSpacing.lg),
          Row(
            children: [
              Expanded(child: Container(height: 1, color: EvioFanColors.border)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.sm),
                child: Text(
                  'PRÓXIMAMENTE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: EvioFanColors.mutedForeground,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: EvioFanColors.border)),
            ],
          ),
          SizedBox(height: EvioSpacing.md),
          
          ...inactiveTickets.map((ticket) {
            return Container(
              margin: EdgeInsets.only(bottom: EvioSpacing.sm),
              padding: EdgeInsets.all(EvioSpacing.md),
              decoration: BoxDecoration(
                color: EvioFanColors.muted.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(EvioRadius.card),
                border: Border.all(color: EvioFanColors.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: EvioFanColors.mutedForeground,
                          ),
                        ),
                        if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                          SizedBox(height: 4),
                          Text(
                            ticket.description!,
                            style: TextStyle(
                              fontSize: 11,
                              color: EvioFanColors.mutedForeground.withValues(alpha: 0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      'Próximamente',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                  SizedBox(width: EvioSpacing.xs),
                  Text(
                    '\$ ${ticket.price ~/ 100}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: EvioFanColors.mutedForeground.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ],
    );
  }

  Widget _buildLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ubicación',
              style: TextStyle(
                fontSize: 18, // ✅ Reducido de 20
                fontWeight: FontWeight.bold,
                color: EvioFanColors.foreground,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Cómo llegar',
                style: TextStyle(
                  color: EvioFanColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.sm),
        Row(
          children: [
            Icon(Icons.place, color: EvioFanColors.primary, size: 20),
            SizedBox(width: EvioSpacing.sm),
            Expanded(
              child: Text(
                venueName.isEmpty ? 'Nombre del lugar' : venueName,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: EvioFanColors.foreground,
                ),
              ),
            ),
          ],
        ),
        if (lat != null && lng != null) ...[
          SizedBox(height: EvioSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(EvioRadius.card),
            child: Container(
              height: 180,
              color: Colors.grey.shade800,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey.shade600),
                    SizedBox(height: 8),
                    Text(
                      'Mapa de ubicación',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Servicios',
          style: TextStyle(
            fontSize: 18, // ✅ Reducido de 20
            fontWeight: FontWeight.bold,
            color: EvioFanColors.foreground,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        Wrap(
          spacing: EvioSpacing.lg,
          runSpacing: EvioSpacing.md,
          children: features.map((feature) {
            IconData icon;
            switch (feature.toLowerCase()) {
              case 'estacionamiento':
                icon = Icons.local_parking;
                break;
              case 'bar':
                icon = Icons.local_bar;
                break;
              case 'aire acondicionado':
                icon = Icons.ac_unit;
                break;
              case 'accesibilidad':
                icon = Icons.accessible;
                break;
              case 'seguridad':
                icon = Icons.security;
                break;
              case 'vestuario':
                icon = Icons.checkroom;
                break;
              default:
                icon = Icons.check_circle;
            }

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: EvioFanColors.primary),
                SizedBox(width: 8),
                Text(
                  feature,
                  style: TextStyle(
                    fontSize: 14,
                    color: EvioFanColors.foreground,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVideo() {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioFanColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: EvioFanColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EvioFanColors.primary,
              borderRadius: BorderRadius.circular(EvioRadius.button),
            ),
            child: Icon(Icons.play_arrow, color: Colors.white, size: 28),
          ),
          SizedBox(width: EvioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Destacado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: EvioFanColors.foreground,
                  ),
                ),
                Text(
                  'Dale play para ver',
                  style: TextStyle(
                    fontSize: 13,
                    color: EvioFanColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA() {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.lg),
      decoration: BoxDecoration(
        color: EvioFanColors.background,
        border: Border(
          top: BorderSide(color: EvioFanColors.border, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: EvioFanColors.primary,
              foregroundColor: Colors.black, // ✅ LETRAS NEGRAS
              padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
              elevation: 0,
            ),
            child: Text(
              'Comprar tickets', // ✅ TEXTO CORRECTO
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
