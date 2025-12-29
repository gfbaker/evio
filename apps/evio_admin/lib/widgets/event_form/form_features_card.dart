import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../common/form_card.dart';

class FormFeaturesCard extends ConsumerWidget {
  final List<String> selectedFeatures;
  final Function(String feature) onToggle;

  const FormFeaturesCard({
    required this.selectedFeatures,
    required this.onToggle,
    super.key,
  });

  static const List<String> _availableFeatures = [
    'Indoor',
    'Outdoor',
    'VIP Area',
    'Bar',
    'Cloakroom',
    'Food Trucks',
    'Beach Access',
    'Pool',
    'Terrace',
    'Premium Sound System',
    'LED Screens',
    'Smoke Machines',
    'VIP Tables',
    'Merch Store',
    'Food Court',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FormCard(
      title: 'Características del Venue',
      icon: Icons.auto_awesome_outlined,
      child: Wrap(
        spacing: EvioSpacing.xs,
        runSpacing: EvioSpacing.xs,
        children: _availableFeatures.map((feature) {
          final isSelected = selectedFeatures.contains(feature);
          return InkWell(
            onTap: () => onToggle(feature),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: EvioSpacing.sm,
                vertical: EvioSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected ? EvioLightColors.primary : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? EvioLightColors.primary
                      : EvioLightColors.border,
                ),
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
              child: Text(
                feature,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : EvioLightColors.foreground,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
