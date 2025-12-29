import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class LabelInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final int? maxLines;
  final TextInputType? keyboardType;

  const LabelInput({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
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
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: EvioLightColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(EvioRadius.input),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: EvioSpacing.sm,
              vertical: EvioSpacing.sm,
            ),
          ),
        ),
      ],
    );
  }
}
