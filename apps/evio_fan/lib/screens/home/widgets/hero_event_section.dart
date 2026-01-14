import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';

class HeroEventSection extends StatefulWidget {
  final Event event;

  const HeroEventSection({super.key, required this.event});

  @override
  State<HeroEventSection> createState() => _HeroEventSectionState();
}

class _HeroEventSectionState extends State<HeroEventSection> {
  final PageController _pageController = PageController();
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
    _timer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_isDisposed || !mounted) return;

      _currentPage = (_currentPage + 1) % 1;

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              if (!_isDisposed && mounted) {
                setState(() {
                  _currentPage = index;
                });
              }
            },
            children: [_buildEventPage(widget.event)],
          ),
        ],
      ),
    );
  }

  Widget _buildEventPage(Event event) {
    return GestureDetector(
      onTap: () => context.push('/event/${event.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ HERO: Imagen de fondo con caché
          Hero(
            tag: 'event-image-${event.id}',
            child: CachedEventImage(
              imageUrl: event.imageUrl,
              thumbnailUrl: event.thumbnailUrl,
              fullImageUrl: event.fullImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 400,
              memCacheHeight: 800,
            ),
          ),

          // ✅ HERO: Gradiente oscuro abajo (sincronizado)
          Hero(
            tag: 'event-gradient-${event.id}',
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: [0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Contenido
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Info del evento (izquierda)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        event.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),

                      // Ubicación
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${event.city} • ${event.venueName}',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),

                      // Fecha
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            _formatDate(event.startDatetime),
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                // Badge de fecha (derecha)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFD700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getDayNumber(event.startDatetime),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Text(
                        _getMonthShort(event.startDatetime),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = [
      'domingo',
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
    ];
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];

    return '$dayName $day de $month';
  }

  String _getDayNumber(DateTime date) {
    return date.day.toString();
  }

  String _getMonthShort(DateTime date) {
    final months = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC',
    ];
    return months[date.month - 1];
  }
}
