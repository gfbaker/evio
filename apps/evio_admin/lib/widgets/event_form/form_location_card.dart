import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../common/form_card.dart';
import '../common/date_picker_field.dart';
import '../common/time_picker_field.dart';

class FormLocationCard extends ConsumerWidget {
  final DateTime startDate;
  final TimeOfDay startTime;
  final String venueName;
  final String city;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final VoidCallback onSelectLocation;

  const FormLocationCard({
    required this.startDate,
    required this.startTime,
    required this.venueName,
    required this.city,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.onSelectLocation,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormCard(
      title: 'Fecha y Ubicación',
      icon: Icons.calendar_today_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DatePickerField(
                  label: 'Fecha del Evento *',
                  value: startDate,
                  onChanged: onDateChanged,
                ),
              ),
              SizedBox(width: EvioSpacing.md),
              Expanded(
                child: TimePickerField(
                  label: 'Hora de Inicio *',
                  value: startTime,
                  onChanged: onTimeChanged,
                ),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.lg),
          Row(
            children: [
              // Venue / Club
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Venue / Club *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: EvioLightColors.foreground,
                      ),
                    ),
                    SizedBox(height: EvioSpacing.xs),
                    InkWell(
                      onTap: onSelectLocation,
                      child: Container(
                        height: 48,
                        padding: EdgeInsets.symmetric(horizontal: EvioSpacing.sm),
                        decoration: BoxDecoration(
                          color: EvioLightColors.inputBackground,
                          borderRadius: BorderRadius.circular(EvioRadius.input),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          venueName.isEmpty ? 'Ej: Warehouse 23' : venueName,
                          style: TextStyle(
                            color: venueName.isEmpty
                                ? EvioLightColors.mutedForeground
                                : EvioLightColors.foreground,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: EvioSpacing.md),
              // Ciudad, País
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ciudad, País *',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: EvioLightColors.foreground,
                      ),
                    ),
                    SizedBox(height: EvioSpacing.xs),
                    InkWell(
                      onTap: onSelectLocation,
                      child: Container(
                        height: 48,
                        padding: EdgeInsets.symmetric(horizontal: EvioSpacing.sm),
                        decoration: BoxDecoration(
                          color: EvioLightColors.inputBackground,
                          borderRadius: BorderRadius.circular(EvioRadius.input),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          city.isEmpty ? 'Ej: Barcelona, España' : city,
                          style: TextStyle(
                            color: city.isEmpty
                                ? EvioLightColors.mutedForeground
                                : EvioLightColors.foreground,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
