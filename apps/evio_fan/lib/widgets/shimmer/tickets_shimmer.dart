import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:evio_core/evio_core.dart';

/// Shimmer para mostrar mientras cargan los tickets
/// Se usa en EventContentSection cuando ticketsAsync está en loading
class TicketsShimmer extends StatelessWidget {
  const TicketsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Shimmer.fromColors(
          baseColor: EvioFanColors.card,
          highlightColor: EvioFanColors.border,
          child: Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: EvioFanColors.card,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        
        SizedBox(height: EvioSpacing.lg),
        
        // 3 Ticket Cards (shimmer)
        ...List.generate(3, (i) => Padding(
          padding: EdgeInsets.only(bottom: EvioSpacing.md),
          child: Shimmer.fromColors(
            baseColor: EvioFanColors.card,
            highlightColor: EvioFanColors.border,
            child: Container(
              height: 80,
              padding: EdgeInsets.all(EvioSpacing.md),
              decoration: BoxDecoration(
                color: EvioFanColors.card,
                borderRadius: BorderRadius.circular(EvioRadius.card),
                border: Border.all(color: EvioFanColors.border),
              ),
              child: Row(
                children: [
                  // Left: Name placeholder
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: EvioFanColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          width: 100,
                          height: 12,
                          decoration: BoxDecoration(
                            color: EvioFanColors.border.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(width: EvioSpacing.md),
                  
                  // Right: Price + Button placeholder
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 16,
                        decoration: BoxDecoration(
                          color: EvioFanColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      SizedBox(width: EvioSpacing.sm),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: EvioFanColors.border,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }
}
