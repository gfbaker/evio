import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class FormHeader extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool isLoading;
  final EventStatus status;

  const FormHeader({
    required this.isEdit,
    required this.onCancel,
    required this.onSave,
    required this.isLoading,
    required this.status,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EvioSpacing.xl,
        vertical: EvioSpacing.md,
      ),
      color: EvioLightColors.surface,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Editar Evento' : 'Crear Nuevo Evento',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
                SizedBox(height: EvioSpacing.xxs),
                Text(
                  isEdit 
                      ? 'Modificá los datos de tu evento'
                      : 'Completá los datos para crear un nuevo evento',
                  style: TextStyle(
                    fontSize: 14,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          
          // Botón Cancelar
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: Icon(Icons.arrow_back, size: 18),
            label: Text('Cancelar'),
            style: OutlinedButton.styleFrom(
              backgroundColor: EvioLightColors.card,
              side: BorderSide(color: EvioLightColors.border),
              foregroundColor: EvioLightColors.textPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: EvioSpacing.lg,
                vertical: EvioSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
            ),
          ),
          
          SizedBox(width: EvioSpacing.sm),
          
          // Botón Crear/Guardar Evento (amarillo)
          FilledButton.icon(
            onPressed: isLoading ? null : onSave,
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EvioLightColors.accentForeground,
                    ),
                  )
                : Icon(Icons.save_outlined, size: 18),
            label: Text(isEdit ? 'Guardar Evento' : 'Crear Evento'),
            style: FilledButton.styleFrom(
              backgroundColor: EvioLightColors.accent,
              foregroundColor: EvioLightColors.accentForeground,
              padding: EdgeInsets.symmetric(
                horizontal: EvioSpacing.lg,
                vertical: EvioSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
