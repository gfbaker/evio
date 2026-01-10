import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

class ImageCropperDialog extends StatefulWidget {
  final Uint8List imageBytes;

  const ImageCropperDialog({required this.imageBytes, super.key});

  @override
  State<ImageCropperDialog> createState() => _ImageCropperDialogState();
}

class _ImageCropperDialogState extends State<ImageCropperDialog> {
  final TransformationController _controller = TransformationController();
  double _zoom = 1.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(EvioSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recortar Imagen', style: EvioTypography.h3),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close, size: EvioSpacing.iconM),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: EvioLightColors.border),

            // Crop area
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Color(0xFF18181B)),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Interactive image
                    InteractiveViewer(
                      transformationController: _controller,
                      minScale: 1.0,
                      maxScale: 4.0,
                      boundaryMargin: EdgeInsets.all(double.infinity),
                      onInteractionUpdate: (details) {
                        setState(() {
                          _zoom = _controller.value.getMaxScaleOnAxis();
                        });
                      },
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Dark overlay with crop window
                    IgnorePointer(
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.7),
                          BlendMode.srcOut,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                backgroundBlendMode: BlendMode.dstOut,
                              ),
                            ),
                            Center(
                              child: Container(
                                width: 480,
                                height: 270,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Crop grid
                    IgnorePointer(
                      child: Container(
                        width: 480,
                        height: 270,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Spacer(),
                                  VerticalDivider(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  Spacer(),
                                  VerticalDivider(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  Spacer(),
                                ],
                              ),
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.3),
                              height: 1,
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Spacer(),
                                  VerticalDivider(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  Spacer(),
                                  VerticalDivider(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  Spacer(),
                                ],
                              ),
                            ),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.3),
                              height: 1,
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Spacer(),
                                  VerticalDivider(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  Spacer(),
                                  VerticalDivider(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                  Spacer(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer controls
            Container(
              padding: EdgeInsets.all(EvioSpacing.md),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: EvioLightColors.border)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.zoom_out,
                    size: EvioSpacing.iconM,
                    color: EvioLightColors.mutedForeground,
                  ),
                  Expanded(
                    child: Slider(
                      value: _zoom.clamp(1.0, 4.0),
                      min: 1.0,
                      max: 4.0,
                      activeColor: EvioLightColors.primary,
                      inactiveColor: EvioLightColors.border,
                      onChanged: (value) {
                        setState(() => _zoom = value);
                        _controller.value = Matrix4.identity()..scale(value);
                      },
                    ),
                  ),
                  Icon(
                    Icons.zoom_in,
                    size: EvioSpacing.iconM,
                    color: EvioLightColors.mutedForeground,
                  ),
                  SizedBox(width: EvioSpacing.xl),
                  OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EvioLightColors.foreground,
                      side: BorderSide(color: EvioLightColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                    ),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  FilledButton.icon(
                    onPressed: () => context.pop(widget.imageBytes),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Aplicar Recorte'),
                    style: FilledButton.styleFrom(
                      backgroundColor: EvioLightColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EvioRadius.button),
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
