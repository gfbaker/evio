import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../common/form_card.dart';

enum ImageType { croppedHero, fullFlyer }

class FormPosterCard extends ConsumerStatefulWidget {
  final Uint8List? croppedImageBytes;
  final Uint8List? fullImageBytes;
  final ImageType imageType;
  final Function(ImageType) onImageTypeChanged;
  final VoidCallback onUploadCropped;
  final VoidCallback onUploadFull;
  final VoidCallback onRemove;

  const FormPosterCard({
    required this.croppedImageBytes,
    required this.fullImageBytes,
    required this.imageType,
    required this.onImageTypeChanged,
    required this.onUploadCropped,
    required this.onUploadFull,
    required this.onRemove,
    super.key,
  });

  @override
  ConsumerState<FormPosterCard> createState() => _FormPosterCardState();
}

class _FormPosterCardState extends ConsumerState<FormPosterCard> {
  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Póster del Evento',
      icon: Icons.image_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle de tipo de imagen
          Text(
            'Tipo de Imagen',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: EvioLightColors.foreground,
            ),
          ),
          SizedBox(height: EvioSpacing.sm),
          
          Row(
            children: [
              Expanded(
                child: _buildTypeButton(
                  type: ImageType.croppedHero,
                  icon: Icons.crop,
                  label: 'Recortar Hero',
                  description: 'La imagen se recortará y usará como fondo hero',
                ),
              ),
              SizedBox(width: EvioSpacing.sm),
              Expanded(
                child: _buildTypeButton(
                  type: ImageType.fullFlyer,
                  icon: Icons.image,
                  label: 'Flyer Completo',
                  description: 'El flyer se mostrará completo sin recortar (ideal para posters con lineup)',
                ),
              ),
            ],
          ),
          
          SizedBox(height: EvioSpacing.lg),
          
          // Preview y botones según el tipo
          if (widget.imageType == ImageType.croppedHero)
            _buildCroppedHeroSection()
          else
            _buildFullFlyerSection(),
        ],
      ),
    );
  }

  Widget _buildTypeButton({
    required ImageType type,
    required IconData icon,
    required String label,
    required String description,
  }) {
    final isSelected = widget.imageType == type;
    
    return GestureDetector(
      onTap: () => widget.onImageTypeChanged(type),
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.sm),
        decoration: BoxDecoration(
          color: isSelected ? EvioLightColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(EvioRadius.button),
          border: Border.all(
            color: isSelected ? EvioLightColors.primary : EvioLightColors.border,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : EvioLightColors.foreground,
            ),
            SizedBox(height: EvioSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : EvioLightColors.foreground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCroppedHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen Recortada',
          style: TextStyle(
            fontSize: 12,
            color: EvioLightColors.mutedForeground,
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        
        if (widget.croppedImageBytes != null)
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(EvioRadius.button),
                child: Image.memory(
                  widget.croppedImageBytes!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: EvioSpacing.xs,
                right: EvioSpacing.xs,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.close, size: 20, color: Colors.black87),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                    splashRadius: 20,
                  ),
                ),
              ),
            ],
          )
        else
          GestureDetector(
            onTap: widget.onUploadCropped,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: EvioLightColors.border),
                color: EvioLightColors.background,
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 32,
                    color: EvioLightColors.mutedForeground,
                  ),
                  SizedBox(height: EvioSpacing.xs),
                  Text(
                    'Click para subir imagen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: EvioLightColors.foreground,
                    ),
                  ),
                  Text(
                    'PNG, JPG, GIF hasta 10MB',
                    style: TextStyle(
                      fontSize: 11,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFullFlyerSection() {
    final hasFullImage = widget.fullImageBytes != null;
    final hasCroppedImage = widget.croppedImageBytes != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Paso 1: Flyer completo
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hasFullImage ? EvioLightColors.success : EvioLightColors.mutedForeground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: EvioSpacing.xs),
            Text(
              'Flyer Completo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.foreground,
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.sm),
        
        if (widget.fullImageBytes != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(EvioRadius.button),
                child: Image.memory(
                  widget.fullImageBytes!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                ),
              ),
              Positioned(
                top: EvioSpacing.xs,
                right: EvioSpacing.xs,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: widget.onRemove,
                    icon: Icon(Icons.close, size: 16),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
                ),
              ),
            ],
          )
        else
          ElevatedButton.icon(
            onPressed: widget.onUploadFull,
            icon: Icon(Icons.upload, size: 16),
            label: Text('Subir Flyer Completo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvioLightColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        
        SizedBox(height: EvioSpacing.lg),
        
        // Paso 2: Preview para cards
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hasCroppedImage ? EvioLightColors.success : EvioLightColors.mutedForeground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '2',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: EvioSpacing.xs),
            Text(
              'Preview para Cards',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.foreground,
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.xs),
        Text(
          'Recorta una parte del flyer para mostrar en las cards',
          style: TextStyle(
            fontSize: 11,
            color: EvioLightColors.mutedForeground,
          ),
        ),
        SizedBox(height: EvioSpacing.sm),
        
        if (widget.croppedImageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(EvioRadius.button),
            child: Image.memory(
              widget.croppedImageBytes!,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
          )
        else
          ElevatedButton.icon(
            onPressed: hasFullImage ? widget.onUploadCropped : null,
            icon: Icon(Icons.crop, size: 16),
            label: Text('Recortar Preview'),
            style: ElevatedButton.styleFrom(
              backgroundColor: EvioLightColors.secondary,
              foregroundColor: EvioLightColors.foreground,
            ),
          ),
      ],
    );
  }
}
