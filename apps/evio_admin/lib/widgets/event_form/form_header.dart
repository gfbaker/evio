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

  String _getStatusLabel(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return 'Borrador';
      case EventStatus.upcoming:
        return 'Publicado';
      case EventStatus.cancelled:
        return 'Cancelado';
    }
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.draft:
        return Colors.orange.shade600;
      case EventStatus.upcoming:
        return Colors.green.shade600;
      case EventStatus.cancelled:
        return Colors.red.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: EvioSpacing.xl,
        vertical: EvioSpacing.md,
      ),
      decoration: BoxDecoration(
        color: EvioLightColors.background,
        border: Border(bottom: BorderSide(color: EvioLightColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(EvioSpacing.xs),
            decoration: BoxDecoration(
              color: EvioLightColors.surface,
              borderRadius: BorderRadius.circular(EvioRadius.button),
              border: Border.all(color: EvioLightColors.border),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: EvioSpacing.iconM,
              color: EvioLightColors.primary,
            ),
          ),
          SizedBox(width: EvioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isEdit ? 'Editar Evento' : 'Crear Nuevo Evento',
                      style: EvioTypography.h2,
                    ),
                    SizedBox(width: EvioSpacing.sm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: EvioSpacing.xs,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withValues(alpha: 0.1),
                        border: Border.all(
                          color: _getStatusColor(status),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusLabel(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Configura todos los detalles de tu próximo evento',
                  style: TextStyle(
                    color: EvioLightColors.mutedForeground,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: BorderSide(color: EvioLightColors.border),
              foregroundColor: EvioLightColors.foreground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
            ),
            child: Text('Cancelar'),
          ),
          
          SizedBox(width: EvioSpacing.sm),
          FilledButton.icon(
            onPressed: isLoading ? null : onSave,
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.save, size: 18),
            label: Text('Guardar Evento'),
            style: FilledButton.styleFrom(
              backgroundColor: EvioLightColors.primary,
              foregroundColor: EvioLightColors.primaryForeground,
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
