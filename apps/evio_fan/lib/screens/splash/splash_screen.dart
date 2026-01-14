import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/event_provider.dart';

/// Splash screen profesional con prefetch inteligente
/// ✅ A PRUEBA DE BOMBAS NUCLEARES
/// - Memory leak safe
/// - Race condition safe
/// - Timeout protected
/// - Error recovery
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  // ✅ CRITICAL: Flags de seguridad nuclear
  bool _isDisposed = false;
  bool _hasCheckedCache = false;
  bool _isNavigating = false;
  Timer? _navigationTimer; // Timeout de navegación

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

    // ✅ CRITICAL: Timeout de seguridad máximo (15s)
    // Si después de 15s no navegó, forzar navegación
    _navigationTimer = Timer(const Duration(seconds: 15), () {
      if (!_isNavigating && !_isDisposed && mounted) {
        debugPrint('⚠️ [Splash] Timeout de 15s alcanzado, forzando navegación');
        _navigateToHome();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Verificar cache UNA SOLA VEZ en el siguiente frame
    if (!_hasCheckedCache) {
      _hasCheckedCache = true;
      
      // Ejecutar en el siguiente frame para evitar setState durante build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed || !mounted) return;
        _checkCacheAndPrefetch();
      });
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
  // CACHE CHECK + PREFETCH
  // ============================================

  Future<void> _checkCacheAndPrefetch() async {
    if (_isDisposed || !mounted) return;

    try {
      // Leer cache de eventos de forma segura
      final eventsCache = ref.read(eventsProvider);
      final hasCache = eventsCache.hasValue && 
                       eventsCache.value != null && 
                       eventsCache.value!.isNotEmpty;
      
      if (hasCache) {
        // ✅ HAY CACHE -> Skip splash, navegación inmediata
        debugPrint('✅ [Splash] Cache detectado (${eventsCache.value!.length} eventos), skip splash');
        
        // Pequeño delay para que se vea el splash (UX)
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (_isDisposed || !mounted) return;
        _navigateToHome();
      } else {
        // ❌ NO HAY CACHE -> Mostrar splash con prefetch
        debugPrint('🚀 [Splash] Sin cache, mostrando splash con prefetch');
        await _preloadData();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [Splash] Error en check cache: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // ✅ RECOVERY: Navegar igual aunque falle
      if (!_isDisposed && mounted) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (!_isDisposed && mounted) {
          _navigateToHome();
        }
      }
    }
  }

  // ============================================
  // PREFETCH CON PROTECCIÓN NUCLEAR
  // ============================================

  Future<void> _preloadData() async {
    if (_isDisposed || !mounted) return;

    try {
      debugPrint('🚀 [Splash] Iniciando prefetch...');
      final startTime = DateTime.now();

      // ✅ Prefetch con timeout de 10s
      final prefetchFuture = ref.read(eventsProvider.future).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ [Splash] Timeout en prefetch (10s), continuando sin datos');
          return <Event>[];
        },
      );
      
      // ✅ Esperar mínimo 1.2s para UX (mostrar splash completo)
      final results = await Future.wait([
        prefetchFuture,
        Future.delayed(const Duration(milliseconds: 1200)),
      ]);

      final elapsed = DateTime.now().difference(startTime);
      debugPrint('✅ [Splash] Prefetch completado en ${elapsed.inMilliseconds}ms');

      // ✅ CRITICAL: Verificar estado antes de navegar
      if (_isDisposed || !mounted) {
        debugPrint('⚠️ [Splash] Widget disposed/unmounted, cancelando navegación');
        return;
      }

      // ✅ Navegar a Home
      _navigateToHome();
      
    } catch (e, stackTrace) {
      debugPrint('❌ [Splash] Error crítico en prefetch: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // ✅ RECOVERY: Navegar igual aunque falle
      if (!_isDisposed && mounted) {
        // Pequeño delay antes de navegar para dar feedback visual
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!_isDisposed && mounted) {
          _navigateToHome();
        }
      }
    }
  }

  // ============================================
  // NAVEGACIÓN NUCLEAR-PROOF
  // ============================================

  void _navigateToHome() {
    // ✅ CRITICAL: Prevenir múltiples navegaciones
    if (_isNavigating) {
      debugPrint('⚠️ [Splash] Navegación ya en progreso, ignorando');
      return;
    }

    // ✅ CRITICAL: Verificar estado
    if (_isDisposed || !mounted) {
      debugPrint('⚠️ [Splash] Widget disposed/unmounted, cancelando navegación');
      return;
    }

    _isNavigating = true;

    // ✅ Cancelar timer de seguridad
    _navigationTimer?.cancel();

    // ✅ Navegar en el siguiente frame (evita race conditions)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isDisposed || !mounted) return;
      
      try {
        context.go('/home');
        debugPrint('✅ [Splash] Navegación a /home exitosa');
      } catch (e) {
        debugPrint('❌ [Splash] Error navegando: $e');
        
        // ✅ RECOVERY: Reintentar una vez
        if (!_isDisposed && mounted) {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!_isDisposed && mounted) {
              try {
                context.go('/home');
                debugPrint('✅ [Splash] Reintento de navegación exitoso');
              } catch (e2) {
                debugPrint('❌ [Splash] Reintento falló: $e2');
                // Ya no hay más recovery, el usuario tendrá que reiniciar
              }
            }
          });
        }
      }
    });
  }
}
