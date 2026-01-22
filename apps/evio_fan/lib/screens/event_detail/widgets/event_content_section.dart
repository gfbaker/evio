import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:evio_core/evio_core.dart';
import '../../../providers/spotify_provider.dart';
import 'event_location_section.dart';
import 'event_producer_section.dart';
import 'category_tickets_section.dart';

class EventContentSection extends ConsumerStatefulWidget {
  final Event event;
  final AsyncValue<List<TicketCategory>> categoriesAsync;
  final Map<String, int> quantities;
  final Function(String, int) onQuantityChanged;
  final GlobalKey ticketsSectionKey;

  const EventContentSection({
    super.key,
    required this.event,
    required this.categoriesAsync,
    required this.quantities,
    required this.onQuantityChanged,
    required this.ticketsSectionKey,
  });

  @override
  ConsumerState<EventContentSection> createState() => _EventContentSectionState();
}

class _EventContentSectionState extends ConsumerState<EventContentSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    // Empieza casi inmediatamente (sincronizado con hero)
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: EvioSpacing.lg),
            if (widget.event.lineup.isNotEmpty) ...[
              _buildLineUpSection(),
              SizedBox(height: EvioSpacing.xl),
            ],
            if (widget.event.description != null && widget.event.description!.isNotEmpty) ...[
              _buildDescriptionSection(),
              SizedBox(height: EvioSpacing.xl),
            ],
            
            // Sección de tickets con clave para scroll
            Container(
              key: widget.ticketsSectionKey,
              child: CategoryTicketsSection(
                categoriesAsync: widget.categoriesAsync,
                quantities: widget.quantities,
                onQuantityChanged: widget.onQuantityChanged,
              ),
            ),
            
            SizedBox(height: EvioSpacing.xl),
            
            // Ubicación (Maps)
            EventLocationSection(event: widget.event),
            
            SizedBox(height: EvioSpacing.xl),
            
            // Productora
            EventProducerSection(event: widget.event),
          ],
        ),
      ),
    );
  }

  Widget _buildLineUpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Line Up',
          style: TextStyle(
            color: EvioFanColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        SizedBox(
          height: 115,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.event.lineup.length,
            separatorBuilder: (_, __) => SizedBox(width: EvioSpacing.md),
            itemBuilder: (context, index) {
              final artist = widget.event.lineup[index];
              return _ArtistAvatarWidget(
                artist: artist,
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acerca del evento',
          style: TextStyle(
            color: EvioFanColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: EvioSpacing.sm),
        Text(
          widget.event.description!,
          style: TextStyle(
            color: EvioFanColors.mutedForeground,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

/// Widget separado para cada artista con su propia animación de fade-in
class _ArtistAvatarWidget extends ConsumerStatefulWidget {
  final LineupArtist artist;
  final int index;

  const _ArtistAvatarWidget({
    required this.artist,
    required this.index,
  });

  @override
  ConsumerState<_ArtistAvatarWidget> createState() => _ArtistAvatarWidgetState();
}

class _ArtistAvatarWidgetState extends ConsumerState<_ArtistAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _imageReady = false;
  String? _resolvedImageUrl;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  void _resolveImage() {
    // 1. Prioridad: Imagen manual del artista
    if (widget.artist.imageUrl != null && widget.artist.imageUrl!.isNotEmpty) {
      _resolvedImageUrl = widget.artist.imageUrl;
      _precacheAndAnimate();
      return;
    }

    // 2. Buscar en cache de Spotify (ya precargado)
    final cache = ref.read(artistImageCacheProvider);
    if (cache.containsKey(widget.artist.name)) {
      _resolvedImageUrl = cache[widget.artist.name];
      if (_resolvedImageUrl != null) {
        _precacheAndAnimate();
      } else {
        // No hay imagen, mostrar fallback con animación
        _showFallback();
      }
      return;
    }

    // 3. Si no está en cache, buscar en Spotify (fallback)
    // Esto solo debería pasar si el evento no estaba en los primeros 10
    _fetchFromSpotify();
  }

  void _fetchFromSpotify() {
    // Observar el provider - esto hará fetch si no está en cache
    final spotifyAsync = ref.read(artistImageProvider(widget.artist.name).future);
    
    spotifyAsync.then((imageUrl) {
      if (!mounted) return;
      
      if (imageUrl != null) {
        _resolvedImageUrl = imageUrl;
        _precacheAndAnimate();
      } else {
        _showFallback();
      }
    }).catchError((_) {
      if (mounted) _showFallback();
    });
  }

  void _precacheAndAnimate() {
    if (_resolvedImageUrl == null || !mounted || _imageReady) return;
    
    // Precargar la imagen antes de mostrarla
    final imageProvider = CachedNetworkImageProvider(_resolvedImageUrl!);
    precacheImage(imageProvider, context).then((_) {
      if (!mounted || _imageReady) return;
      
      setState(() => _imageReady = true);
      // Delay escalonado basado en índice para efecto cascada
      Future.delayed(Duration(milliseconds: 30 * widget.index), () {
        if (mounted) _fadeController.forward();
      });
    }).catchError((_) {
      // Si falla la carga, mostrar fallback
      if (mounted && !_imageReady) {
        _showFallback();
      }
    });
  }

  void _showFallback() {
    if (!mounted || _imageReady) return;
    
    setState(() {
      _imageReady = true;
      _resolvedImageUrl = null;
    });
    
    Future.delayed(Duration(milliseconds: 30 * widget.index), () {
      if (mounted) _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Avatar con fade-in
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            children: [
              // Fallback/placeholder siempre visible debajo
              _buildFallbackAvatar(),
              
              // Imagen con fade encima (si existe y está cargada)
              if (_resolvedImageUrl != null && _imageReady)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(_resolvedImageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        SizedBox(
          width: 70,
          child: Text(
            widget.artist.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: EvioFanColors.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackAvatar() {
    final name = widget.artist.name;
    final words = name.split(' ');
    final initials = words.length > 1
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
    
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: EvioFanColors.muted,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: EvioFanColors.mutedForeground,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
