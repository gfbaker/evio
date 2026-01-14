import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';

/// Carousel de eventos destacados (Hero Section)
/// ✅ Cards grandes con Hero animation
/// ✅ Indicadores de página
/// ✅ Auto-play opcional
class HeroCarousel extends StatefulWidget {
  final List<Event> events;

  const HeroCarousel({
    super.key,
    required this.events,
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final PageController _pageController = PageController(
    viewportFraction: 0.92, // Cards con peek del siguiente
  );
  Timer? _timer;
  int _currentPage = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_isDisposed || !mounted) return;

      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % widget.events.length;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carousel de cards (sin título)
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _pageController,
            padEnds: false,
            onPageChanged: (index) {
              if (_isDisposed || !mounted) return;
              setState(() => _currentPage = index);
            },
            itemCount: widget.events.length,
            itemBuilder: (context, index) {
              final event = widget.events[index];
              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? EvioSpacing.lg : EvioSpacing.xs,
                  right: index == widget.events.length - 1 
                      ? EvioSpacing.lg 
                      : EvioSpacing.xs,
                ),
                child: _HeroEventCard(event: event),
              );
            },
          ),
        ),


      ],
    );
  }
}

class _HeroEventCard extends StatelessWidget {
  final Event event;

  const _HeroEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Container(
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(EvioRadius.card),
          child: Stack(
            children: [
              // ✅ Imagen principal (sin Hero)
              CachedEventImage(
                imageUrl: event.imageUrl,
                thumbnailUrl: event.thumbnailUrl,
                fullImageUrl: event.fullImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 380,
                memCacheHeight: 760,
              ),

              // ✅ Gradiente
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.4, 0.7, 1.0],
                  ),
                ),
              ),

              // Contenido overlay
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título
                    Text(
                      event.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: EvioSpacing.xs),

                    // Venue
                    Text(
                      event.venueName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: EvioSpacing.sm),

                    // Fecha y ciudad
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: EvioFanColors.primary,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _formatDate(event.startDatetime),
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        SizedBox(width: 12),
                        Icon(
                          Icons.location_on_rounded,
                          color: EvioFanColors.primary,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          event.city,
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];
    return '$dayName $day $month';
  }
}
