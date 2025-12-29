import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  const TimePickerField({
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
            final picked = await showTimePicker(
              context: context,
              initialTime: value,
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
                  Icons.access_time,
                  size: EvioSpacing.iconS,
                  color: EvioLightColors.mutedForeground,
                ),
                SizedBox(width: EvioSpacing.xs),
                Text(
                  value.format(context),
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
