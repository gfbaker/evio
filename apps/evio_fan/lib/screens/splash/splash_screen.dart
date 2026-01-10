import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/event_provider.dart';

/// Splash screen con prefetch inteligente basado en cache
/// - Si hay cache: Skip splash, navegación directa
/// - Sin cache: Mostrar splash + prefetch eventos
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  // ✅ Flags de seguridad
  bool _isDisposed = false;
  bool _hasCheckedCache = false;
  bool _isNavigating = false; // Prevenir múltiples navegaciones

  @override
  void initState() {
    super.initState();

    // Animación de scale para el logo
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar cache UNA SOLA VEZ
    if (!_hasCheckedCache) {
      _hasCheckedCache = true;
      
      // Leer cache de eventos de forma segura
      try {
        final eventsCache = ref.read(eventsProvider);
        final hasCache = eventsCache.hasValue && 
                         eventsCache.value != null && 
                         eventsCache.value!.isNotEmpty;
        
        if (hasCache) {
          // ✅ HAY CACHE -> Skip splash
          debugPrint('✅ [Splash] Cache detectado (${eventsCache.value!.length} eventos), skip splash');
          _navigateToHome();
          
          // Retornar scaffold vacío mientras redirige
          return Scaffold(
            backgroundColor: EvioFanColors.background,
            body: const SizedBox.shrink(),
          );
        } else {
          // ❌ NO HAY CACHE -> Mostrar splash con prefetch
          debugPrint('🚀 [Splash] Sin cache, mostrando splash con prefetch');
          _preloadData();
        }
      } catch (e) {
        // En caso de error leyendo el cache, mostrar splash igual
        debugPrint('⚠️ [Splash] Error leyendo cache: $e, mostrando splash');
        _preloadData();
      }
    }
    
    // Mostrar splash animado
    return Scaffold(
      backgroundColor: EvioFanColors.background,
      body: ScaleTransition(
        scale: _scaleAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de Evio
              Text(
                'EVIO',
                style: TextStyle(
                  color: EvioFanColors.primary,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 12,
                ),
              ),

              SizedBox(height: EvioSpacing.xs),

              // Tagline
              Text(
                'Electronic Events',
                style: TextStyle(
                  color: EvioFanColors.mutedForeground,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: EvioSpacing.xxl),

              // Loading indicator
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: EvioFanColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // PREFETCH CON MANEJO DE ERRORES ROBUSTO
  // ============================================

  Future<void> _preloadData() async {
    if (_isDisposed) return;

    try {
      debugPrint('🚀 [Splash] Iniciando prefetch...');
      final startTime = DateTime.now();

      // Prefetch eventos con timeout de seguridad
      final prefetchFuture = ref.read(eventsProvider.future).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('⚠️ [Splash] Timeout en prefetch, continuando sin datos');
          return <Event>[];
        },
      );
      
      // Esperar mínimo 1.5s para UX (mostrar splash completo)
      await Future.wait([
        prefetchFuture,
        Future.delayed(const Duration(milliseconds: 1500)),
      ]);

      final elapsed = DateTime.now().difference(startTime);
      debugPrint('✅ [Splash] Prefetch completado en ${elapsed.inMilliseconds}ms');

      // ✅ Verificar estado antes de navegar
      if (_isDisposed || !mounted) {
        debugPrint('⚠️ [Splash] Widget disposed/unmounted, cancelando navegación');
        return;
      }

      // Navegar a Home
      _navigateToHome();
      
    } catch (e, stackTrace) {
      debugPrint('❌ [Splash] Error en prefetch: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // ✅ Navegar igual aunque falle
      if (!_isDisposed && mounted) {
        _navigateToHome();
      }
    }
  }

  // ============================================
  // NAVEGACIÓN SEGURA (previene múltiples llamadas)
  // ============================================

  void _navigateToHome() {
    // ✅ Prevenir múltiples navegaciones
    if (_isNavigating) {
      debugPrint('⚠️ [Splash] Navegación ya en progreso, ignorando');
      return;
    }

    if (_isDisposed || !mounted) {
      debugPrint('⚠️ [Splash] Widget disposed/unmounted, cancelando navegación');
      return;
    }

    _isNavigating = true;

    // Navegar en el siguiente frame para evitar race conditions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;
      
      try {
        context.go('/home');
        debugPrint('✅ [Splash] Navegación a /home exitosa');
      } catch (e) {
        debugPrint('❌ [Splash] Error navegando: $e');
        // Reset flag para reintentar si falla
        _isNavigating = false;
      }
    });
  }
}
