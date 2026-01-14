import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/event_provider.dart';
import '../../providers/saved_event_provider.dart'; // ⚡ AGREGADO
import 'widgets/featured_event_card.dart';
import 'widgets/single_event_card.dart';
import 'widgets/this_week_events_list.dart';
import 'widgets/saved_events_carousel.dart';
import 'widgets/gradient_section_title.dart';

/// Home Screen profesional
/// ✅ A PRUEBA DE BOMBAS NUCLEARES
/// - Memory leak safe
/// - Lifecycle aware
/// - Timeout protected
/// - Pull-to-refresh optimizado
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isDisposed = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    
    // ✅ Listener de scroll con check de mounted
    _scrollController.addListener(_onScroll);
    
    // ✅ Listener de lifecycle
    WidgetsBinding.instance.addObserver(this);
    
    // 🔄 Smart Refresh al entrar (solo si cache expiró)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;
      
      _safeSmartRefresh();
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // ✅ Cuando la app vuelve del background
    if (state == AppLifecycleState.resumed) {
      if (_isDisposed || !mounted) return;
      
      debugPrint('🔄 [Home] App resumed, verificando cache...');
      _safeSmartRefresh();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================
  // SMART REFRESH NUCLEAR-PROOF
  // ============================================
  // ⚡ ESTRATEGIA:
  // 1. Cancelar timer anterior para evitar leaks
  // 2. Timeout de 18s en operación + 20s en timer backup
  // 3. Catch específico de TimeoutException
  // 4. Finally garantiza limpieza del timer
  // 5. No propagar errores (silent fail, provider ya maneja)

  Future<void> _safeSmartRefresh({bool force = false}) async {
    if (_isDisposed || !mounted) return;

    // ✅ Cancelar timer anterior si existe
    _refreshTimer?.cancel();

    try {
      // ✅ Ejecutar con timeout propio
      _refreshTimer = Timer(const Duration(seconds: 20), () {
        if (!_isDisposed) {
          debugPrint('⚠️ [Home] Timeout de smart refresh alcanzado');
        }
      });

      await smartRefreshEvents(ref, force: force).timeout(
        const Duration(seconds: 18),
        onTimeout: () {
          debugPrint('⚠️ [Home] Timeout en smartRefreshEvents');
        },
      );

      _refreshTimer?.cancel();
      
    } on TimeoutException catch (e) {
      debugPrint('⚠️ [Home] TimeoutException: $e');
    } catch (e) {
      debugPrint('❌ [Home] Error en smart refresh: $e');
    } finally {
      _refreshTimer?.cancel();
    }
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
  // PULL TO REFRESH
  // ============================================

  Future<void> _handlePullToRefresh() async {
    if (_isDisposed || !mounted) return;
    
    debugPrint('🔄 [Home] Pull-to-refresh triggered');
    
    try {
      // Force refresh (ignorar TTL) con timeout
      await _safeSmartRefresh(force: true);
    } catch (e) {
      debugPrint('❌ [Home] Error en pull-to-refresh: $e');
      // No mostrar error al usuario, el provider ya maneja errores
    }
  }

  // ============================================
  // CONTENT BUILDERS
  // ============================================

  Widget _buildContent(BuildContext context, List<Event> events) {
    if (events.isEmpty) {
      return _buildEmpty();
    }

    return SingleChildScrollView(
      controller: _scrollController,
      physics: AlwaysScrollableScrollPhysics(), // Para RefreshIndicator
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Espacio para el header fijo
          SizedBox(height: MediaQuery.of(context).padding.top + 60),

          // ✅ 1. Featured Event Card (destacado con container aesthetic)
          if (events.isNotEmpty) FeaturedEventCard(event: events.first),

          // ⚡ SPACING CONDICIONAL: Solo agregar si HAY eventos guardados
          Consumer(
            builder: (context, ref, child) {
              final savedEventsAsync = ref.watch(savedEventsProvider);
              final hasSavedEvents = savedEventsAsync.maybeWhen(
                data: (events) => events.isNotEmpty,
                orElse: () => false,
              );
              
              // Si hay guardados, agregar spacing
              return hasSavedEvents 
                  ? SizedBox(height: EvioSpacing.xl)
                  : SizedBox.shrink();
            },
          ),

          // ✅ 2. Guardados (eventos reales guardados por el usuario)
          // ⚡ Wrapper para manejar spacing condicional
          Consumer(
            builder: (context, ref, child) {
              final savedEventsAsync = ref.watch(savedEventsProvider);
              final hasSavedEvents = savedEventsAsync.maybeWhen(
                data: (events) => events.isNotEmpty,
                orElse: () => false,
              );
              
              return Column(
                children: [
                  SavedEventsCarousel(),
                  if (hasSavedEvents) SizedBox(height: EvioSpacing.xl),
                ],
              );
            },
          ),

          // ✅ 3. Single Event Card (sin container, segundo evento)
          // ⚡ Agregar spacing solo si NO hay guardados
          Consumer(
            builder: (context, ref, child) {
              final savedEventsAsync = ref.watch(savedEventsProvider);
              final hasSavedEvents = savedEventsAsync.maybeWhen(
                data: (events) => events.isNotEmpty,
                orElse: () => false,
              );
              
              return Column(
                children: [
                  // Si NO hay guardados, agregar spacing antes del single card
                  if (!hasSavedEvents) SizedBox(height: EvioSpacing.xl),
                  if (events.length > 1) SingleEventCard(event: events[1]),
                ],
              );
            },
          ),

          SizedBox(height: EvioSpacing.xl), // ⚡ Reducido de xxl

          // ✅ 4. Esta Semana (filtrado automático)
          ThisWeekEventsList(events: events),

          SizedBox(height: EvioSpacing.xl), // ⚡ Reducido de xxl

          // ✅ 5. Todos los eventos restantes
          _buildRemainingEvents(events),

          SizedBox(height: 120), // Espacio para bottom nav
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
        SizedBox(height: 16),

        // Cards grandes
        ...remainingEvents.map((event) => Padding(
          padding: EdgeInsets.only(bottom: EvioSpacing.lg),
          child: SingleEventCard(event: event),
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
                        SizedBox(width: EvioSpacing.xs),

                        // Avatar
                        GestureDetector(
                          onTap: () {
                            if (_isDisposed || !mounted) return;
                            context.go('/profile');
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: EvioFanColors.surface,
                            child: Icon(
                              Icons.person_rounded,
                              color: EvioFanColors.mutedForeground,
                              size: 24,
                            ),
                          ),
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
