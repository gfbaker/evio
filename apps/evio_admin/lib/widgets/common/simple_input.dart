import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class SimpleInput extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final bool isWhite;

  const SimpleInput({
    required this.hint,
    this.controller,
    this.isWhite = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : EvioLightColors.inputBackground,
        borderRadius: BorderRadius.circular(EvioRadius.input),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
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
      ),
    );
  }
}
