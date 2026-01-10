import 'dart:async';
import 'package:evio_fan/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:evio_core/evio_core.dart';

import '../../providers/event_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../providers/spotify_provider.dart';
import 'widgets/event_hero_section.dart';
import 'widgets/event_content_section.dart';
import 'widgets/bottom_purchase_cta.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/auth_bottom_sheet.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isDisposed = false;
  final Map<String, int> _quantities = {};
  final ScrollController _scrollController = ScrollController();
  // ✅ GlobalKey para hacer scroll a la sección de tickets
  final GlobalKey _ticketsSectionKey = GlobalKey();
  
  // ✅ Estado para controlar visibilidad del header flotante
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);
  static const double _titleThreshold = 350.0; // Cuando el título desaparece

  @override
  void initState() {
  super.initState();
  
  // ✅ Listener para detectar scroll
  _scrollController.addListener(_onScroll);
  
  // ✅ PARALLEL FETCH: Cargar info estática + categorías en paralelo
  WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_isDisposed || !mounted) return;
  
  // Disparar AMBAS llamadas simultáneamente (no secuencial)
  ref.read(eventInfoProvider(widget.eventId)); // Cached
  ref.read(filteredTicketCategoriesProvider(widget.eventId)); // Filtered
  
  // Precachear imágenes de artistas cuando el evento cargue
  final eventAsync = ref.read(eventInfoProvider(widget.eventId));
  eventAsync.whenData((event) {
      if (event != null && event.lineup.isNotEmpty) {
          // Disparar búsqueda de imágenes en background
          for (final artist in event.lineup) {
            ref.read(artistImageProvider(artist.name));
          }
        }
      });
    });
  }
  
  void _onScroll() {
    if (_scrollController.hasClients) {
      _scrollOffset.value = _scrollController.offset;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onQuantityChanged(String tierId, int quantity) {
    if (_isDisposed || !mounted) return;
    setState(() {
      if (quantity <= 0) {
        _quantities.remove(tierId);
      } else {
        _quantities[tierId] = quantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
  // ✅ CACHED: Info estática del evento
    final eventAsync = ref.watch(eventInfoProvider(widget.eventId));
    
    // ✅ FILTERED: Categorías filtradas según configuración del evento
    final categoriesAsync = ref.watch(filteredTicketCategoriesProvider(widget.eventId));

    return eventAsync.when(
      data: (event) {
        if (event == null) {
          return Scaffold(
            backgroundColor: EvioFanColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    color: EvioFanColors.mutedForeground,
                    size: 48,
                  ),
                  SizedBox(height: EvioSpacing.md),
                  Text(
                    'Evento no encontrado',
                    style: TextStyle(
                      color: EvioFanColors.foreground,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.lg),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Volver'),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildContent(context, event, categoriesAsync);
      },
      loading: () => Scaffold(
        backgroundColor: EvioFanColors.background,
        body: Center(
          child: CircularProgressIndicator(color: EvioFanColors.primary),
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: EvioFanColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: EvioFanColors.error, size: 48),
              SizedBox(height: EvioSpacing.md),
              Text(
                'Error al cargar evento',
                style: TextStyle(color: EvioFanColors.foreground, fontSize: 18),
              ),
              SizedBox(height: EvioSpacing.xs),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.xl),
                child: Text(
                  e.toString(),
                  style: TextStyle(
                    color: EvioFanColors.mutedForeground,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: EvioSpacing.lg),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Event event,
    AsyncValue<List<TicketCategory>> categoriesAsync,
  ) {
    return Scaffold(
      body: Container(
        // ✅ Fondo usando token centralizado
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: Stack(
          children: [
          SingleChildScrollView(
            controller: _scrollController, // Conectar ScrollController
            child: Column(
              children: [
                EventHeroSection(
                  event: event,
                  height: 450,
                  onBackPressed: () => context.pop(),
                ),
                EventContentSection(
                  event: event,
                  categoriesAsync: categoriesAsync,
                  quantities: _quantities,
                  onQuantityChanged: _onQuantityChanged,
                  ticketsSectionKey: _ticketsSectionKey, // ✅ Pasar el key
                ),
                SizedBox(height: 200), // ✅ Más espacio para que no tape la productora
              ],
            ),
          ),
          
          // ✅ HEADER FLOTANTE (aparece cuando scrolleas más allá del título)
          ValueListenableBuilder<double>(
            valueListenable: _scrollOffset,
            builder: (context, offset, child) {
              // Calcular opacidad: 0 cuando offset < threshold, 1 cuando >= threshold
              final opacity = (offset - _titleThreshold).clamp(0.0, 100.0) / 100.0;
              
              // ✅ NO renderizar si es invisible (optimización)
              if (opacity <= 0) return const SizedBox.shrink();
              
              return AnimatedOpacity(
                opacity: opacity,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 110, // ✅ Más altura para que no tape el texto
                  decoration: BoxDecoration(
                    color: EvioFanColors.background.withValues(alpha: 0.95),
                    border: Border(
                      bottom: BorderSide(
                        color: EvioFanColors.border.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: EvioSpacing.md,
                        vertical: EvioSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          // Botón back con RepaintBoundary para aislar taps
                          RepaintBoundary(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  debugPrint('🔙 Back button tapped');
                                  context.pop();
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: EvioFanColors.muted,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.arrow_back,
                                    color: EvioFanColors.foreground,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          SizedBox(width: EvioSpacing.md),
                          
                          // Título del evento (centrado)
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                color: EvioFanColors.foreground,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          SizedBox(width: 40 + EvioSpacing.md), // Compensar botón back
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          BottomPurchaseCTA(
            categoriesAsync: categoriesAsync,
            quantities: _quantities,
            ticketsSectionKey: _ticketsSectionKey, // ✅ Pasar key para scroll
            scrollController: _scrollController, // ✅ Pasar controller
            onPurchase: () async {
              if (_isDisposed || !mounted) return;

              // ✅ REFETCH categorías JUSTO antes de comprar CON TIMEOUT
              try {
                final freshCategoriesAsync = await ref.refresh(
                  eventTicketCategoriesProvider(widget.eventId).future,
                ).timeout(
                  const Duration(seconds: 5),
                  onTimeout: () {
                    throw TimeoutException('Timeout al verificar disponibilidad');
                  },
                );

                if (_isDisposed || !mounted) return;

                // Validar disponibilidad con datos FRESCOS
                bool hasStock = true;
                String? errorMsg;

                // ✅ PASO 1: Agrupar cantidades por categoría
                final quantitiesByCategory = <String, int>{};

                for (final entry in _quantities.entries) {
                  final tierId = entry.key;
                  final requestedQty = entry.value;

                  // Buscar el tier en las categorías
                  TicketTier? tier;
                  String? categoryId;
                  
                  // ✅ OPTIMIZADO: Break early cuando encuentres el tier
                  bool found = false;
                  for (final category in freshCategoriesAsync) {
                    if (found) break;
                    for (final t in category.tiers) {
                      if (t.id == tierId) {
                        tier = t;
                        categoryId = category.id;
                        found = true;
                        break;
                      }
                    }
                  }

                  if (tier == null) {
                    errorMsg = 'Ticket no encontrado';
                    hasStock = false;
                    break;
                  }

                  // Acumular cantidades por categoría
                  quantitiesByCategory[categoryId!] = 
                    (quantitiesByCategory[categoryId] ?? 0) + requestedQty;

                  // ❌ Verificar sold out
                  if (tier.isSoldOut) {
                    hasStock = false;
                    errorMsg = '${tier.name} está agotado';
                    break;
                  }

                  // ❌ Verificar cantidad disponible
                  if (tier.availableQuantity < requestedQty) {
                    hasStock = false;
                    errorMsg =
                        'Solo quedan ${tier.availableQuantity} tickets de ${tier.name}';
                    break;
                  }
                }

                // ✅ PASO 2: Validar maxPerPurchase por categoría
                if (hasStock) {
                  for (final category in freshCategoriesAsync) {
                    final totalQty = quantitiesByCategory[category.id] ?? 0;
                    if (totalQty > 0 && category.maxPerPurchase != null) {
                      if (totalQty > category.maxPerPurchase!) {
                        hasStock = false;
                        errorMsg = 
                          'Máximo ${category.maxPerPurchase} tickets de ${category.name} por compra';
                        break;
                      }
                    }
                  }
                }

                if (!hasStock) {
                  if (_isDisposed || !mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg!),
                      backgroundColor: EvioFanColors.error,
                      action: SnackBarAction(
                        label: 'Actualizar',
                        textColor: Colors.white,
                        onPressed: () {
                          if (_isDisposed || !mounted) return;
                          // Refrescar cantidades
                          setState(() => _quantities.clear());
                        },
                      ),
                    ),
                  );
                  return;
                }

                // ✅ Stock disponible → Continuar a checkout
                if (_isDisposed || !mounted) return;
                
                final cartNotifier = ref.read(cartProvider.notifier);
                cartNotifier.setEvent(widget.eventId);

                for (final entry in _quantities.entries) {
                  cartNotifier.setQuantity(entry.key, entry.value);
                }

                final isAuthenticated = ref.read(isAuthenticatedProvider);

                if (!isAuthenticated) {
                  AuthBottomSheet.show(context, redirectTo: '/checkout');
                  return;
                }

                if (_isDisposed || !mounted) return;
                
                // Navegar a checkout
                context.push('/checkout');
              } catch (e) {
                debugPrint('❌ [EventDetail] Error en onPurchase: $e');
                
                if (_isDisposed || !mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      e is TimeoutException 
                        ? 'Timeout al verificar disponibilidad. Intenta de nuevo.'
                        : 'Error al procesar compra: $e',
                    ),
                    backgroundColor: EvioFanColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
    );
  }
}
