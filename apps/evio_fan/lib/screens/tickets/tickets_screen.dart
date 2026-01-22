import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ticket_provider.dart';
import '../../widgets/auth/auth_bottom_sheet.dart';
import '../../widgets/shimmer/tickets_list_shimmer.dart';

class TicketsScreen extends ConsumerStatefulWidget {
  const TicketsScreen({super.key});

  @override
  ConsumerState<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends ConsumerState<TicketsScreen> {
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    
    // ✅ Si no hay sesión, mostrar bottom sheet de auth
    if (userId == null) {
      return _buildNoSessionState(context);
    }
    
    final ticketsAsync = ref.watch(myActiveTicketsProvider);

    return Scaffold(
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: SafeArea(
        child: ticketsAsync.when(
          data: (tickets) {
            if (tickets.isEmpty) {
              return _buildEmptyState(context);
            }

            // Separar y agrupar por fecha y evento
            // Un evento se considera "pasado" si ya pasaron 6+ horas desde su inicio
            final now = DateTime.now();
            final upcomingTickets = tickets
                .where(
                  (t) =>
                      t.event?.startDatetime != null &&
                      t.event!.startDatetime.isAfter(now.subtract(Duration(hours: 6))),
                )
                .toList();
            final pastTickets = tickets
                .where(
                  (t) =>
                      t.event?.startDatetime != null &&
                      t.event!.startDatetime.isBefore(now.subtract(Duration(hours: 6))),
                )
                .toList();

            // Agrupar por evento
            final upcomingGroups = _groupByEvent(upcomingTickets);
            final pastGroups = _groupByEvent(pastTickets);

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(EvioSpacing.lg),
                    child: Text(
                      'Mis Tickets',
                      style: EvioTypography.h1.copyWith(
                        color: EvioFanColors.foreground,
                      ),
                    ),
                  ),
                ),

                // Próximos eventos
                if (upcomingGroups.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        EvioSpacing.lg,
                        EvioSpacing.md,
                        EvioSpacing.lg,
                        EvioSpacing.sm,
                      ),
                      child: Text(
                        'PRÓXIMOS EVENTOS',
                        style: EvioTypography.labelSmall.copyWith(
                          color: EvioFanColors.mutedForeground,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final group = upcomingGroups[index];
                        final firstTicket = group.value.first;
                        return Padding(
                          padding: EdgeInsets.only(bottom: EvioSpacing.md),
                          child: _TicketListItem(
                            eventId: group.key,
                            eventTitle: firstTicket.event?.title ?? 'Evento',
                            eventImage: firstTicket.event?.imageUrl,
                            eventDate: firstTicket.event?.startDatetime,
                            ticketCount: group.value.length,
                            isPast: false,
                          ),
                        );
                      }, childCount: upcomingGroups.length),
                    ),
                  ),
                ],

                // Eventos pasados
                if (pastGroups.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        EvioSpacing.lg,
                        EvioSpacing.xl,
                        EvioSpacing.lg,
                        EvioSpacing.sm,
                      ),
                      child: Text(
                        'EVENTOS PASADOS',
                        style: EvioTypography.labelSmall.copyWith(
                          color: EvioFanColors.mutedForeground,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final group = pastGroups[index];
                        final firstTicket = group.value.first;
                        return Padding(
                          padding: EdgeInsets.only(bottom: EvioSpacing.md),
                          child: _TicketListItem(
                            eventId: group.key,
                            eventTitle: firstTicket.event?.title ?? 'Evento',
                            eventImage: firstTicket.event?.imageUrl,
                            eventDate: firstTicket.event?.startDatetime,
                            ticketCount: group.value.length,
                            isPast: true,
                          ),
                        );
                      }, childCount: pastGroups.length),
                    ),
                  ),
                ],

                // Spacing bottom
                SliverToBoxAdapter(child: SizedBox(height: EvioSpacing.xxl)),
              ],
            );
          },
          loading: () => const TicketsListShimmer(),
          error: (e, st) => _buildErrorState(context, e),
        ),
      ),
      ),
    );
  }

  List<MapEntry<String, List<Ticket>>> _groupByEvent(List<Ticket> tickets) {
    final groups = <String, List<Ticket>>{};
    for (final ticket in tickets) {
      groups.putIfAbsent(ticket.eventId, () => []).add(ticket);
    }
    return groups.entries.toList();
  }

  Widget _buildNoSessionState(BuildContext context) {
    // ✅ SENIOR PATTERN: Sin modal automático, solo UI clara con CTA
    return Scaffold(
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(EvioSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 80,
                    color: EvioFanColors.primary.withValues(alpha: 0.7),
                  ),
                  SizedBox(height: EvioSpacing.xl),
                  Text(
                    'Tus tickets te esperan',
                    style: EvioTypography.h2.copyWith(
                      color: EvioFanColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: EvioSpacing.sm),
                  Text(
                    'Iniciá sesión para ver tus entradas y acceder a los eventos',
                    style: EvioTypography.bodyMedium.copyWith(
                      color: EvioFanColors.mutedForeground,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: EvioSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => AuthBottomSheet.show(context, redirectTo: '/tickets'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EvioFanColors.primary,
                        foregroundColor: EvioFanColors.primaryForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(EvioRadius.button),
                        ),
                      ),
                      child: Text('Iniciar sesión', style: EvioTypography.button),
                    ),
                  ),
                  SizedBox(height: EvioSpacing.md),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: Text(
                      'Explorar eventos',
                      style: EvioTypography.labelMedium.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: EvioFanColors.mutedForeground,
          ),
          SizedBox(height: EvioSpacing.md),
          Text(
            'No tenés tickets',
            style: EvioTypography.h3.copyWith(color: EvioFanColors.foreground),
          ),
          SizedBox(height: EvioSpacing.sm),
          Text(
            'Comprá tu primer evento para verlo acá',
            style: EvioTypography.bodyMedium.copyWith(
              color: EvioFanColors.mutedForeground,
            ),
          ),
          SizedBox(height: EvioSpacing.lg),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvioFanColors.primary,
              foregroundColor: EvioFanColors.primaryForeground,
            ),
            child: const Text('Explorar eventos'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: EvioFanColors.error,
          ),
          SizedBox(height: EvioSpacing.md),
          Text(
            'Error al cargar tickets',
            style: EvioTypography.h4.copyWith(color: EvioFanColors.foreground),
          ),
          SizedBox(height: EvioSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: EvioSpacing.xl),
            child: Text(
              error.toString(),
              style: EvioTypography.bodySmall.copyWith(
                color: EvioFanColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: EvioSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => ref.invalidate(myActiveTicketsProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvioFanColors.primary,
              foregroundColor: EvioFanColors.primaryForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketListItem extends StatelessWidget {
  final String eventId;
  final String eventTitle;
  final String? eventImage;
  final DateTime? eventDate;
  final int ticketCount;
  final bool isPast;

  const _TicketListItem({
    required this.eventId,
    required this.eventTitle,
    this.eventImage,
    this.eventDate,
    required this.ticketCount,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, dd MMM - HH:mm');

    return GestureDetector(
      onTap: () {
        context.push('/event-tickets/$eventId');
      },
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.md),
        decoration: BoxDecoration(
          color: EvioFanColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          border: Border.all(color: EvioFanColors.border),
        ),
        child: Row(
          children: [
            // Imagen del evento
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: EvioFanColors.muted,
                borderRadius: BorderRadius.circular(EvioRadius.button),
                image: eventImage != null
                    ? DecorationImage(
                        image: NetworkImage(eventImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: eventImage == null
                  ? Icon(
                      Icons.music_note,
                      color: EvioFanColors.mutedForeground,
                      size: 32,
                    )
                  : null,
            ),
            SizedBox(width: EvioSpacing.md),

            // Info del evento
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eventTitle,
                    style: EvioTypography.bodyLarge.copyWith(
                      color: EvioFanColors.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: EvioSpacing.xxs),
                  Text(
                    eventDate != null ? dateFormat.format(eventDate!) : '',
                    style: EvioTypography.bodySmall.copyWith(
                      color: EvioFanColors.mutedForeground,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.xxs),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: EvioSpacing.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: EvioFanColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$ticketCount ${ticketCount == 1 ? 'ticket' : 'tickets'}',
                      style: EvioTypography.labelSmall.copyWith(
                        color: EvioFanColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              isPast ? Icons.check_circle : Icons.chevron_right,
              color: isPast
                  ? EvioFanColors.mutedForeground
                  : EvioFanColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
