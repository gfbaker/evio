import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../common/form_card.dart';
import '../common/label_input.dart';
import '../common/custom_dropdown.dart';

class FormDetailsCard extends ConsumerWidget {
  final TextEditingController titleCtrl;
  final TextEditingController mainArtistCtrl;
  final TextEditingController genreCtrl;
  final TextEditingController organizerCtrl;
  final TextEditingController descriptionCtrl;
  final EventStatus status;
  final ValueChanged<EventStatus> onStatusChanged;

  const FormDetailsCard({
    required this.titleCtrl,
    required this.mainArtistCtrl,
    required this.genreCtrl,
    required this.organizerCtrl,
    required this.descriptionCtrl,
    required this.status,
    required this.onStatusChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormCard(
      title: 'Detalles del Evento',
      icon: Icons.music_note_outlined,
      child: Column(
        children: [
          LabelInput(
            label: 'Nombre del Evento *',
            controller: titleCtrl,
            hint: 'Ej: Neon Nights',
          ),
          SizedBox(height: EvioSpacing.lg),
          LabelInput(
            label: 'Artista Principal *',
            controller: mainArtistCtrl,
            hint: 'Ej: Nina Kraviz',
          ),
          SizedBox(height: EvioSpacing.lg),
          Row(
            children: [
              Expanded(
                child: LabelInput(
                  label: 'Género Musical *',
                  controller: genreCtrl,
                  hint: 'Ej: Techno',
                ),
              ),
              SizedBox(width: EvioSpacing.md),
              Expanded(
                child: CustomDropdown(
                  label: 'Estado del Evento',
                  value: status.displayName,
                  items: EventStatus.values.map((s) => s.displayName).toList(),
                  onChanged: (value) {
                    final newStatus = EventStatus.values.firstWhere(
                      (s) => s.displayName == value,
                    );
                    onStatusChanged(newStatus);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.lg),
          LabelInput(
            label: 'Organizador *',
            controller: organizerCtrl,
            hint: 'Ej: Pulse Events',
          ),
          SizedBox(height: EvioSpacing.lg),
          LabelInput(
            label: 'Descripción del evento',
            controller: descriptionCtrl,
            maxLines: 4,
            hint:
                'Describe tu evento... Ej: Una noche épica de techno con los mejores DJs de la escena underground.',
          ),
        ],
      ),
    );
  }
}
