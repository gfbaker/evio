import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/common/floating_snackbar.dart';

// Importaciones de tu proyecto
import 'package:evio_core/evio_core.dart';
import 'package:evio_admin/providers/event_providers.dart';

// ✅ PROVIDER: Obtener tickets
final eventTicketsProvider = FutureProvider.autoDispose
    .family<List<TicketType>, String>((ref, eventId) async {
      final repo = ref.watch(eventRepositoryProvider);
      return repo.getEventTicketTypes(eventId);
    });

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({required this.eventId, super.key});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(eventDetailProvider(widget.eventId));
    final ticketsAsync = ref.watch(eventTicketsProvider(widget.eventId));
    final statsAsync = ref.watch(eventStatsProvider(widget.eventId));

    return Scaffold(
      backgroundColor: EvioLightColors.background,
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return const _ErrorState(msg: 'Evento no encontrado');
          }

          return Column(
            children: [
              // 1. Header Fijo
              _EventHeader(
                event: event,
                onEdit: () => context.push('/admin/events/${event.id}/edit'),
                onDelete: () => _showDeleteDialog(context, event),
              ),

              // 2. Contenido Scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(EvioSpacing.xl),
                  child: Column(
                    children: [
                      // A. Acciones Rápidas
                      _QuickActionsCard(event: event),

                      SizedBox(height: EvioSpacing.xl),

                      // B. Grid de Métricas (CON STATS REALES)
                      statsAsync.when(
                        data: (stats) => LayoutBuilder(
                          builder: (context, constraints) {
                            final isDesktop = constraints.maxWidth > 800;
                            return isDesktop
                                ? IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _CapacityCard(stats: stats),
                                        ),
                                        SizedBox(width: EvioSpacing.xl),
                                        Expanded(
                                          child: _RevenueCard(stats: stats),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      _CapacityCard(stats: stats),
                                      SizedBox(height: EvioSpacing.xl),
                                      _RevenueCard(stats: stats),
                                    ],
                                  );
                          },
                        ),
                        loading: () => Container(
                          height: 200,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, s) => Container(
                          height: 200,
                          child: Center(
                            child: Text('Error cargando stats: $e'),
                          ),
                        ),
                      ),

                      SizedBox(height: EvioSpacing.xl),

                      // C. Gestión de Tandas
                      ticketsAsync.when(
                        data: (tickets) => _TicketTiersCard(
                          event: event,
                          tickets: tickets,
                          onAddTier: () => _showAddTicketDialog(context, event),
                          onDeleteTier: (ticketId) =>
                              _deleteTicket(event.id, ticketId),
                        ),
                        loading: () => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: EvioLightColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: EvioLightColors.border),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, s) => Text('Error tickets: $e'),
                      ),

                      SizedBox(height: EvioSpacing.xl),

                      // D. Info Adicional
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 800;
                          if (!isDesktop) {
                            return Column(
                              children: [
                                _DJLineupCard(event: event),
                                SizedBox(height: EvioSpacing.xl),
                                _ContactCard(event: event),
                              ],
                            );
                          }
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: _DJLineupCard(event: event)),
                                SizedBox(width: EvioSpacing.xl),
                                Expanded(child: _ContactCard(event: event)),
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(height: EvioSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _ErrorState(msg: err.toString()),
      ),
    );
  }

  void _deleteTicket(String eventId, String ticketId) async {
    try {
      await ref.read(
        deleteTicketTypeProvider(
          DeleteTicketTypeParams(eventId: eventId, ticketTypeId: ticketId),
        ).future,
      );
      ref.invalidate(eventTicketsProvider(eventId));
      ref.invalidate(eventStatsProvider(eventId)); // ✅ También refrescar stats

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tanda eliminada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showDeleteDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Evento'),
        content: Text(
          '¿Estás seguro de eliminar "${event.title}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await ref.read(deleteEventProvider(event.id).future);
                if (mounted) {
                  context.go('/admin/dashboard');
                  // ✅ UN SOLO FloatingSnackBar después de navegar
                  FloatingSnackBar.show(
                    context,
                    message: 'Evento "${event.title}" eliminado exitosamente',
                    type: SnackBarType.success,
                  );
                }
              } catch (e) {
                if (mounted) {
                  FloatingSnackBar.show(
                    context,
                    message: 'Error al eliminar: $e',
                    type: SnackBarType.error,
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: EvioLightColors.destructive,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddTicketDialog(BuildContext context, Event event) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final qtyController = TextEditingController();
    final maxController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva Tanda de Tickets'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej: Early Bird',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio (valor entero)',
                  hintText: 'Ej: 20',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad total',
                  hintText: 'Ej: 100',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxController,
                decoration: const InputDecoration(
                  labelText: 'Máximo por persona (opcional)',
                  hintText: 'Ej: 4',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  qtyController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa todos los campos')),
                );
                return;
              }

              final ticketType = TicketType(
                id: const Uuid().v4(),
                eventId: event.id,
                name: nameController.text,
                price: int.parse(priceController.text),
                totalQuantity: int.parse(qtyController.text),
                maxPerPurchase: maxController.text.isEmpty
                    ? null
                    : int.parse(maxController.text),
              );

              Navigator.pop(dialogContext);

              try {
                await ref.read(
                  createTicketTypeProvider(
                    CreateTicketTypeParams(
                      eventId: event.id,
                      ticketType: ticketType,
                    ),
                  ).future,
                );
                ref.invalidate(eventTicketsProvider(event.id));
                ref.invalidate(
                  eventStatsProvider(event.id),
                ); // ✅ Refrescar stats

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tanda creada exitosamente')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear tanda: $e')),
                  );
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECCIÓN 1: HEADER & HERO
// -----------------------------------------------------------------------------

class _EventHeader extends StatelessWidget {
  final Event event;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EventHeader({
    required this.event,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.xl),
      decoration: BoxDecoration(
        gradient: EvioGradients.headerGradient,
        border: Border(bottom: BorderSide(color: EvioLightColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _OutlineButtonSmall(
                icon: Icons.arrow_back,
                label: 'Volver al Dashboard',
                onTap: () => context.pop(),
              ),
              const Spacer(),
              _OutlineButtonSmall(
                icon: Icons.edit_outlined,
                label: 'Editar Evento',
                onTap: onEdit,
              ),
              SizedBox(width: EvioSpacing.xs),
              _DestructiveButtonSmall(onTap: onDelete),
            ],
          ),
          SizedBox(height: EvioSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(EvioRadius.lg),
                  border: Border.all(color: EvioLightColors.border, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(EvioRadius.lg),
                  child: event.imageUrl != null
                      ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: EvioLightColors.muted,
                          child: const Icon(Icons.image, size: 48),
                        ),
                ),
              ),
              SizedBox(width: EvioSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            event.title,
                            style: EvioTypography.displayMedium.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: EvioSpacing.sm),
                        _StatusBadge(status: _getEventStatus(event)),
                      ],
                    ),
                    SizedBox(height: EvioSpacing.md),
                    Wrap(
                      spacing: EvioSpacing.lg,
                      runSpacing: EvioSpacing.md,
                      children: [
                        _MetaItem(
                          Icons.calendar_today,
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'es',
                          ).format(event.startDatetime),
                        ),
                        _MetaItem(
                          Icons.access_time,
                          DateFormat('HH:mm').format(event.startDatetime),
                        ),
                        _MetaItem(Icons.location_on, event.venueName),
                        if (event.genre != null)
                          _MetaItem(Icons.music_note, event.genre!),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getEventStatus(Event event) {
    if (!event.isPublished) return 'Borrador';
    return event.isPast ? 'Finalizado' : 'Publicado';
  }
}

// -----------------------------------------------------------------------------
// SECCIÓN 2: CARDS CON DATOS REALES
// -----------------------------------------------------------------------------

class _QuickActionsCard extends StatelessWidget {
  final Event event;
  const _QuickActionsCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Acciones Rápidas',
      icon: Icons.bolt,
      accentColor: EvioLightColors.primary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 600;
          return Flex(
            direction: isDesktop ? Axis.horizontal : Axis.vertical,
            children: [
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: _ActionCardButton(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Generar Ticket Manual',
                  subtitle: 'Crear entrada directa',
                  onTap: () {},
                ),
              ),
              SizedBox(
                width: isDesktop ? EvioSpacing.md : 0,
                height: isDesktop ? 0 : EvioSpacing.md,
              ),
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: _ActionCardButton(
                  icon: Icons.check_circle_outline,
                  label: 'Marcar Sold Out',
                  subtitle: 'Finalizar ventas',
                  onTap: () {},
                ),
              ),
              SizedBox(
                width: isDesktop ? EvioSpacing.md : 0,
                height: isDesktop ? 0 : EvioSpacing.md,
              ),
              Expanded(
                flex: isDesktop ? 1 : 0,
                child: _ActionCardButton(
                  icon: Icons.send_outlined,
                  label: 'Enviar Invitaciones',
                  subtitle: 'Tickets gratuitos',
                  onTap: () {},
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  final EventStats stats; // ✅ USA STATS
  const _CapacityCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final sold = stats.soldCount;
    final total = stats.totalCapacity;
    final percentage = total > 0 ? (sold / total) : 0.0;
    final percentInt = (percentage * 100).round();

    Color progressColor = EvioLightColors.progressLow;
    if (percentInt >= 40) progressColor = EvioLightColors.progressMedium;
    if (percentInt >= 70) progressColor = EvioLightColors.progressHigh;
    if (percentInt >= 90) progressColor = EvioLightColors.progressFull;

    return _DetailCard(
      title: 'Capacidad & Ventas',
      icon: Icons.bar_chart,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vendidos:',
                style: EvioTypography.bodySmall.copyWith(
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              Text('$sold / $total', style: EvioTypography.labelLarge),
            ],
          ),
          SizedBox(height: EvioSpacing.xs),
          Container(
            height: 32,
            width: double.infinity,
            decoration: BoxDecoration(
              color: EvioLightColors.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: percentage.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: progressColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    '$percentInt%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: EvioSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Disponibles: ${stats.availableCount}',
                style: TextStyle(
                  fontSize: 10.5,
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              if (percentInt >= 90)
                Text(
                  '¡Casi Agotado!',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: EvioLightColors.destructive,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
            child: Divider(color: EvioLightColors.border),
          ),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'Capacidad Total',
                  value: total.toString(),
                ),
              ),
              Expanded(
                child: _StatItem(
                  label: 'Tickets Vendidos',
                  value: sold.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final EventStats stats; // ✅ USA STATS
  const _RevenueCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final currentRevenue = stats.currentRevenue / 100;
    final potentialRevenue = stats.potentialRevenue / 100;
    final remaining = stats.remainingRevenue / 100;
    final avgPrice = stats.avgPrice / 100;

    return _DetailCard(
      title: 'Ingresos',
      icon: Icons.euro,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresos Actuales',
            style: EvioTypography.bodySmall.copyWith(
              color: EvioLightColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '\$${currentRevenue.toStringAsFixed(2)}',
            style: EvioTypography.revenue,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
            child: Divider(color: EvioLightColors.border),
          ),
          _RevenueRow(
            label: 'Precio promedio',
            value: '\$${avgPrice.toStringAsFixed(2)}',
          ),
          SizedBox(height: EvioSpacing.xs),
          _RevenueRow(
            label: 'Ingresos potenciales',
            value: '\$${potentialRevenue.toStringAsFixed(2)}',
          ),
          SizedBox(height: EvioSpacing.xs),
          _RevenueRow(
            label: 'Por vender',
            value: '\$${remaining.toStringAsFixed(2)}',
            valueColor: EvioLightColors.revenuePending,
          ),
        ],
      ),
    );
  }
}

class _TicketTiersCard extends StatelessWidget {
  final Event event;
  final List<TicketType> tickets;
  final VoidCallback onAddTier;
  final Function(String) onDeleteTier;

  const _TicketTiersCard({
    required this.event,
    required this.tickets,
    required this.onAddTier,
    required this.onDeleteTier,
  });

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Gestión de Tandas',
      icon: Icons.confirmation_number,
      headerAction: FilledButton.icon(
        onPressed: onAddTier,
        icon: const Icon(Icons.add, size: 16),
        label: const Text('Nueva Tanda'),
        style: FilledButton.styleFrom(
          backgroundColor: EvioLightColors.primary,
          foregroundColor: EvioLightColors.primaryForeground,
          padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(0, 36),
        ),
      ),
      child: Column(
        children: tickets.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No hay tandas creadas aún.',
                    style: TextStyle(color: EvioLightColors.mutedForeground),
                  ),
                ),
              ]
            : tickets.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final ticket = entry.value;
                final soldCount = ticket.soldQuantity;
                final isSoldOut = ticket.isSoldOut;
                final status = isSoldOut ? 'Agotada' : 'Activa';

                return Padding(
                  padding: EdgeInsets.only(bottom: EvioSpacing.md),
                  child: _TierItem(
                    number: index,
                    name: ticket.name,
                    status: status,
                    price: '\$${ticket.price}',
                    sold: soldCount,
                    total: ticket.totalQuantity,
                    isActive: !isSoldOut,
                    isSoldOut: isSoldOut,
                    onDelete: () => onDeleteTier(ticket.id),
                  ),
                );
              }).toList(),
      ),
    );
  }
}

class _TierItem extends StatelessWidget {
  final int number;
  final String name;
  final String status;
  final String price;
  final int sold;
  final int total;
  final bool isActive;
  final bool isSoldOut;
  final VoidCallback onDelete;

  const _TierItem({
    required this.number,
    required this.name,
    required this.status,
    required this.price,
    required this.sold,
    required this.total,
    required this.isActive,
    required this.isSoldOut,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor = EvioLightColors.border;
    Color bgColor = EvioLightColors.muted.withValues(alpha: 0.3);
    Color progressColor = EvioLightColors.mutedForeground;
    Color badgeColor = EvioLightColors.mutedForeground;

    if (isSoldOut) {
      borderColor = EvioLightColors.tierSoldOutBorder;
      bgColor = EvioLightColors.tierSoldOutBackground.withValues(alpha: 0.5);
      progressColor = EvioLightColors.destructive;
      badgeColor = EvioLightColors.destructive;
    } else if (isActive) {
      borderColor = EvioLightColors.tierActiveBorder;
      bgColor = EvioLightColors.primary.withValues(alpha: 0.05);
      progressColor = EvioLightColors.primary;
      badgeColor = EvioLightColors.primary;
    }

    final percent = total > 0 ? sold / total : 0.0;

    return Container(
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(EvioRadius.lg),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: EvioLightColors.background,
                  border: Border.all(color: EvioLightColors.border),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: EvioSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: EvioTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: EvioSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Precio: $price',
                      style: TextStyle(
                        color: EvioLightColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: EvioLightColors.destructive,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.sm),
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: EvioLightColors.secondary.withValues(alpha: 1.0),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
          SizedBox(height: EvioSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percent * 100).round()}% vendido',
                style: TextStyle(
                  fontSize: 10.5,
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              Text(
                '${total - sold} disponibles',
                style: TextStyle(
                  fontSize: 10.5,
                  color: EvioLightColors.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DJLineupCard extends StatelessWidget {
  final Event event;
  const _DJLineupCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Line-up de DJs',
      icon: Icons.music_note,
      child: event.lineup.isEmpty
          ? Center(
              child: Text('No hay lineup', style: EvioTypography.bodySmall),
            )
          : Column(
              children: event.lineup
                  .map(
                    (artist) => Padding(
                      padding: EdgeInsets.only(bottom: EvioSpacing.sm),
                      child: Container(
                        padding: EdgeInsets.all(EvioSpacing.sm),
                        decoration: BoxDecoration(
                          color: EvioLightColors.muted.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(EvioRadius.lg),
                          border: Border.all(color: EvioLightColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: EvioLightColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.music_note,
                                size: 20,
                                color: EvioLightColors.primary,
                              ),
                            ),
                            SizedBox(width: EvioSpacing.sm),
                            Expanded(
                              child: Text(
                                artist.name,
                                style: EvioTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (artist.isHeadliner)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: EvioLightColors.primary,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Headliner',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final Event event;
  const _ContactCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      title: 'Información de Contacto',
      icon: Icons.info_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Organizador',
            style: TextStyle(
              fontSize: 10.5,
              color: EvioLightColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            event.organizerName ?? 'Pulse Events',
            style: EvioTypography.bodyLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: EvioSpacing.md),
          _InfoRow(
            label: 'Teléfono',
            value: '+34 612 345 678',
            icon: Icons.phone,
          ),
          SizedBox(height: EvioSpacing.md),
          _InfoRow(
            label: 'Dirección',
            value: event.address,
            icon: Icons.location_on,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SECCIÓN 3: WIDGETS GENÉRICOS
// -----------------------------------------------------------------------------

class _DetailCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? headerAction;
  final Color? accentColor;

  const _DetailCard({
    required this.title,
    required this.icon,
    required this.child,
    this.headerAction,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final leftBorderColor = accentColor ?? EvioLightColors.border;
    return Container(
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvioLightColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: leftBorderColor, width: 4.0),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: EvioLightColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: EvioLightColors.primary,
                      ),
                    ),
                    SizedBox(width: EvioSpacing.sm),
                    Text(title, style: EvioTypography.h2),
                    if (headerAction != null) ...[
                      const Spacer(),
                      headerAction!,
                    ],
                  ],
                ),
              ),
              Padding(padding: EdgeInsets.all(EvioSpacing.xl), child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCardButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        backgroundColor: EvioLightColors.background,
        side: const BorderSide(color: EvioLightColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: EvioLightColors.foreground),
          SizedBox(height: EvioSpacing.sm),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: EvioLightColors.mutedForeground,
              fontSize: 10.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    switch (status) {
      case 'Borrador':
        bg = Colors.orange.shade600;
        break;
      case 'Publicado':
        bg = EvioLightColors.statusUpcoming;
        break;
      case 'En curso':
        bg = EvioLightColors.statusOngoing;
        break;
      case 'Finalizado':
        bg = EvioLightColors.statusCompleted;
        break;
      default:
        bg = EvioLightColors.statusCancelled;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaItem(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: EvioLightColors.mutedForeground),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: EvioLightColors.mutedForeground,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _OutlineButtonSmall extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineButtonSmall({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: EvioLightColors.foreground,
        backgroundColor: EvioLightColors.background,
        side: const BorderSide(color: EvioLightColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14),
      ),
    );
  }
}

class _DestructiveButtonSmall extends StatelessWidget {
  final VoidCallback onTap;
  const _DestructiveButtonSmall({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.delete, size: 16),
      label: const Text('Eliminar'),
      style: FilledButton.styleFrom(
        backgroundColor: EvioLightColors.destructive,
        foregroundColor: EvioLightColors.destructiveForeground,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        minimumSize: const Size(0, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: EvioTypography.statsLabel),
        const SizedBox(height: 2),
        Text(value, style: EvioTypography.statsValue),
      ],
    );
  }
}

class _RevenueRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _RevenueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: EvioLightColors.mutedForeground,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? EvioLightColors.foreground,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final IconData? icon;
  const _InfoRow({required this.label, required this.value, this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: EvioLightColors.mutedForeground,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: EvioLightColors.mutedForeground),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                value,
                style: EvioTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String msg;
  const _ErrorState({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: EvioLightColors.destructive,
            ),
            SizedBox(height: EvioSpacing.md),
            Text('Error al cargar', style: EvioTypography.h3),
            Text(msg, style: TextStyle(color: EvioLightColors.mutedForeground)),
          ],
        ),
      ),
    );
  }
}
