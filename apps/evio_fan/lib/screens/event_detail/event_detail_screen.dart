import 'package:evio_fan/providers/order_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void initState() {
  super.initState();
  
  // ✅ PARALLEL FETCH: Cargar info estática + tickets en paralelo
  WidgetsBinding.instance.addPostFrameCallback((_) {
  if (_isDisposed || !mounted) return;
  
  // Disparar AMBAS llamadas simultáneamente (no secuencial)
  ref.read(eventInfoProvider(widget.eventId)); // Cached
  ref.read(filteredTicketTypesProvider(widget.eventId)); // Filtered
  
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

  @override
  void dispose() {
    _isDisposed = true;
    _scrollController.dispose();
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
    
    // ✅ FILTERED: Tickets filtrados según configuración del evento
    final ticketsAsync = ref.watch(filteredTicketTypesProvider(widget.eventId));

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
        return _buildContent(context, event, ticketsAsync);
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
    AsyncValue<List<TicketType>> ticketsAsync,
  ) {
    return Scaffold(
      backgroundColor: EvioFanColors.background,
      body: Stack(
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
                  ticketsAsync: ticketsAsync,
                  selectedTierId: null,
                  quantities: _quantities,
                  onTierSelected: (_) {},
                  onQuantityChanged: _onQuantityChanged,
                ),
                SizedBox(height: 180), // Espacio fijo para CTA expandido
              ],
            ),
          ),
          BottomPurchaseCTA(
            ticketsAsync: ticketsAsync,
            quantities: _quantities,
            onPurchase: () async {
              if (!mounted) return;

              // ✅ REFETCH tickets JUSTO antes de comprar
              final freshTicketsAsync = await ref.refresh(
                ticketTypesProvider(widget.eventId).future,
              );

              // Validar disponibilidad con datos FRESCOS
              bool hasStock = true;
              String? errorMsg;

              for (final entry in _quantities.entries) {
                final ticketId = entry.key;
                final requestedQty = entry.value;

                final ticket = freshTicketsAsync.firstWhere(
                  (t) => t.id == ticketId,
                );

                // ❌ Verificar sold out
                if (ticket.isSoldOut) {
                  hasStock = false;
                  errorMsg = '${ticket.name} está agotado';
                  break;
                }

                // ❌ Verificar cantidad disponible
                if (ticket.availableQuantity < requestedQty) {
                  hasStock = false;
                  errorMsg =
                      'Solo quedan ${ticket.availableQuantity} tickets de ${ticket.name}';
                  break;
                }

                // ❌ Verificar max per purchase
                if (ticket.maxPerPurchase != null &&
                    requestedQty > ticket.maxPerPurchase!) {
                  hasStock = false;
                  errorMsg =
                      'Máximo ${ticket.maxPerPurchase} tickets de ${ticket.name} por compra';
                  break;
                }
              }

              if (!hasStock) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMsg!),
                    backgroundColor: EvioFanColors.error,
                    action: SnackBarAction(
                      label: 'Actualizar',
                      textColor: Colors.white,
                      onPressed: () {
                        // Refrescar cantidades
                        setState(() => _quantities.clear());
                      },
                    ),
                  ),
                );
                return;
              }

              // ✅ Stock disponible → Continuar a checkout
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

              // Navegar a checkout
              context.push('/checkout');
            },
          ),
        ],
      ),
    );
  }
}
