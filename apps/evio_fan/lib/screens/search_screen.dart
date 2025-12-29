import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvioFanColors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            'Search Screen',
            style: EvioTypography.h1.copyWith(color: EvioFanColors.foreground),
          ),
        ),
      ),
    );
  }
}
