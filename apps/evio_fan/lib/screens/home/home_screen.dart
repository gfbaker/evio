import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/event_provider.dart';
import 'widgets/hero_event_section.dart';
import 'widgets/featured_carousel.dart';
import 'widgets/upcoming_events_list.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isDisposed = false;

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
      // No hacer await aquí para no bloquear el build
      smartRefreshEvents(ref).catchError((e) {
        debugPrint('⚠️ [Home] Error en smart refresh: $e');
      });
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // ✅ Cuando la app vuelve del background
    if (state == AppLifecycleState.resumed) {
      if (_isDisposed || !mounted) return;
      
      debugPrint('🔄 [Home] App resumed, verificando cache...');
      
      // Refresh solo si el cache expiró (con manejo de errores)
      smartRefreshEvents(ref).catchError((e) {
        debugPrint('⚠️ [Home] Error en smart refresh: $e');
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // ✅ Check mounted antes de setState
    if (_isDisposed || !mounted) return;
    
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Usar eventsProvider (ya pre-cacheado en splash)
    final eventsAsync = ref.watch(eventsProvider);

    return Scaffold(
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: RefreshIndicator(
        onRefresh: () async {
          if (_isDisposed || !mounted) return;
          
          debugPrint('🔄 [Home] Pull-to-refresh triggered');
          
          try {
            // Force refresh (ignorar TTL) con timeout
            await smartRefreshEvents(ref, force: true).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                debugPrint('⚠️ [Home] Timeout en pull-to-refresh');
              },
            );
          } catch (e) {
            debugPrint('❌ [Home] Error en pull-to-refresh: $e');
            // No mostrar error al usuario, el provider ya maneja errores
          }
        },
        color: EvioFanColors.primary,
        backgroundColor: EvioFanColors.surface,
        child: Stack(
          children: [
            // ✅ CONTENT: Con padding top para el header
            eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No hay eventos disponibles',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Espacio para el header fijo
                      SizedBox(height: MediaQuery.of(context).padding.top + 60),

                      // Hero Section (Evento destacado grande)
                      HeroEventSection(event: events.first),

                      SizedBox(height: 32),

                      // Sección "Destacados" (Carousel horizontal)
                      FeaturedCarousel(events: events.take(6).toList()),

                      SizedBox(height: 32),

                      // Sección "Próximos" (Lista vertical)
                      UpcomingEventsList(
                        events: events.where((e) => !e.isPast).take(10).toList(),
                      ),

                      SizedBox(height: 100), // Espacio para bottom nav
                    ],
                  ),
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: EvioFanColors.primary),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Error al cargar eventos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(eventsProvider);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EvioFanColors.primary,
                          foregroundColor: EvioFanColors.primaryForeground,
                        ),
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // ✅ HEADER: Sticky con animaciones
            _buildAnimatedHeader(context),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildAnimatedHeader(BuildContext context) {
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
                padding: EdgeInsets.symmetric(horizontal: 16),
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
                          onPressed: () => context.go('/search'),
                          icon: Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 8),

                        // Avatar
                        GestureDetector(
                          onTap: () => context.go('/profile'),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF252525),
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.grey[400],
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
