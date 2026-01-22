import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/event_provider.dart';
import '../../providers/saved_event_provider.dart'; // ⚡ AGREGADO
import '../../providers/notification_provider.dart';
import '../../widgets/notification_bell.dart';
import 'widgets/event_card.dart';
import 'widgets/this_week_events_list.dart';
import 'widgets/saved_events_carousel.dart';
import 'widgets/gradient_section_title.dart';

/// Home Screen - Simplificado siguiendo principios KISS
/// ✅ Confía en Riverpod para cache/refresh
/// ✅ Código predecible y explicable en 10 segundos
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isDisposed = false;

  // Espacio para bottom nav
  static const _bottomNavSpace = 120.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Inicializar notificaciones (una sola vez)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(notificationProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================
  // SCROLL LISTENER
  // ============================================

  void _onScroll() {
    // ✅ Check mounted antes de setState
    if (_isDisposed || !mounted) return;
    
    final newOffset = _scrollController.offset;
    
    // ✅ Solo actualizar si cambió significativamente (optimización)
    if ((newOffset - _scrollOffset).abs() > 5) {
      setState(() {
        _scrollOffset = newOffset;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Usar eventsProvider (ya pre-cacheado en splash)
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: RefreshIndicator(
          onRefresh: _handlePullToRefresh,
          color: EvioFanColors.primary,
          backgroundColor: EvioFanColors.surface,
          child: Stack(
            children: [
              // ✅ CONTENT
              eventsAsync.when(
                data: (events) => _buildContent(context, events),
                loading: () => _buildLoading(),
                error: (error, stack) => _buildError(error, stack),
              ),
              
              // ✅ HEADER: Sticky con animaciones
              _buildAnimatedHeader(context),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PULL TO REFRESH - Confía en el provider
  // ============================================

  Future<void> _handlePullToRefresh() async {
    if (_isDisposed || !mounted) return;
    // Invalidar = Riverpod hace refetch automático
    ref.invalidate(eventsProvider);
  }

  // ============================================
  // CONTENT BUILDERS
  // ============================================

  Widget _buildContent(BuildContext context, List<Event> events) {
    if (events.isEmpty) return _buildEmpty();

    // ✅ UN solo watch - código predecible
    final savedEventsAsync = ref.watch(savedEventsProvider);
    final hasSavedEvents = savedEventsAsync.maybeWhen(
      data: (saved) => saved.isNotEmpty,
      orElse: () => false,
    );

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Espacio para header fijo
          SizedBox(height: MediaQuery.of(context).padding.top + 60),

          // 1. Featured
          EventCard(event: events.first, isFeatured: true),
          SizedBox(height: EvioSpacing.xl),

          // 2. Guardados (si hay)
          if (hasSavedEvents) ...[
            SavedEventsCarousel(),
            SizedBox(height: EvioSpacing.xl),
          ],

          // 3. Segundo evento (si hay)
          if (events.length > 1) ...[
            EventCard(event: events[1]),
            SizedBox(height: EvioSpacing.xl),
          ],

          // 4. Esta Semana
          ThisWeekEventsList(events: events),
          SizedBox(height: EvioSpacing.xl),

          // 5. Más eventos
          _buildRemainingEvents(events),

          SizedBox(height: _bottomNavSpace),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: EvioFanColors.primary),
          SizedBox(height: EvioSpacing.lg),
          Text(
            'Cargando eventos...',
            style: EvioTypography.bodyMedium.copyWith(
              color: EvioFanColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(EvioSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 64,
              color: EvioFanColors.mutedForeground,
            ),
            SizedBox(height: EvioSpacing.lg),
            Text(
              'No hay eventos disponibles',
              style: EvioTypography.h3.copyWith(
                color: EvioFanColors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: EvioSpacing.sm),
            Text(
              'Volvé más tarde para ver nuevos eventos',
              style: EvioTypography.bodyMedium.copyWith(
                color: EvioFanColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemainingEvents(List<Event> allEvents) {
    // Obtener eventos que NO están en:
    // - Featured (primero)
    // - Single card (segundo)
    // - Esta semana (ya filtrados en ThisWeekEventsList)
    
    // Para simplificar, mostramos desde el 3er evento en adelante
    final remainingEvents = allEvents.length > 2 
        ? allEvents.sublist(2) 
        : <Event>[];
    
    if (remainingEvents.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con gradiente
        Padding(
          padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md), // ⚡ Alineado
          child: GradientSectionTitle(text: 'Más Eventos'),
        ),
        SizedBox(height: EvioSpacing.md),

        // Cards estilo Dice
        ...remainingEvents.map((event) => Padding(
          padding: EdgeInsets.only(bottom: EvioSpacing.lg),
          child: EventCard(event: event),
        )),
      ],
    );
  }

  Widget _buildError(Object error, StackTrace? stack) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(EvioSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: EvioFanColors.error,
            ),
            SizedBox(height: EvioSpacing.lg),
            Text(
              'Error al cargar eventos',
              style: EvioTypography.h3.copyWith(
                color: EvioFanColors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: EvioSpacing.sm),
            Text(
              'Intentá nuevamente en unos momentos',
              style: EvioTypography.bodyMedium.copyWith(
                color: EvioFanColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: EvioSpacing.xl),
            ElevatedButton(
              onPressed: () {
                if (_isDisposed || !mounted) return;
                ref.invalidate(eventsProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: EvioFanColors.primary,
                foregroundColor: EvioFanColors.primaryForeground,
                padding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.xl,
                  vertical: EvioSpacing.md,
                ),
              ),
              child: Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ANIMATED HEADER
  // ============================================

  Widget _buildAnimatedHeader(BuildContext context) {
    // ✅ Protección contra race conditions
    if (_isDisposed || !mounted) return const SizedBox.shrink();
    
    // Calcular opacidades basado en scroll
    final double logoOpacity = (_scrollOffset / 50).clamp(0.0, 1.0);
    final double bgOpacity = 1.0 - (_scrollOffset / 100).clamp(0.0, 0.3);
    final bool showBlur = _scrollOffset > 20;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: showBlur
              ? ImageFilter.blur(sigmaX: 10, sigmaY: 10)
              : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: EvioFanColors.background.withValues(alpha: bgOpacity),
              border: Border(
                bottom: BorderSide(
                  color: _scrollOffset > 20
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                height: 60,
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo EVIO con fade
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: 1.0 - logoOpacity,
                      child: Text(
                        'EVIO',
                        style: TextStyle(
                          color: EvioFanColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ),

                    // Icons (siempre visibles)
                    Row(
                      children: [
                        // Search icon
                        IconButton(
                          onPressed: () {
                            if (_isDisposed || !mounted) return;
                            context.go('/search');
                          },
                          icon: Icon(
                            Icons.search_rounded,
                            color: EvioFanColors.foreground,
                            size: 28,
                          ),
                        ),

                        // Notification bell
                        NotificationBell(
                          iconColor: EvioFanColors.foreground,
                          iconSize: 26,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
