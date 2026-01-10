import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import '../common/form_card.dart';

class FormVideoCard extends StatefulWidget {
  final String? videoUrl;
  final Function(String?) onChanged;

  const FormVideoCard({
    required this.videoUrl,
    required this.onChanged,
    super.key,
  });

  @override
  State<FormVideoCard> createState() => _FormVideoCardState();
}

class _FormVideoCardState extends State<FormVideoCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.videoUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormCard(
      title: 'Video Destacado',
      icon: Icons.play_circle_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explicación
          Container(
            padding: EdgeInsets.all(EvioSpacing.sm),
            decoration: BoxDecoration(
              color: EvioLightColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(EvioRadius.button),
              border: Border.all(
                color: EvioLightColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: EvioLightColors.info,
                ),
                SizedBox(width: EvioSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Qué es esto?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: EvioLightColors.info,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Agrega un video de YouTube para mostrar en el detalle del evento. Puede ser un set del artista principal, un trailer del evento, o cualquier contenido relacionado.',
                        style: TextStyle(
                          fontSize: 12,
                          color: EvioLightColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: EvioSpacing.md),
          
          // Input de URL
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: EvioLightColors.inputBackground,
              borderRadius: BorderRadius.circular(EvioRadius.input),
            ),
            child: TextField(
              controller: _controller,
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'https://www.youtube.com/watch?v=...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.sm,
                  vertical: 10,
                ),
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              onChanged: (value) {
                widget.onChanged(value.isEmpty ? null : value);
              },
            ),
          ),
          
          SizedBox(height: EvioSpacing.xs),
          
          // Ejemplo
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: EvioLightColors.mutedForeground,
              ),
              SizedBox(width: 4),
              Text(
                'Ejemplo: https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                style: TextStyle(
                  fontSize: 11,
                  color: EvioLightColors.mutedForeground,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          
          // Preview si hay URL
          if (_controller.text.isNotEmpty) ...[
            SizedBox(height: EvioSpacing.md),
            Container(
              padding: EdgeInsets.all(EvioSpacing.sm),
              decoration: BoxDecoration(
                color: EvioLightColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(EvioRadius.button),
                border: Border.all(
                  color: EvioLightColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: EvioLightColors.success,
                  ),
                  SizedBox(width: EvioSpacing.xs),
                  Expanded(
                    child: Text(
                      'Video configurado. Se mostrará en el detalle del evento.',
                      style: TextStyle(
                        fontSize: 12,
                        color: EvioLightColors.success,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged(null);
                    },
                    child: Text(
                      'Quitar',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
