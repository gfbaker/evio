import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:evio_core/evio_core.dart';

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const DatePickerField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: EvioLightColors.foreground,
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime.now(),
              lastDate: DateTime(2030),
            );
            if (picked != null) onChanged(picked);
          },
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: EvioSpacing.sm),
            decoration: BoxDecoration(
              color: EvioLightColors.inputBackground,
              borderRadius: BorderRadius.circular(EvioRadius.input),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: EvioSpacing.iconS,
                  color: EvioLightColors.mutedForeground,
                ),
                SizedBox(width: EvioSpacing.xs),
                Text(
                  DateFormat('dd/MM/yyyy').format(value),
                  style: TextStyle(
                    fontSize: 14,
                    color: EvioLightColors.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
