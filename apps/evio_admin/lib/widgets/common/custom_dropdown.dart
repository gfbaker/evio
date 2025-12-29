import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const CustomDropdown({
    required this.label,
    required this.value,
    required this.items,
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
        Container(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: EvioSpacing.sm),
          decoration: BoxDecoration(
            color: EvioLightColors.inputBackground,
            borderRadius: BorderRadius.circular(EvioRadius.input),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: EvioSpacing.iconM,
                color: EvioLightColors.mutedForeground,
              ),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
