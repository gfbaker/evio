import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../../widgets/cached_event_image.dart';
import '../../../widgets/auth/auth_bottom_sheet.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/saved_events_provider.dart';

/// Hero section con animaciones coordinadas y sincronizadas
/// ✅ Un solo AnimationController para todo
/// ✅ Intervals precisos para secuencia limpia
class EventHeroSection extends ConsumerStatefulWidget {
  final Event event;
  final double height;
  final VoidCallback onBackPressed;

  const EventHeroSection({
    super.key,
    required this.event,
    required this.height,
    required this.onBackPressed,
  });

  @override
  ConsumerState<EventHeroSection> createState() => _EventHeroSectionState();
}

class _EventHeroSectionState extends ConsumerState<EventHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _imageOpacity;
  late Animation<double> _contentOpacity;
  late Animation<Offset> _contentSlide;
  late Animation<double> _buttonsOpacity;
  late Animation<double> _buttonsScale;

  @override
  void initState() {
    super.initState();

    // ⚡ Un solo controller para TODAS las animaciones
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // 📸 Imagen aparece primero (0.0 - 0.4)
    _imageOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    // 📝 Contenido aparece después (0.25 - 0.7)
    _contentOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.25, 0.7, curve: Curves.easeOut),
      ),
    );

    _contentSlide = Tween<Offset>(
      begin: Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.25, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // 🔘 Botones aparecen al final (0.4 - 0.8)
    _buttonsOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _buttonsScale = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.4, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // ⚡ Iniciar inmediatamente
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // 📸 Background Image con fade in
          Positioned.fill(
            child: FadeTransition(
              opacity: _imageOpacity,
              child: CachedEventImage(
                imageUrl: widget.event.imageUrl,
                thumbnailUrl: widget.event.thumbnailUrl,
                fullImageUrl: widget.event.fullImageUrl,
                fit: BoxFit.cover,
                height: widget.height,
                memCacheHeight: 1000,
              ),
            ),
          ),

          // 🌫️ Gradient Overlay (aparece con la imagen)
          Positioned.fill(
            child: FadeTransition(
              opacity: _imageOpacity,
              child: Container(
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
            ),
          ),

          // 🔙 Back Button (con scale + fade)
          Positioned(
            top: MediaQuery.of(context).padding.top + EvioSpacing.md,
            left: EvioSpacing.md,
            child: FadeTransition(
              opacity: _buttonsOpacity,
              child: ScaleTransition(
                scale: _buttonsScale,
                child: _buildBackButton(widget.onBackPressed),
              ),
            ),
          ),

          // 🔖 Bookmark Button (con scale + fade)
          Positioned(
            top: MediaQuery.of(context).padding.top + EvioSpacing.md,
            right: EvioSpacing.md,
            child: FadeTransition(
              opacity: _buttonsOpacity,
              child: ScaleTransition(
                scale: _buttonsScale,
                child: _buildBookmarkButton(),
              ),
            ),
          ),

          // 📝 Event Info (fade + slide)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _contentOpacity,
              child: SlideTransition(
                position: _contentSlide,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.event.title} @ ${widget.event.venueName}',
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
                    Container(
                      width: 100,
                      height: 3,
                      decoration: BoxDecoration(
                        color: EvioFanColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          color: EvioFanColors.primary,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _formatDate(widget.event.startDatetime),
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: EvioFanColors.primary,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.event.city,
                            style: TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: EvioFanColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(Icons.arrow_back, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildBookmarkButton() {
    // ✅ Verificar si hay usuario autenticado
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final savedIdsAsync = ref.watch(savedEventsNotifierProvider);
    
    // Si no está autenticado, mostrar botón que abre auth modal
    if (!isAuthenticated) {
      return GestureDetector(
        onTap: () {
          // Mostrar modal de autenticación
          AuthBottomSheet.show(
            context, 
            redirectTo: '/event/${widget.event.id}',
          );
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: EvioFanColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.bookmark_border,
            color: Colors.white,
            size: 22,
          ),
        ),
      );
    }
    
    // Usuario autenticado - mostrar estado real
    return savedIdsAsync.when(
      data: (savedIds) {
        final isSaved = savedIds.contains(widget.event.id);
        
        return GestureDetector(
          onTap: () {
            // ⚡ Toggle inmediato
            ref
                .read(savedEventsNotifierProvider.notifier)
                .toggleSave(widget.event.id);
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSaved 
                  ? EvioFanColors.primary.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: EvioFanColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? Colors.black : Colors.white,
              size: 22,
            ),
          ),
        );
      },
      loading: () => Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: EvioFanColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
        ),
      ),
      error: (_, __) => GestureDetector(
        onTap: () {
          // En caso de error, intentar mostrar auth
          AuthBottomSheet.show(
            context, 
            redirectTo: '/event/${widget.event.id}',
          );
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(
              color: EvioFanColors.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.bookmark_border,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    final dayName = days[date.weekday % 7];
    final day = date.day;
    final month = months[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$dayName, $day $month • $hour:$minute';
  }
}
