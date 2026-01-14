import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/event_providers.dart';
import '../../widgets/common/floating_snackbar.dart';
import '../../widgets/events/invitations_drawer.dart';
import '../../widgets/event_detail/event_detail.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId, super.key});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isDisposed = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _refreshData() {
    if (_isDisposed) return;
    Future.microtask(() {
      if (_isDisposed) return;
      ref.invalidate(eventDetailProvider(widget.eventId));
      ref.invalidate(eventTicketCategoriesProvider(widget.eventId));
      ref.invalidate(eventStatsProvider(widget.eventId));
    });
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await _showDeleteDialog(event);
    if (!confirmed || _isDisposed || !mounted) return;

    try {
      await ref.read(deleteEventProvider(event.id).future).timeout(
        Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Timeout eliminando evento'),
      );

      if (_isDisposed || !mounted) return;

      // Invalidar providers
      ref.invalidate(currentUserEventsProvider);
      ref.invalidate(eventsProvider);
      ref.invalidate(eventDetailProvider(event.id));

      context.go('/admin/dashboard');

      Future.delayed(Duration(milliseconds: 300), () {
        if (!_isDisposed && mounted) {
          FloatingSnackBar.show(
            context,
            message: 'Evento "${event.title}" eliminado',
            type: SnackBarType.success,
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Error eliminando evento: $e');
      if (!_isDisposed && mounted) {
        FloatingSnackBar.show(
          context,
          message: 'Error al eliminar evento',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<bool> _showDeleteDialog(Event event) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar Evento'),
        content: Text(
          '¿Estás seguro de eliminar "${event.title}"?\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: EvioLightColors.destructive,
            ),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final categoriesAsync = ref.watch(eventTicketCategoriesProvider(widget.eventId));
    final statsAsync = ref.watch(eventStatsProvider(widget.eventId));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: EvioLightColors.surface,
      endDrawer: InvitationsDrawer(eventId: widget.eventId),
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return _ErrorView(message: 'Evento no encontrado');
          }

          return Column(
            children: [
              // Header
              EventDetailHeader(
                event: event,
                onEdit: () => context.push('/admin/events/${event.id}/edit'),
                onDelete: () => _deleteEvent(event),
              ),

              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(EvioSpacing.xl),
                  child: Column(
                    children: [
                      // Acciones rápidas
                      QuickActionsCard(
                        event: event,
                        onGenerateTicket: () {
                          // TODO: Implementar
                        },
                        onMarkSoldOut: () {
                          // TODO: Implementar
                        },
                        onSendInvitations: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                      ),
                      SizedBox(height: EvioSpacing.xl),

                      // Stats: Capacidad + Ingresos
                      statsAsync.when(
                        data: (stats) => _StatsRow(stats: stats),
                        loading: () => _LoadingCard(height: 200),
                        error: (e, _) => _ErrorCard(message: 'Error cargando stats'),
                      ),
                      SizedBox(height: EvioSpacing.xl),

                      // Categorías de tickets
                      categoriesAsync.when(
                        data: (categories) => TicketCategoriesCard(
                          event: event,
                          categories: categories,
                          onManage: () => context.push('/admin/events/${event.id}/edit'),
                        ),
                        loading: () => _LoadingCard(height: 200),
                        error: (e, _) => _ErrorCard(message: 'Error cargando categorías'),
                      ),
                      SizedBox(height: EvioSpacing.xl),

                      // Line-up + Info
                      _InfoRow(event: event),
                      SizedBox(height: EvioSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: EvioLightColors.accent),
        ),
        error: (e, _) => _ErrorView(message: e.toString()),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// LAYOUT WIDGETS
// -----------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final EventStats stats;

  const _StatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: CapacityCard(stats: stats)),
                SizedBox(width: EvioSpacing.xl),
                Expanded(child: RevenueCard(stats: stats)),
              ],
            ),
          );
        }

        return Column(
          children: [
            CapacityCard(stats: stats),
            SizedBox(height: EvioSpacing.xl),
            RevenueCard(stats: stats),
          ],
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Event event;

  const _InfoRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 800;

        if (isDesktop) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: DjLineupCard(event: event)),
                SizedBox(width: EvioSpacing.xl),
                Expanded(child: ContactCard(event: event)),
              ],
            ),
          );
        }

        return Column(
          children: [
            DjLineupCard(event: event),
            SizedBox(height: EvioSpacing.xl),
            ContactCard(event: event),
          ],
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// UTILITY WIDGETS
// -----------------------------------------------------------------------------

class _LoadingCard extends StatelessWidget {
  final double height;

  const _LoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Center(
        child: CircularProgressIndicator(color: EvioLightColors.accent),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.xl),
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: EvioLightColors.destructive),
          SizedBox(width: EvioSpacing.sm),
          Text(
            message,
            style: TextStyle(color: EvioLightColors.destructive),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: EvioLightColors.destructive,
          ),
          SizedBox(height: EvioSpacing.md),
          Text(
            'Error al cargar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: EvioLightColors.textPrimary,
            ),
          ),
          SizedBox(height: EvioSpacing.xs),
          Text(
            message,
            style: TextStyle(color: EvioLightColors.mutedForeground),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: EvioSpacing.xl),
          OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: Icon(Icons.arrow_back),
            label: Text('Volver'),
          ),
        ],
      ),
    );
  }
}
