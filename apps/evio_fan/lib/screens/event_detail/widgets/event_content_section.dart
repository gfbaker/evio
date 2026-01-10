import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../../providers/spotify_provider.dart';
import 'event_location_section.dart';
import 'event_producer_section.dart';
import 'category_tickets_section.dart';

class EventContentSection extends ConsumerStatefulWidget {
  final Event event;
  final AsyncValue<List<TicketCategory>> categoriesAsync;
  final Map<String, int> quantities;
  final Function(String, int) onQuantityChanged;
  final GlobalKey ticketsSectionKey; // ✅ Recibir el key

  const EventContentSection({
    super.key,
    required this.event,
    required this.categoriesAsync,
    required this.quantities,
    required this.onQuantityChanged,
    required this.ticketsSectionKey,
  });

  @override
  ConsumerState<EventContentSection> createState() => _EventContentSectionState();
}

class _EventContentSectionState extends ConsumerState<EventContentSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _controller,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: EvioSpacing.lg),
              if (widget.event.lineup.isNotEmpty) ...[
                _buildLineUpSection(ref),
                SizedBox(height: EvioSpacing.xl),
              ],
              if (widget.event.description != null && widget.event.description!.isNotEmpty) ...[
                _buildDescriptionSection(),
                SizedBox(height: EvioSpacing.xl),
              ],
              
              // ✅ NUEVO: Sección de tickets con clave para scroll
              Container(
                key: widget.ticketsSectionKey, // ✅ Agregar key aquí
                child: CategoryTicketsSection(
                  categoriesAsync: widget.categoriesAsync,
                  quantities: widget.quantities,
                  onQuantityChanged: widget.onQuantityChanged,
                ),
              ),
              
              SizedBox(height: EvioSpacing.xl),
              
              // Ubicación (Maps)
              EventLocationSection(event: widget.event),
              
              SizedBox(height: EvioSpacing.xl),
              
              // Productora
              EventProducerSection(event: widget.event),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineUpSection(WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line Up',
          style: TextStyle(
            color: EvioFanColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.event.lineup.length,
            separatorBuilder: (_, __) => SizedBox(width: EvioSpacing.md),
            itemBuilder: (context, index) {
              final artist = widget.event.lineup[index];
              return _buildArtistAvatar(artist, ref);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtistAvatar(LineupArtist artist, WidgetRef ref) {
    final imageAsync = ref.watch(artistImageProvider(artist.name));
    
    return Column(
      children: [
        // Siempre muestra algo (fallback o imagen real)
        imageAsync.maybeWhen(
          data: (imageUrl) {
            if (imageUrl != null) {
              return Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }
            return _buildFallbackAvatar(artist.name);
          },
          // Mientras carga O si hay error → fallback
          orElse: () => _buildFallbackAvatar(artist.name),
        ),
        SizedBox(height: EvioSpacing.xs),
        SizedBox(
          width: 70,
          child: Text(
            artist.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EvioFanColors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final words = name.split(' ');
    final initials = words.length > 1
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
    
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: EvioFanColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acerca del evento',
          style: TextStyle(
            color: EvioFanColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: EvioSpacing.sm),
        Text(
          widget.event.description!,
          style: TextStyle(
            color: EvioFanColors.mutedForeground,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
