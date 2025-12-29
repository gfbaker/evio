import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EventLocationSection extends StatefulWidget {
  final Event event;

  const EventLocationSection({super.key, required this.event});

  @override
  State<EventLocationSection> createState() => _EventLocationSectionState();
}

class _EventLocationSectionState extends State<EventLocationSection> {
  GoogleMapController? _mapController;

  // Tema oscuro de Google Maps
  static const String _darkMapStyle = '''[
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#757575"}]},
    {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#181818"}]},
    {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#8a8a8a"}]},
    {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#373737"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#3c3c3c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]},
    {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d3d3d"}]}
  ]''';

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _openInMaps() async {
    final lat = widget.event.lat ?? 0;
    final lng = widget.event.lng ?? 0;
    
    // URL para abrir en Google Maps/Apple Maps
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.lat == null || widget.event.lng == null) {
      return SizedBox.shrink();
    }

    final location = LatLng(widget.event.lat!, widget.event.lng!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ubicación',
              style: TextStyle(
                color: EvioFanColors.foreground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _openInMaps,
              child: Text(
                'Cómo llegar',
                style: TextStyle(
                  color: EvioFanColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.sm),
        
        // Dirección
        Row(
          children: [
            Icon(Icons.location_on, color: EvioFanColors.mutedForeground, size: 16),
            SizedBox(width: EvioSpacing.xs),
            Expanded(
              child: Text(
                '${widget.event.venueName} · ${widget.event.address}',
                style: TextStyle(
                  color: EvioFanColors.mutedForeground,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.md),
        
        // Mapa
        ClipRRect(
          borderRadius: BorderRadius.circular(EvioRadius.card),
          child: SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: location,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('event-location'),
                  position: location,
                  infoWindow: InfoWindow(
                    title: widget.event.venueName,
                    snippet: widget.event.address,
                  ),
                ),
              },
              onMapCreated: (controller) {
                _mapController = controller;
                // Aplicar tema oscuro
                controller.setMapStyle(_darkMapStyle);
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),
      ],
    );
  }
}
