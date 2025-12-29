import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import 'package:go_router/go_router.dart';
import '../../providers/search_providers.dart';
import '../../providers/location_provider.dart';
import 'package:geolocator/geolocator.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!_isDisposed) {
        ref.read(searchNotifierProvider.notifier).setQuery(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchNotifierProvider);

    return Scaffold(
      backgroundColor: EvioFanColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(EvioSpacing.md),
              child: Column(
                children: [
                  _buildSearchBar(),
                  SizedBox(height: EvioSpacing.sm),
                  _buildFilterChips(searchState),
                ],
              ),
            ),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: EvioFanColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.input),
        border: Border.all(color: EvioFanColors.border, width: 1),
      ),
      child: TextField(
        controller: _searchController,
        style: EvioTypography.bodyLarge.copyWith(color: EvioFanColors.foreground),
        decoration: InputDecoration(
          hintText: 'Eventos, bandas u organizadores',
          hintStyle: EvioTypography.bodyLarge.copyWith(
            color: EvioFanColors.secondary,
          ),
          prefixIcon: Icon(Icons.search, color: EvioFanColors.secondary),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: EvioFanColors.secondary),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(searchNotifierProvider.notifier).setQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.md,
            vertical: EvioSpacing.sm,
          ),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFilterChips(SearchState searchState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: searchState.venueName != null ? 'Ubicación ✓' : 'Ubicación',
            icon: Icons.location_on_outlined,
            isSelected: searchState.venueName != null,
            onTap: _showVenueFilter,
          ),
          SizedBox(width: EvioSpacing.xs),
          _buildFilterChip(
            label: searchState.date != null ? 'Fecha ✓' : 'Fecha',
            icon: Icons.calendar_today_outlined,
            isSelected: searchState.date != null,
            onTap: _showDateFilter,
          ),
          SizedBox(width: EvioSpacing.xs),
          _buildFilterChip(
            label: 'Nuevos eventos',
            icon: Icons.fiber_new_outlined,
            isSelected: false,
            onTap: () {},
          ),
          SizedBox(width: EvioSpacing.xs),
          _buildFilterChip(
            label: 'Eventos cercanos',
            icon: Icons.near_me_outlined,
            isSelected: searchState.nearbyMode,
            onTap: _toggleNearbyMode,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: EvioSpacing.md,
          vertical: EvioSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? EvioFanColors.primary : EvioFanColors.card,
          borderRadius: BorderRadius.circular(EvioRadius.button),
          border: Border.all(
            color: isSelected ? EvioFanColors.primary : EvioFanColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? EvioFanColors.background
                  : EvioFanColors.secondary,
            ),
            SizedBox(width: EvioSpacing.xxs),
            Text(
              label,
              style: EvioTypography.labelLarge.copyWith(
                color: isSelected
                    ? EvioFanColors.background
                    : EvioFanColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final eventsAsync = ref.watch(filteredEventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return _buildEmptyState();
        }

        final groupedEvents = _groupEventsByDate(events);

        return ListView.builder(
          padding: EdgeInsets.all(EvioSpacing.md),
          itemCount: groupedEvents.length,
          itemBuilder: (context, index) {
            final entry = groupedEvents.entries.elementAt(index);
            return _buildDateSection(entry.key, entry.value);
          },
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      ),
      error: (error, stack) => Center(
        child: Text(
          'Error: $error',
          style: EvioTypography.bodyLarge.copyWith(
            color: EvioFanColors.secondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection(String dateLabel, List<Event> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: EvioSpacing.sm),
          child: Text(
            dateLabel,
            style: EvioTypography.h3.copyWith(color: EvioFanColors.foreground),
          ),
        ),
        ...events.map((event) => _buildEventCard(event)),
        SizedBox(height: EvioSpacing.lg),
      ],
    );
  }

  Widget _buildEventCard(Event event) {
    return InkWell(
      onTap: () => context.push('/event/${event.id}'),
      borderRadius: BorderRadius.circular(EvioRadius.card),
      child: Container(
        margin: EdgeInsets.only(bottom: EvioSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(EvioRadius.card),
              child: Image.network(
                event.imageUrl ?? '',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: EvioFanColors.card,
                  child: Icon(
                    Icons.image_outlined,
                    color: EvioFanColors.secondary,
                  ),
                ),
              ),
            ),
            SizedBox(width: EvioSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: EvioTypography.h4.copyWith(
                      color: EvioFanColors.foreground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: EvioSpacing.xxs),
                  Text(
                    _formatTime(event.startDatetime),
                    style: EvioTypography.bodyMedium.copyWith(
                      color: EvioFanColors.foreground,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.xxs),
                  Text(
                    '${event.city} · ${event.venueName}',
                    style: EvioTypography.caption.copyWith(
                      color: EvioFanColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: EvioFanColors.secondary),
          SizedBox(height: EvioSpacing.md),
          Text(
            'No se encontraron eventos',
            style: EvioTypography.h3.copyWith(
              color: EvioFanColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<Event>> _groupEventsByDate(List<Event> events) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));

    final Map<String, List<Event>> grouped = {};
    
    final weekDays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    for (final event in events) {
      final eventDate = DateTime(
        event.startDatetime.year,
        event.startDatetime.month,
        event.startDatetime.day,
      );

      String label;
      if (eventDate == today) {
        label = 'Hoy - ${event.startDatetime.day.toString().padLeft(2, '0')}.${event.startDatetime.month.toString().padLeft(2, '0')}';
      } else if (eventDate == tomorrow) {
        label = 'Mañana - ${event.startDatetime.day.toString().padLeft(2, '0')}.${event.startDatetime.month.toString().padLeft(2, '0')}';
      } else {
        // ✅ Nombre del día - DD.MM
        final dayName = weekDays[event.startDatetime.weekday - 1];
        label = '$dayName - ${event.startDatetime.day.toString().padLeft(2, '0')}.${event.startDatetime.month.toString().padLeft(2, '0')}';
      }

      grouped.putIfAbsent(label, () => []);
      grouped[label]!.add(event);
    }

    return grouped;
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} hs';
  }

  // TODO: Implementar filtro por productora
  // ignore: unused_element
  void _showProducerFilter() {
    final currentProducerId = ref.read(searchNotifierProvider).producerId;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProducerFilterSheet(
        currentProducerId: currentProducerId,
        onSelect: (producerId) {
          // Si selecciona el mismo, lo desactiva
          if (currentProducerId == producerId) {
            ref.read(searchNotifierProvider.notifier).setProducer(null);
          } else {
            ref.read(searchNotifierProvider.notifier).setProducer(producerId);
          }
          Navigator.pop(context);
        },
        onClear: () {
          ref.read(searchNotifierProvider.notifier).setProducer(null);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showVenueFilter() {
    final currentVenue = ref.read(searchNotifierProvider).venueName;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _VenueFilterSheet(
        currentVenue: currentVenue,
        onSelect: (venueName) {
          // Si selecciona el mismo, lo desactiva
          if (currentVenue == venueName) {
            ref.read(searchNotifierProvider.notifier).setVenue(null);
          } else {
            ref.read(searchNotifierProvider.notifier).setVenue(venueName);
          }
          Navigator.pop(context);
        },
        onClear: () {
          ref.read(searchNotifierProvider.notifier).setVenue(null);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDateFilter() async {
    final currentDate = ref.read(searchNotifierProvider).date;
    
    // Si ya hay fecha seleccionada y toca el chip, desactiva
    if (currentDate != null) {
      ref.read(searchNotifierProvider.notifier).setDate(null);
      return;
    }
    
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: EvioFanColors.primary,
              surface: EvioFanColors.card,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && !_isDisposed) {
      ref.read(searchNotifierProvider.notifier).setDate(picked);
    }
  }

  void _toggleNearbyMode() async {
    final currentMode = ref.read(searchNotifierProvider).nearbyMode;
    
    // Si ya está activo, desactivar
    if (currentMode) {
      ref.read(searchNotifierProvider.notifier).setNearbyMode(false);
      return;
    }
    
    // Solicitar permiso y activar
    final locationService = ref.read(locationServiceProvider);
    
    // Verificar si el servicio está habilitado
    final serviceEnabled = await locationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      _showLocationServiceDialog();
      return;
    }
    
    // Verificar permisos
    LocationPermission permission = await locationService.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await locationService.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      _showPermissionDeniedForeverDialog();
      return;
    }
    
    // ✅ Permiso concedido, activar modo nearby
    ref.read(searchNotifierProvider.notifier).setNearbyMode(true);
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvioFanColors.card,
        title: Text(
          'Ubicación desactivada',
          style: TextStyle(color: EvioFanColors.foreground),
        ),
        content: Text(
          'Para mostrar eventos cercanos, activa los servicios de ubicación en tu dispositivo.',
          style: TextStyle(color: EvioFanColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(locationServiceProvider).openLocationSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: EvioFanColors.primary,
            ),
            child: Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvioFanColors.card,
        title: Text(
          'Permiso denegado',
          style: TextStyle(color: EvioFanColors.foreground),
        ),
        content: Text(
          'Necesitamos acceso a tu ubicación para mostrarte eventos cercanos.',
          style: TextStyle(color: EvioFanColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: EvioFanColors.card,
        title: Text(
          'Permiso bloqueado',
          style: TextStyle(color: EvioFanColors.foreground),
        ),
        content: Text(
          'Has bloqueado el acceso a la ubicación. Para usar esta función, debes habilitar el permiso en la configuración de la app.',
          style: TextStyle(color: EvioFanColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(locationServiceProvider).openAppSettings();
            },
            style: FilledButton.styleFrom(
              backgroundColor: EvioFanColors.primary,
            ),
            child: Text('Abrir Ajustes'),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet para Productoras
class _ProducerFilterSheet extends ConsumerWidget {
  final String? currentProducerId;
  final Function(String producerId) onSelect;
  final VoidCallback onClear;

  const _ProducerFilterSheet({
    required this.currentProducerId,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final producersAsync = ref.watch(producersListProvider);

    return Container(
      decoration: BoxDecoration(
        color: EvioFanColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EvioRadius.card),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(EvioSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seleccionar Productora',
                  style: EvioTypography.h3.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text('Limpiar', style: EvioTypography.button),
                ),
              ],
            ),
          ),
          Divider(color: EvioFanColors.border, height: 1),
          producersAsync.when(
            data: (producers) => ListView.builder(
              shrinkWrap: true,
              itemCount: producers.length,
              itemBuilder: (context, index) {
                final producer = producers[index];
                final isSelected = currentProducerId == producer.id;
                
                return ListTile(
                  title: Text(
                    producer.name,
                    style: EvioTypography.bodyLarge.copyWith(
                      color: isSelected 
                        ? EvioFanColors.primary 
                        : EvioFanColors.foreground,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected 
                    ? Icon(Icons.check, color: EvioFanColors.primary)
                    : null,
                  onTap: () => onSelect(producer.id),
                );
              },
            ),
            loading: () => Padding(
              padding: EdgeInsets.all(EvioSpacing.xl),
              child: CircularProgressIndicator(color: EvioFanColors.primary),
            ),
            error: (_, __) => Padding(
              padding: EdgeInsets.all(EvioSpacing.md),
              child: Text('Error al cargar productoras'),
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet para Venues
class _VenueFilterSheet extends ConsumerWidget {
  final String? currentVenue;
  final Function(String venueName) onSelect;
  final VoidCallback onClear;

  const _VenueFilterSheet({
    required this.currentVenue,
    required this.onSelect,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(venuesListProvider);

    return Container(
      decoration: BoxDecoration(
        color: EvioFanColors.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(EvioRadius.card),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(EvioSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seleccionar Lugar',
                  style: EvioTypography.h3.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: Text('Limpiar', style: EvioTypography.button),
                ),
              ],
            ),
          ),
          Divider(color: EvioFanColors.border, height: 1),
          venuesAsync.when(
            data: (venues) => ListView.builder(
              shrinkWrap: true,
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
                final isSelected = currentVenue == venue;
                
                return ListTile(
                  title: Text(
                    venue,
                    style: EvioTypography.bodyLarge.copyWith(
                      color: isSelected 
                        ? EvioFanColors.primary 
                        : EvioFanColors.foreground,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected 
                    ? Icon(Icons.check, color: EvioFanColors.primary)
                    : null,
                  onTap: () => onSelect(venue),
                );
              },
            ),
            loading: () => Padding(
              padding: EdgeInsets.all(EvioSpacing.xl),
              child: CircularProgressIndicator(color: EvioFanColors.primary),
            ),
            error: (_, __) => Padding(
              padding: EdgeInsets.all(EvioSpacing.md),
              child: Text('Error al cargar lugares'),
            ),
          ),
        ],
      ),
    );
  }
}
