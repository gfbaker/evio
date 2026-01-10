import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerDialog extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerDialog({
    this.initialLat,
    this.initialLng,
    super.key,
  });

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  final _searchCtrl = TextEditingController();
  GoogleMapController? _mapController;
  bool _isDisposed = false;
  
  late LatLng _selectedLocation;
  String _selectedVenue = '';
  String _selectedAddress = '';
  String _selectedCity = 'Mendoza, Argentina';

  // Ubicaciones sugeridas de Mendoza
  final List<SuggestedVenue> _suggestedVenues = [
    SuggestedVenue(
      name: 'Arena Maipú',
      address: 'Lateral Sur Acceso Este 2520',
      city: 'Maipú, Mendoza',
      lat: -32.9833,
      lng: -68.7833,
    ),
    SuggestedVenue(
      name: 'Estadio Malvinas Argentinas',
      address: 'Av. Libertador 3000',
      city: 'Godoy Cruz, Mendoza',
      lat: -32.8833,
      lng: -68.8500,
    ),
    SuggestedVenue(
      name: 'Nave Cultural',
      address: 'Av. Las Heras 340',
      city: 'Mendoza Capital',
      lat: -32.8908,
      lng: -68.8436,
    ),
    SuggestedVenue(
      name: 'Club Español',
      address: 'Av. España 1014',
      city: 'Mendoza Capital',
      lat: -32.8856,
      lng: -68.8472,
    ),
    SuggestedVenue(
      name: 'Espacio Cultural Le Parc',
      address: 'Av. San Martín 1046',
      city: 'Mendoza Capital',
      lat: -32.8899,
      lng: -68.8456,
    ),
  ];

  List<SuggestedVenue> _filteredVenues = [];

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(
      widget.initialLat ?? -32.8895,
      widget.initialLng ?? -68.8458,
    );
    _filteredVenues = _suggestedVenues;
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    
    // ✅ Try-catch para prevenir error de google_maps_flutter_web
    if (_mapController != null) {
      try {
        _mapController?.dispose();
      } catch (e) {
        // Ignorar error de dispose de google_maps_flutter_web
        // "Maps cannot be retrieved before calling buildView!"
        debugPrint('⚠️ MapController dispose error (ignorado): $e');
      }
    }
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase();
    if (query.isEmpty) {
      setState(() => _filteredVenues = _suggestedVenues);
    } else {
      setState(() {
        _filteredVenues = _suggestedVenues
            .where((v) =>
                v.name.toLowerCase().contains(query) ||
                v.address.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  void _onVenueSelected(SuggestedVenue venue) {
    final newLocation = LatLng(venue.lat, venue.lng);
    
    setState(() {
      _selectedLocation = newLocation;
      _selectedVenue = venue.name;
      _selectedAddress = venue.address;
      _selectedCity = venue.city;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(newLocation, 16),
    );
  }

  Future<void> _onMapTap(LatLng position) async {
    setState(() {
      _selectedLocation = position;
      _selectedVenue = 'Ubicación personalizada';
      _selectedAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}';
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty && mounted && !_isDisposed) {
        final placemark = placemarks.first;
        setState(() {
          _selectedVenue = placemark.name ?? 'Ubicación personalizada';
          _selectedAddress = placemark.street ?? _selectedAddress;
          _selectedCity = '${placemark.locality ?? 'Mendoza'}, ${placemark.administrativeArea ?? 'Mendoza'}';
        });
      }
    } catch (e) {
      // Ignorar errores de geocoding
    }
  }

  void _confirm() {
    context.pop({
      'venue': _selectedVenue.isEmpty ? 'Ubicación personalizada' : _selectedVenue,
      'address': _selectedAddress.isEmpty ? 
          'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}' : 
          _selectedAddress,
      'city': _selectedCity,
      'lat': _selectedLocation.latitude,
      'lng': _selectedLocation.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: SizedBox(
        width: 900,
        height: 600,
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(EvioSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Seleccionar Ubicación', style: EvioTypography.h3),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: EvioLightColors.border),

            // Info
            Padding(
              padding: EdgeInsets.all(EvioSpacing.md),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: EvioLightColors.mutedForeground),
                  SizedBox(width: EvioSpacing.xs),
                  Expanded(
                    child: Text(
                      'Busca en las sugerencias o haz click en el mapa.',
                      style: TextStyle(fontSize: 12, color: EvioLightColors.mutedForeground),
                    ),
                  ),
                ],
              ),
            ),

            // Map + Suggestions
            Expanded(
              child: Row(
                children: [
                  // Google Map
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: EdgeInsets.only(
                        left: EvioSpacing.md,
                        bottom: EvioSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(EvioRadius.card),
                        border: Border.all(color: EvioLightColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(EvioRadius.card),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation,
                            zoom: 13,
                          ),
                          markers: {
                            Marker(
                              markerId: MarkerId('selected'),
                              position: _selectedLocation,
                              draggable: true,
                              onDragEnd: _onMapTap,
                            ),
                          },
                          onMapCreated: (controller) {
                            if (!_isDisposed) {
                              _mapController = controller;
                            }
                          },
                          onTap: _onMapTap,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                        ),
                      ),
                    ),
                  ),

                  // Suggestions Panel
                  Expanded(
                    flex: 1,
                    child: Container(
                      margin: EdgeInsets.only(
                        left: EvioSpacing.md,
                        right: EvioSpacing.md,
                        bottom: EvioSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: EvioLightColors.surface,
                        border: Border.all(color: EvioLightColors.border),
                        borderRadius: BorderRadius.circular(EvioRadius.card),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search bar
                          Padding(
                            padding: EdgeInsets.all(EvioSpacing.sm),
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Buscar lugar...',
                                hintStyle: TextStyle(fontSize: 13),
                                prefixIcon: Icon(Icons.search, size: 18),
                                suffixIcon: _searchCtrl.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(EvioRadius.input),
                                  borderSide: BorderSide(color: EvioLightColors.border),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: EvioSpacing.sm,
                                  vertical: EvioSpacing.xs,
                                ),
                              ),
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          
                          Divider(height: 1, color: EvioLightColors.border),
                          
                          Padding(
                            padding: EdgeInsets.all(EvioSpacing.sm),
                            child: Text(
                              'Lugares populares',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: EvioLightColors.mutedForeground,
                              ),
                            ),
                          ),
                          
                          // Venues list
                          Expanded(
                            child: ListView.separated(
                              padding: EdgeInsets.symmetric(horizontal: EvioSpacing.xs),
                              itemCount: _filteredVenues.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: EvioLightColors.border,
                              ),
                              itemBuilder: (context, index) {
                                final venue = _filteredVenues[index];
                                final isSelected = venue.name == _selectedVenue;
                                
                                return InkWell(
                                  onTap: () => _onVenueSelected(venue),
                                  child: Container(
                                    padding: EdgeInsets.all(EvioSpacing.sm),
                                    color: isSelected
                                        ? EvioLightColors.primary.withValues(alpha: 0.1)
                                        : null,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: isSelected
                                              ? EvioLightColors.primary
                                              : EvioLightColors.mutedForeground,
                                        ),
                                        SizedBox(width: EvioSpacing.sm),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                venue.name,
                                                style: TextStyle(
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  fontSize: 13,
                                                  color: isSelected
                                                      ? EvioLightColors.primary
                                                      : EvioLightColors.foreground,
                                                ),
                                              ),
                                              Text(
                                                venue.address,
                                                style: TextStyle(
                                                  fontSize: 11,
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
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(EvioSpacing.md),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: EvioLightColors.border)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVenue.isEmpty ? 'Ubicación personalizada' : _selectedVenue,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (_selectedAddress.isNotEmpty)
                          Text(
                            _selectedAddress,
                            style: TextStyle(
                              fontSize: 11,
                              color: EvioLightColors.mutedForeground,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        child: Text('Cancelar'),
                      ),
                      SizedBox(width: EvioSpacing.sm),
                      FilledButton(
                        onPressed: _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: EvioLightColors.primary,
                        ),
                        child: Text('Confirmar'),
                      ),
                    ],
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

class SuggestedVenue {
  final String name;
  final String address;
  final String city;
  final double lat;
  final double lng;

  SuggestedVenue({
    required this.name,
    required this.address,
    required this.city,
    required this.lat,
    required this.lng,
  });
}
