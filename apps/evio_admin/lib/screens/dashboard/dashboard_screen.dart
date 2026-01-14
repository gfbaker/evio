import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:evio_core/evio_core.dart';

import '../../providers/event_providers.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/event_card.dart';
import '../../widgets/common/event_list_item.dart';
import '../../widgets/common/producer_onboarding_dialog.dart';

/// Vista activa del dashboard
enum DashboardView { grid, list, kanban }

/// Tab activo de filtro
enum DashboardTab { todos, activos, finalizados }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isDisposed = false;
  final TextEditingController _searchCtrl = TextEditingController();

  DashboardView _currentView = DashboardView.grid;
  DashboardTab _currentTab = DashboardTab.todos;

  // ✅ Listener como función nombrada para poder removerlo correctamente
  void _onSearchChanged() {
    if (!_isDisposed && mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  Future<void> _checkOnboarding() async {
    if (_isDisposed || !mounted) return;

    try {
      final user = await ref
          .read(currentUserProvider.future)
          .timeout(Duration(seconds: 10));

      if (_isDisposed || !mounted) return;

      if (user?.producerId == null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const ProducerOnboardingDialog(),
        );
      }
    } on TimeoutException {
      debugPrint('Timeout checking onboarding status');
    } catch (e) {
      debugPrint('Error checking onboarding: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvioLightColors.surface,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(EvioSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título y subtítulo
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: EvioLightColors.textPrimary,
              ),
            ),
            SizedBox(height: EvioSpacing.xxs),
            Text(
              'Gestiona tus eventos de música electrónica',
              style: TextStyle(
                fontSize: 14,
                color: EvioLightColors.mutedForeground,
              ),
            ),
            
            SizedBox(height: EvioSpacing.xl),
            
            // Stats Section (mantener por ahora)
            const _StatsSection(),
            
            SizedBox(height: EvioSpacing.xxl),
            
            // Sección Mis Eventos
            _buildMisEventosHeader(),
            
            SizedBox(height: EvioSpacing.lg),
            
            // Contenido según vista
            _buildEventsContent(),
            
            SizedBox(height: EvioSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildMisEventosHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título "Mis Eventos"
        Text(
          'Mis Eventos',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: EvioLightColors.textPrimary,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        
        // Row con tabs y controles
        Row(
          children: [
            // Tabs: Todos | Activos | Finalizados
            _buildTabs(),
            
            const Spacer(),
            
            // Search
            _buildSearchField(),
            
            SizedBox(width: EvioSpacing.md),
            
            // View toggle (grid, list, kanban)
            _buildViewToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      children: [
        _TabButton(
          label: 'Todos',
          isActive: _currentTab == DashboardTab.todos,
          onTap: () => setState(() => _currentTab = DashboardTab.todos),
        ),
        SizedBox(width: EvioSpacing.md),
        _TabButton(
          label: 'Activos',
          isActive: _currentTab == DashboardTab.activos,
          onTap: () => setState(() => _currentTab = DashboardTab.activos),
        ),
        SizedBox(width: EvioSpacing.md),
        _TabButton(
          label: 'Finalizados',
          isActive: _currentTab == DashboardTab.finalizados,
          onTap: () => setState(() => _currentTab = DashboardTab.finalizados),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      width: 240,
      height: 40,
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.input),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar eventos...',
          hintStyle: TextStyle(
            color: EvioLightColors.mutedForeground,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 20,
            color: EvioLightColors.mutedForeground,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.sm,
            vertical: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.input),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ViewToggleButton(
            icon: Icons.grid_view_rounded,
            isActive: _currentView == DashboardView.grid,
            onTap: () => setState(() => _currentView = DashboardView.grid),
            isFirst: true,
          ),
          _ViewToggleButton(
            icon: Icons.view_list_rounded,
            isActive: _currentView == DashboardView.list,
            onTap: () => setState(() => _currentView = DashboardView.list),
          ),
          _ViewToggleButton(
            icon: Icons.view_column_rounded,
            isActive: _currentView == DashboardView.kanban,
            onTap: () => setState(() => _currentView = DashboardView.kanban),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsContent() {
    return Consumer(
      builder: (context, ref, _) {
        final eventsAsync = ref.watch(currentUserEventsNotifierProvider);

        return eventsAsync.when(
          data: (events) {
            // Aplicar filtros
            var filtered = _filterEvents(events);

            // Empty states
            if (events.isEmpty) return const _EmptyStateFirstTime();
            if (filtered.isEmpty) return const _EmptyStateNoResults();

            // Renderizar según vista
            switch (_currentView) {
              case DashboardView.grid:
                return _buildGridView(filtered);
              case DashboardView.list:
                return _buildListView(filtered);
              case DashboardView.kanban:
                return _buildKanbanView(events); // Kanban usa todos, no filtered
            }
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

  List<Event> _filterEvents(List<Event> events) {
    return events.where((e) {
      // Search filter
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

      // Tab filter
      switch (_currentTab) {
        case DashboardTab.todos:
          return true;
        case DashboardTab.activos:
          return e.startDatetime.isAfter(DateTime.now()) && e.isPublished;
        case DashboardTab.finalizados:
          return e.startDatetime.isBefore(DateTime.now());
      }
    }).toList();
  }

  Widget _buildGridView(List<Event> events) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int cols = 1;
        if (constraints.maxWidth > 600) cols = 2;
        if (constraints.maxWidth > 900) cols = 3;
        if (constraints.maxWidth > 1200) cols = 4;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: EvioSpacing.lg,
            crossAxisSpacing: EvioSpacing.lg,
            mainAxisExtent: 420,
          ),
          itemCount: events.length,
          itemBuilder: (_, i) => EventCard(event: events[i]),
        );
      },
    );
  }

  Widget _buildListView(List<Event> events) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      separatorBuilder: (_, __) => SizedBox(height: EvioSpacing.sm),
      itemBuilder: (_, i) => EventListItem(event: events[i]),
    );
  }

  Widget _buildKanbanView(List<Event> events) {
    // Separar eventos por estado
    final borradores = events.where((e) => !e.isPublished).toList();
    final proximos = events.where((e) => 
      e.isPublished && e.startDatetime.isAfter(DateTime.now())
    ).toList();
    final finalizados = events.where((e) => 
      e.startDatetime.isBefore(DateTime.now())
    ).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _KanbanColumn(
            title: 'Borradores',
            icon: Icons.edit_note_rounded,
            events: borradores,
            emptyMessage: '0 eventos',
          ),
        ),
        SizedBox(width: EvioSpacing.lg),
        Expanded(
          child: _KanbanColumn(
            title: 'Próximos',
            icon: Icons.calendar_today_rounded,
            events: proximos,
            emptyMessage: '0 eventos',
          ),
        ),
        SizedBox(width: EvioSpacing.lg),
        Expanded(
          child: _KanbanColumn(
            title: 'Finalizados',
            icon: Icons.check_circle_outline_rounded,
            events: finalizados,
            emptyMessage: '0 eventos',
            isGrayscale: true,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB BUTTON
// -----------------------------------------------------------------------------

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(bottom: EvioSpacing.xs),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? EvioLightColors.textPrimary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive 
                ? EvioLightColors.textPrimary 
                : EvioLightColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// VIEW TOGGLE BUTTON
// -----------------------------------------------------------------------------

class _ViewToggleButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _ViewToggleButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.horizontal(
        left: isFirst ? Radius.circular(EvioRadius.input) : Radius.zero,
        right: isLast ? Radius.circular(EvioRadius.input) : Radius.zero,
      ),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? EvioLightColors.accent : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isFirst ? Radius.circular(EvioRadius.input) : Radius.zero,
            right: isLast ? Radius.circular(EvioRadius.input) : Radius.zero,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive
              ? EvioLightColors.accentForeground
              : EvioLightColors.mutedForeground,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// KANBAN COLUMN
// -----------------------------------------------------------------------------

class _KanbanColumn extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Event> events;
  final String emptyMessage;
  final bool isGrayscale;

  const _KanbanColumn({
    required this.title,
    required this.icon,
    required this.events,
    required this.emptyMessage,
    this.isGrayscale = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: EvioLightColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: EvioLightColors.textPrimary,
                ),
              ),
              SizedBox(width: EvioSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: EvioLightColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${events.length} eventos',
                    style: TextStyle(
                      fontSize: 12,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: EvioSpacing.md),
          
          // Events list
          if (events.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(EvioSpacing.xl),
                child: Text(
                  emptyMessage,
                  style: TextStyle(
                    color: EvioLightColors.mutedForeground,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...events.map((e) => Padding(
              padding: EdgeInsets.only(bottom: EvioSpacing.sm),
              child: _KanbanEventCard(event: e, isGrayscale: isGrayscale),
            )),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// KANBAN EVENT CARD
// -----------------------------------------------------------------------------

class _KanbanEventCard extends ConsumerWidget {
  final Event event;
  final bool isGrayscale;

  const _KanbanEventCard({
    required this.event,
    this.isGrayscale = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Obtener stats reales del provider
    final statsAsync = ref.watch(eventStatsProvider(event.id));
    
    final totalCapacity = event.totalCapacity ?? 0;
    final soldCount = statsAsync.maybeWhen(
      data: (stats) => stats.soldCount,
      orElse: () => 0,
    );
    final occupancy = totalCapacity > 0
        ? (soldCount / totalCapacity)
        : 0.0;

    return GestureDetector(
      onTap: () => context.push('/admin/events/${event.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: EvioLightColors.background,
          borderRadius: BorderRadius.circular(EvioRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(EvioRadius.card),
              ),
              child: ColorFiltered(
                colorFilter: isGrayscale
                    ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: event.imageUrl != null
                      ? Image.network(event.imageUrl!, fit: BoxFit.cover)
                      : Container(
                          color: EvioLightColors.muted,
                          child: Icon(Icons.image, color: EvioLightColors.mutedForeground),
                        ),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(EvioSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha badge + Título
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DateBadge(date: event.startDatetime),
                      SizedBox(width: EvioSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: EvioLightColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              event.venueName,
                              style: TextStyle(
                                fontSize: 12,
                                color: EvioLightColors.mutedForeground,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: EvioSpacing.sm),
                  
                  // Badge de estado para finalizados
                  if (isGrayscale)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: EvioSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EvioLightColors.muted,
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: EvioLightColors.mutedForeground),
                          SizedBox(width: 4),
                          Text(
                            'Finalizado',
                            style: TextStyle(
                              fontSize: 11,
                              color: EvioLightColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Genre badge
                    if (event.genre != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: EvioSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EvioLightColors.muted,
                          borderRadius: BorderRadius.circular(EvioRadius.button),
                        ),
                        child: Text(
                          event.genre!,
                          style: TextStyle(
                            fontSize: 11,
                            color: EvioLightColors.textPrimary,
                          ),
                        ),
                      ),
                  ],
                  
                  SizedBox(height: EvioSpacing.sm),
                  
                  // Vendidos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vendidos',
                        style: TextStyle(
                          fontSize: 12,
                          color: EvioLightColors.mutedForeground,
                        ),
                      ),
                      Text(
                        '${soldCount}/${totalCapacity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: EvioLightColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: EvioSpacing.xxs),
                  
                  // Progress bar
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: EvioLightColors.muted,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: occupancy.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isGrayscale 
                              ? EvioLightColors.mutedForeground 
                              : EvioLightColors.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DATE BADGE
// -----------------------------------------------------------------------------

class _DateBadge extends StatelessWidget {
  final DateTime date;

  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final day = date.day.toString();
    final month = DateFormat('MMM', 'es').format(date).toUpperCase();

    return Container(
      width: 44,
      padding: EdgeInsets.symmetric(vertical: EvioSpacing.xs),
      decoration: BoxDecoration(
        color: EvioLightColors.muted,
        borderRadius: BorderRadius.circular(EvioRadius.button),
      ),
      child: Column(
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: EvioLightColors.textPrimary,
              height: 1,
            ),
          ),
          Text(
            month,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: EvioLightColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// STATS SECTION
// -----------------------------------------------------------------------------

class _StatsSection extends ConsumerWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(currentUserEventsNotifierProvider);

    return eventsAsync.when(
      data: (events) {
        final activeEvents = events
            .where((e) => e.status == EventStatus.upcoming && e.isPublished)
            .toList();

        final upcomingEvents = events
            .where((e) => e.startDatetime.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.startDatetime.compareTo(b.startDatetime));

        final nextEvent = upcomingEvents.isNotEmpty ? upcomingEvents.first : null;

        final eventIds = activeEvents.map((e) => e.id).toList();

        if (eventIds.isEmpty) {
          return _StatsGrid(
            ticketsThisWeek: 0,
            activeEventsCount: 0,
            nextEvent: nextEvent,
            avgOccupancy: 0,
          );
        }

        final eventIdsStr = eventIds.join(',');
        final statsAsync = ref.watch(multipleEventStatsProvider(eventIdsStr));

        return statsAsync.when(
          data: (statsMap) {
            int ticketsThisWeek = 0;
            for (final stats in statsMap.values) {
              ticketsThisWeek += stats.soldCount;
            }

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
                icon: Icons.confirmation_number_outlined,
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 0, height: isDesktop ? 0 : 16),
            Expanded(
              flex: isDesktop ? 1 : 0,
              child: _StatCard(
                label: 'Eventos Activos',
                value: activeEventsCount.toString(),
                icon: Icons.event_available_outlined,
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
                icon: Icons.trending_up_rounded,
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
                  color: EvioLightColors.card,
                  borderRadius: BorderRadius.circular(EvioRadius.card),
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
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EvioLightColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(EvioRadius.button),
            ),
            child: Icon(
              icon,
              size: 24,
              color: EvioLightColors.textPrimary,
            ),
          ),
          SizedBox(width: EvioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EvioLightColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(EvioRadius.button),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 24,
              color: EvioLightColors.textPrimary,
            ),
          ),
          SizedBox(width: EvioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasEvent) ...[
                  Text(
                    event!.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: EvioLightColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _formatEventDate(event!.startDatetime),
                    style: TextStyle(
                      fontSize: 12,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                ] else
                  Text(
                    'Sin eventos próximos',
                    style: TextStyle(
                      fontSize: 14,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                backgroundColor: EvioLightColors.accent,
                foregroundColor: EvioLightColors.accentForeground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.button),
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
              decoration: BoxDecoration(
                color: EvioLightColors.muted,
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
              'Intenta ajustar los filtros de búsqueda',
              style: TextStyle(color: EvioLightColors.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
