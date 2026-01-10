import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:evio_core/evio_core.dart';

/// Preview en vivo del evento exactamente como se ve en evio_fan
class LivePreviewCard extends StatelessWidget {
  final String title;
  final String mainArtist;
  final DateTime date;
  final String venue;
  final String city;
  final String? description;
  final String? organizerName;
  final List<LineupArtist> lineup;
  final List<TicketCategory> categories;
  final Uint8List? imageBytes;

  const LivePreviewCard({
    required this.title,
    required this.mainArtist,
    required this.date,
    required this.venue,
    required this.city,
    this.description,
    this.organizerName,
    required this.lineup,
    required this.categories,
    this.imageBytes,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 375, // Ancho iPhone estándar
      constraints: const BoxConstraints(maxHeight: 750),
      decoration: BoxDecoration(
        color: EvioFanColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 50,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
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
                          if (categories.isNotEmpty) ...[
                            SizedBox(height: EvioSpacing.xl),
                            _buildTickets(),
                          ],
                          SizedBox(height: EvioSpacing.xl),
                          _buildLocation(),
                          SizedBox(height: EvioSpacing.xl),
                          _buildProducer(),
                          SizedBox(height: 100),
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
      height: 350,
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
          
          // GRADIENT OVERLAY - Exacto al real
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),
          
          // Back button
          Positioned(
            top: 40,
            left: EvioSpacing.md,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
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
                  title.isEmpty 
                    ? 'Título del evento' 
                    : '$title${venue.isNotEmpty ? " @ $venue" : ""}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
            fontSize: 18,
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
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: EvioFanColors.foreground,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        Wrap(
          spacing: EvioSpacing.lg,
          runSpacing: EvioSpacing.lg,
          children: lineup.take(8).map((artist) {
            final hasImage = artist.imageUrl != null && artist.imageUrl!.isNotEmpty;
            
            return Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: artist.isHeadliner
                      ? EvioFanColors.primary
                      : EvioFanColors.card,
                  backgroundImage: hasImage 
                      ? NetworkImage(artist.imageUrl!) 
                      : null,
                  child: !hasImage
                      ? Text(
                          artist.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: artist.isHeadliner
                                ? Colors.black
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
    // Filtrar solo categorías con tiers activos
    final categoriesWithActiveTiers = categories
        .where((cat) => cat.tiers.any((t) => t.isActive))
        .toList();
    
    if (categoriesWithActiveTiers.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
        
        // Mostrar cada categoría con sus tiers activos
        ...categoriesWithActiveTiers.asMap().entries.map((entry) {
          final category = entry.value;
          final activeTiers = category.tiers.where((t) => t.isActive).toList();
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📌 Header de categoría (mismo estilo que evio_fan)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: EvioFanColors.foreground,
                    ),
                  ),
                  if (category.maxPerPurchase != null)
                    Text(
                      'Máx. ${category.maxPerPurchase} por persona',
                      style: TextStyle(
                        fontSize: 11,
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                ],
              ),
              
              SizedBox(height: EvioSpacing.sm),
              
              // 🎫 Tiers - Estilo EXACTO de evio_fan
              ...activeTiers.map((tier) {
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
                              tier.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: EvioFanColors.foreground,
                              ),
                            ),
                          ),
                          // Precio
                          Text(
                            '\$ ${tier.price ~/ 100} ARS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      
                      // Descripción + Botones
                      if (tier.description != null && tier.description!.isNotEmpty) ...[
                        SizedBox(height: EvioSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Descripción
                            Expanded(
                              flex: 2,
                              child: Text(
                                tier.description!,
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
                                const Text(
                                  '0',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
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
                                  child: const Icon(
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
                    ],
                  ),
                );
              }).toList(),
              
              // Espacio entre categorías
              if (entry.key < categoriesWithActiveTiers.length - 1)
                SizedBox(height: EvioSpacing.lg),
            ],
          );
        }).toList(),
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
                fontSize: 18,
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
                venue.isEmpty ? 'Nombre del lugar' : venue,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: EvioFanColors.foreground,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.md),
        // Placeholder del mapa
        ClipRRect(
          borderRadius: BorderRadius.circular(EvioRadius.card),
          child: Container(
            height: 160,
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
    );
  }
  
  Widget _buildProducer() {
    final producerName = organizerName ?? 'Productora';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Organizado por',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: EvioFanColors.foreground,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        Container(
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
                child: Center(
                  child: Text(
                    producerName[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(width: EvioSpacing.md),
              Expanded(
                child: Text(
                  producerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EvioFanColors.foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Comprar tickets',
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
