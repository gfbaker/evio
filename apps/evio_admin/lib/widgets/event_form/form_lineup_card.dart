import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../common/form_card.dart';
import '../common/simple_input.dart';
import '../../providers/spotify_provider.dart';

class FormLineupCard extends ConsumerStatefulWidget {
  final List<LineupArtist> lineup;
  final Function(String name, bool isHeadliner, String? imageUrl) onAdd;
  final Function(int index) onRemove;
  final Function(int index) onToggleHeadliner;

  const FormLineupCard({
    required this.lineup,
    required this.onAdd,
    required this.onRemove,
    required this.onToggleHeadliner,
    super.key,
  });

  @override
  ConsumerState<FormLineupCard> createState() => _FormLineupCardState();
}

class _FormLineupCardState extends ConsumerState<FormLineupCard> {
  final _artistCtrl = TextEditingController();
  bool _isNewHeadliner = false;
  bool _isAdding = false;

  @override
  void dispose() {
    _artistCtrl.dispose();
    super.dispose();
  }

  Future<void> _addArtist() async {
    if (_artistCtrl.text.isEmpty || _isAdding) return;

    setState(() => _isAdding = true);

    try {
      // Obtener imagen de Spotify
      final spotify = ref.read(spotifyServiceProvider);
      final imageUrl = await spotify.getArtistImageUrl(_artistCtrl.text);

      // Agregar artista con imageUrl
      widget.onAdd(_artistCtrl.text, _isNewHeadliner, imageUrl);
      
      _artistCtrl.clear();
      setState(() => _isNewHeadliner = false);
    } catch (e) {
      debugPrint('⚠️ Error getting Spotify image: $e');
      // Agregar sin imagen si falla
      widget.onAdd(_artistCtrl.text, _isNewHeadliner, null);
      _artistCtrl.clear();
      setState(() => _isNewHeadliner = false);
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'DJ Line-up',
      icon: Icons.music_note_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SimpleInput(
                  controller: _artistCtrl,
                  hint: 'Nombre del DJ/Artista',
                  isWhite: false,
                ),
              ),
              SizedBox(width: EvioSpacing.xs),
              IconButton(
                onPressed: () =>
                    setState(() => _isNewHeadliner = !_isNewHeadliner),
                icon: Icon(
                  _isNewHeadliner ? Icons.star : Icons.star_outline,
                  color: _isNewHeadliner
                      ? Colors.amber
                      : EvioLightColors.mutedForeground,
                ),
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                  side: BorderSide(color: EvioLightColors.border),
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(width: EvioSpacing.xs),
              FilledButton.icon(
                onPressed: _isAdding ? null : _addArtist,
                icon: _isAdding 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(Icons.add, size: 16),
                label: Text(_isAdding ? 'Buscando...' : 'Agregar'),
                style: FilledButton.styleFrom(
                  backgroundColor: EvioLightColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                  fixedSize: Size.fromHeight(42),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Usa el botón ☆ para marcar el artista principal (headliner)',
            style: TextStyle(
              fontSize: 11,
              color: EvioLightColors.mutedForeground,
            ),
          ),
          if (widget.lineup.isNotEmpty) ...[
            SizedBox(height: EvioSpacing.md),
            ...widget.lineup.asMap().entries.map((entry) {
              final index = entry.key;
              final artist = entry.value;
              return _buildArtistRow(artist, index);
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildArtistRow(LineupArtist artist, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.xs),
      padding: EdgeInsets.all(EvioSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: EvioLightColors.border),
        borderRadius: BorderRadius.circular(EvioRadius.button),
      ),
      child: Row(
        children: [
          Icon(
            Icons.drag_indicator,
            color: EvioLightColors.border,
            size: EvioSpacing.iconM,
          ),
          SizedBox(width: EvioSpacing.sm),
          
          // Avatar con imagen de Spotify (guardada)
          artist.imageUrl != null
              ? Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(artist.imageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              : _buildFallbackAvatar(artist.name),
          
          SizedBox(width: EvioSpacing.sm),
          Text(
            artist.name,
            style: TextStyle(
              fontWeight: artist.isHeadliner
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          if (artist.isHeadliner) ...[
            SizedBox(width: EvioSpacing.xs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'HEADLINER',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.amber[900],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          Spacer(),
          IconButton(
            icon: Icon(
              artist.isHeadliner ? Icons.star : Icons.star_border,
              size: EvioSpacing.iconM,
              color: artist.isHeadliner ? Colors.amber : Colors.grey,
            ),
            onPressed: () => widget.onToggleHeadliner(index),
            constraints: BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          SizedBox(width: EvioSpacing.md),
          InkWell(
            onTap: () => widget.onRemove(index),
            child: Icon(
              Icons.delete_outline,
              size: 18,
              color: EvioLightColors.destructive,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar(String name) {
    final words = name.split(' ');
    final initials = words.length > 1
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: EvioLightColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
