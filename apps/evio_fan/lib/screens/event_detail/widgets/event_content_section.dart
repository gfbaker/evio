import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../../providers/spotify_provider.dart';
import '../../../widgets/shimmer/tickets_shimmer.dart';
import 'event_location_section.dart';
import 'event_producer_section.dart';

class EventContentSection extends ConsumerStatefulWidget {
  final Event event;
  final AsyncValue<List<TicketType>> ticketsAsync;
  final String? selectedTierId;
  final Map<String, int> quantities;
  final Function(String?) onTierSelected;
  final Function(String, int) onQuantityChanged;

  const EventContentSection({
    super.key,
    required this.event,
    required this.ticketsAsync,
    required this.selectedTierId,
    required this.quantities,
    required this.onTierSelected,
    required this.onQuantityChanged,
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
              _buildTicketsSection(widget.ticketsAsync),
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

  Widget _buildTicketsSection(AsyncValue<List<TicketType>> ticketsAsync) {
    return ticketsAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No hay entradas disponibles',
                style: TextStyle(color: EvioFanColors.mutedForeground),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecciona tus Tickets',
              style: TextStyle(
                color: EvioFanColors.foreground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: EvioSpacing.md),
            ...tickets.map(
              (ticket) => Padding(
                padding: EdgeInsets.only(bottom: EvioSpacing.lg),
                child: _buildTicketRow(ticket),
              ),
            ),
          ],
        );
      },
      loading: () => const TicketsShimmer(), // ✅ Shimmer en lugar de spinner
      error: (e, st) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Text(
                'Error cargando entradas',
                style: TextStyle(color: EvioFanColors.mutedForeground),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  e.toString(),
                  style: TextStyle(color: EvioFanColors.error, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketRow(TicketType ticket) {
    final quantity = widget.quantities[ticket.id] ?? 0;
    final isSoldOut = ticket.isSoldOut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                ticket.name,
                style: TextStyle(
                  color: EvioFanColors.foreground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '\$${(ticket.price / 100).toStringAsFixed(0)} ARS',
              style: TextStyle(
                color: EvioFanColors.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSoldOut
                  ? 'Agotado'
                  : 'Máx. ${ticket.maxPerPurchase ?? 10} por persona',
              style: TextStyle(
                color: isSoldOut ? Colors.red : EvioFanColors.mutedForeground,
                fontSize: 12,
              ),
            ),
            if (!isSoldOut)
              Row(
                children: [
                  _buildQuantityButton(
                    icon: Icons.remove,
                    onTap: quantity > 0
                        ? () => widget.onQuantityChanged(ticket.id, quantity - 1)
                        : null,
                    isPrimary: false,
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$quantity',
                      style: TextStyle(
                        color: EvioFanColors.foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  _buildQuantityButton(
                    icon: Icons.add,
                    onTap:
                        quantity <
                            (ticket.maxPerPurchase ?? ticket.availableQuantity)
                        ? () => widget.onQuantityChanged(ticket.id, quantity + 1)
                        : null,
                    isPrimary: true,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback? onTap,
    bool isPrimary = false,
  }) {
    final isDisabled = onTap == null;
    return GestureDetector(
      onTap: isDisabled ? null : () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPrimary && !isDisabled
              ? EvioFanColors.primary
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDisabled
                ? EvioFanColors.border
                : (isPrimary ? EvioFanColors.primary : EvioFanColors.primary),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isDisabled
              ? EvioFanColors.mutedForeground
              : (isPrimary ? Colors.black : EvioFanColors.primary),
        ),
      ),
    );
  }
}
