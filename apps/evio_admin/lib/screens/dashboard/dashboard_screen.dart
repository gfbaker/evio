import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:evio_core/evio_core.dart';

import '../../providers/event_providers.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/event_list_item.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isDisposed = false;
  final TextEditingController _searchCtrl = TextEditingController();

  String _genreFilter = 'all';
  String _statusFilter = 'all';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (!_isDisposed && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchCtrl.removeListener(() {});
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvioLightColors.background,
      body: Column(
        children: [
          const _DashboardHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: _StatsSection(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildFilters(),
                  ),
                  const SizedBox(height: 24),
                  const _EventCountBanner(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildEventsGrid(),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Flex(
      direction: Axis.horizontal,
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: EvioLightColors.inputBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Buscar eventos, venues...',
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: EvioLightColors.mutedForeground,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 11,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _CustomDropdown(
          value: _genreFilter,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Todos los géneros')),
            DropdownMenuItem(value: 'techno', child: Text('Techno')),
            DropdownMenuItem(value: 'house', child: Text('House')),
          ],
          onChanged: (v) => setState(() => _genreFilter = v!),
        ),
        const SizedBox(width: 16),
        _CustomDropdown(
          value: _statusFilter,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Todos los estados')),
            DropdownMenuItem(value: 'upcoming', child: Text('Próximos')),
            DropdownMenuItem(value: 'completed', child: Text('Finalizados')),
          ],
          onChanged: (v) => setState(() => _statusFilter = v!),
        ),
        const SizedBox(width: 16),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: EvioLightColors.border),
          ),
          child: Row(
            children: [
              _ViewToggleButton(
                icon: Icons.grid_view,
                isActive: _isGridView,
                onTap: () => setState(() => _isGridView = true),
              ),
              Container(width: 1, height: 24, color: EvioLightColors.border),
              _ViewToggleButton(
                icon: Icons.view_list,
                isActive: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventsGrid() {
    return Consumer(
      builder: (context, ref, _) {
        final eventsAsync = ref.watch(currentUserEventsProvider);

        return eventsAsync.when(
          data: (events) {
            // ✅ APLICAR FILTROS
            var filtered = events.where((e) {
              // Search
              if (_searchCtrl.text.isNotEmpty) {
                final q = _searchCtrl.text.toLowerCase();
                final matchTitle = e.title.toLowerCase().contains(q);
                final matchVenue = e.venueName.toLowerCase().contains(q);
                final matchArtist = e.mainArtist.toLowerCase().contains(q);
                final matchCity = e.city.toLowerCase().contains(q);
                if (!matchTitle && !matchVenue && !matchArtist && !matchCity) {
                  return false;
                }
              }

              // Genre
              if (_genreFilter != 'all') {
                if (e.genre == null || e.genre!.toLowerCase() != _genreFilter) {
                  return false;
                }
              }

              // Status
              if (_statusFilter == 'upcoming') {
                if (!e.startDatetime.isAfter(DateTime.now())) return false;
              } else if (_statusFilter == 'completed') {
                if (e.startDatetime.isAfter(DateTime.now())) return false;
              }

              return true;
            }).toList();

            // Empty states
            if (events.isEmpty) return const _EmptyStateFirstTime();
            if (filtered.isEmpty) return const _EmptyStateNoResults();

            if (!_isGridView) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, i) => EventListItem(event: filtered[i]),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                int cols = 1;
                if (constraints.maxWidth > 768) cols = 2;
                if (constraints.maxWidth > 1024) cols = 3;
                if (constraints.maxWidth > 1400) cols = 4;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 24,
                    mainAxisExtent: 385, // ✅ Reducido para eliminar espacio
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => EventCard(event: filtered[i]),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(child: Text('Error: $err')),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// HEADER
// -----------------------------------------------------------------------------

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: EvioGradients.headerGradient,
        border: const Border(bottom: BorderSide(color: EvioLightColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EvioLightColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month,
              size: 32,
              color: EvioLightColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gestión de Eventos',
                  style: EvioTypography.displayMedium.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Administra tus eventos de música electrónica',
                  style: TextStyle(color: EvioLightColors.mutedForeground),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () => context.push('/admin/events/new'),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Crear Evento'),
            style: FilledButton.styleFrom(
              backgroundColor: EvioLightColors.primary,
              foregroundColor: EvioLightColors.primaryForeground,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              minimumSize: const Size(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATS SECTION CON DATOS REALES
// -----------------------------------------------------------------------------

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(currentUserEventsProvider);

    return eventsAsync.when(
      data: (events) {
        // 1. Eventos activos (upcoming + published)
        final activeEvents = events
            .where((e) => e.status == EventStatus.upcoming && e.isPublished)
            .toList();

        // 2. Próximo evento (más cercano a hoy)
        final upcomingEvents =
            events
                .where((e) => e.startDatetime.isAfter(DateTime.now()))
                .toList()
              ..sort((a, b) => a.startDatetime.compareTo(b.startDatetime));

        final nextEvent = upcomingEvents.isNotEmpty
            ? upcomingEvents.first
            : null;

        // 3. IDs de eventos activos para stats
        final eventIds = activeEvents.map((e) => e.id).toList();

        // ✅ CRÍTICO: Early return si no hay eventos activos
        if (eventIds.isEmpty) {
          return _StatsGrid(
            ticketsThisWeek: 0,
            activeEventsCount: 0,
            nextEvent: nextEvent,
            avgOccupancy: 0,
          );
        }

        // ✅ Solo watch UNA VEZ con IDs válidos
        final eventIdsStr = eventIds.join(',');
        final statsAsync = ref.watch(multipleEventStatsProvider(eventIdsStr));

        return statsAsync.when(
          data: (statsMap) {
            // Calcular tickets vendidos (total por ahora, TODO: filtrar por semana)
            int ticketsThisWeek = 0;
            for (final stats in statsMap.values) {
              ticketsThisWeek += stats.soldCount;
            }

            // Calcular ocupación promedio
            final occupancies = statsMap.values
                .where((s) => s.totalCapacity > 0)
                .map((s) => s.occupancyPercent.toDouble())
                .toList();

            final avgOccupancy = occupancies.isEmpty
                ? 0.0
                : occupancies.reduce((a, b) => a + b) / occupancies.length;

            return _StatsGrid(
              ticketsThisWeek: ticketsThisWeek,
              activeEventsCount: activeEvents.length,
              nextEvent: nextEvent,
              avgOccupancy: avgOccupancy,
            );
          },
          loading: () => const _StatsGridLoading(),
          error: (_, __) => _StatsGrid(
            ticketsThisWeek: 0,
            activeEventsCount: activeEvents.length,
            nextEvent: nextEvent,
            avgOccupancy: 0,
          ),
        );
      },
      loading: () => const _StatsGridLoading(),
      error: (_, __) => const _StatsGrid(
        ticketsThisWeek: 0,
        activeEventsCount: 0,
        nextEvent: null,
        avgOccupancy: 0,
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int ticketsThisWeek;
  final int activeEventsCount;
  final Event? nextEvent;
  final double avgOccupancy;

  const _StatsGrid({
    required this.ticketsThisWeek,
    required this.activeEventsCount,
    required this.nextEvent,
    required this.avgOccupancy,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        return Flex(
          direction: isDesktop ? Axis.horizontal : Axis.vertical,
          children: [
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: _StatCard(
                label: 'Tickets Esta Semana',
                value: ticketsThisWeek.toString(),
                icon: Icons.confirmation_number,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: _StatCard(
                label: 'Eventos Activos',
                value: activeEventsCount.toString(),
                icon: Icons.event_available,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: _NextEventCard(event: nextEvent),
            ),
            SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: _StatCard(
                label: 'Ocupación Promedio',
                value: '${avgOccupancy.round()}%',
                icon: Icons.trending_up,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatsGridLoading extends StatelessWidget {
  const _StatsGridLoading();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        return Flex(
          direction: isDesktop ? Axis.horizontal : Axis.vertical,
          children: List.generate(
            4,
            (i) => Expanded(
              flex: isDesktop ? 1 : 0,
              child: Container(
                margin: EdgeInsets.only(
                  right: isDesktop && i < 3 ? 16 : 0,
                  bottom: !isDesktop && i < 3 ? 16 : 0,
                ),
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EvioLightColors.border),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvioLightColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: EvioLightColors.border, width: 4.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12.25,
                        color: EvioLightColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: EvioLightColors.foreground,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EvioLightColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 24, color: EvioLightColors.foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextEventCard extends StatelessWidget {
  final Event? event;

  const _NextEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final hasEvent = event != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EvioLightColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: EvioLightColors.border, width: 4.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Próximo Evento',
                      style: TextStyle(
                        fontSize: 12.25,
                        color: EvioLightColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasEvent) ...[
                      Text(
                        event!.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: EvioLightColors.foreground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatEventDate(event!.startDatetime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: EvioLightColors.mutedForeground,
                        ),
                      ),
                    ] else
                      const Text(
                        'Sin eventos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: EvioLightColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: EvioLightColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  size: 24,
                  color: EvioLightColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.inDays == 0) {
      return 'Hoy ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays == 1) {
      return 'Mañana ${DateFormat('HH:mm').format(date)}';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} días - ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd MMM - HH:mm', 'es').format(date);
    }
  }
}

// -----------------------------------------------------------------------------
// BANNER CON DATOS REALES
// -----------------------------------------------------------------------------

class _EventCountBanner extends ConsumerWidget {
  const _EventCountBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(currentUserEventsProvider);

    return eventsAsync.when(
      data: (events) {
        final activeEvents = events
            .where((e) => e.status == EventStatus.upcoming && e.isPublished)
            .toList();

        final eventIds = activeEvents.map((e) => e.id).toList();

        // ✅ CRÍTICO: Early return si no hay eventos activos
        if (eventIds.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: EvioGradients.bannerGradient,
              border: const Border.symmetric(
                horizontal: BorderSide(color: EvioLightColors.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mostrando ${events.length} eventos',
                  style: const TextStyle(
                    fontSize: 14,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: EvioLightColors.border),
                    borderRadius: BorderRadius.circular(6),
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  child: const Text(
                    '0% ocupación general',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final eventIdsStr = eventIds.join(',');
        final statsAsync = ref.watch(multipleEventStatsProvider(eventIdsStr));

        return statsAsync.when(
          data: (statsMap) {
            final occupancies = statsMap.values
                .where((s) => s.totalCapacity > 0)
                .map((s) => s.occupancyPercent)
                .toList();

            final avgOccupancy = occupancies.isEmpty
                ? 0
                : (occupancies.reduce((a, b) => a + b) ~/ occupancies.length);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: EvioGradients.bannerGradient,
                border: const Border.symmetric(
                  horizontal: BorderSide(color: EvioLightColors.border),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mostrando ${events.length} eventos',
                    style: const TextStyle(
                      fontSize: 14,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: EvioLightColors.border),
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    child: Text(
                      '$avgOccupancy% ocupación general',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildBannerSkeleton(events.length),
          error: (_, __) => _buildBannerSkeleton(events.length),
        );
      },
      loading: () => _buildBannerSkeleton(0),
      error: (_, __) => _buildBannerSkeleton(0),
    );
  }

  Widget _buildBannerSkeleton(int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        gradient: EvioGradients.bannerGradient,
        border: const Border.symmetric(
          horizontal: BorderSide(color: EvioLightColors.border),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Mostrando $count eventos',
            style: const TextStyle(
              fontSize: 14,
              color: EvioLightColors.mutedForeground,
            ),
          ),
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// OTROS WIDGETS
// -----------------------------------------------------------------------------

class _CustomDropdown extends StatelessWidget {
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _CustomDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 192,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: EvioLightColors.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: EvioLightColors.mutedForeground,
            size: 16,
          ),
          style: const TextStyle(
            fontSize: 14,
            color: EvioLightColors.foreground,
          ),
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        alignment: Alignment.center,
        color: isActive ? EvioLightColors.inputBackground : Colors.transparent,
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? EvioLightColors.foreground
              : EvioLightColors.mutedForeground,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// EMPTY STATES
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// EMPTY STATES
// -----------------------------------------------------------------------------

class _EmptyStateFirstTime extends StatelessWidget {
  const _EmptyStateFirstTime();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No hay eventos creados',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: EvioLightColors.foreground,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comienza creando tu primer evento de música electrónica',
              style: TextStyle(
                fontSize: 14,
                color: EvioLightColors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/admin/events/new'),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Crear Evento'),
              style: FilledButton.styleFrom(
                backgroundColor: EvioLightColors.primary,
                foregroundColor: EvioLightColors.primaryForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateNoResults extends StatelessWidget {
  const _EmptyStateNoResults();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: EvioLightColors.inputBackground,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off,
                size: 48,
                color: EvioLightColors.mutedForeground,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontraron eventos',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text(
              'Intenta ajustar los filtros de búsqueda o limpia el campo de búsqueda',
              style: TextStyle(color: EvioLightColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
