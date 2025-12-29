import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:evio_core/evio_core.dart';

/// Shimmer para mostrar mientras cargan los tickets
class TicketsListShimmer extends StatelessWidget {
  const TicketsListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(EvioSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Shimmer.fromColors(
            baseColor: EvioFanColors.card,
            highlightColor: EvioFanColors.border,
            child: Container(
              width: 150,
              height: 32,
              decoration: BoxDecoration(
                color: EvioFanColors.card,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          SizedBox(height: EvioSpacing.xl),
          
          // Section label
          Shimmer.fromColors(
            baseColor: EvioFanColors.card,
            highlightColor: EvioFanColors.border,
            child: Container(
              width: 120,
              height: 12,
              decoration: BoxDecoration(
                color: EvioFanColors.card,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          
          SizedBox(height: EvioSpacing.sm),
          
          // 3 Ticket Cards
          ...List.generate(3, (i) => Padding(
            padding: EdgeInsets.only(bottom: EvioSpacing.md),
            child: Shimmer.fromColors(
              baseColor: EvioFanColors.card,
              highlightColor: EvioFanColors.border,
              child: Container(
                padding: EdgeInsets.all(EvioSpacing.md),
                decoration: BoxDecoration(
                  color: EvioFanColors.surface,
                  borderRadius: BorderRadius.circular(EvioRadius.card),
                  border: Border.all(color: EvioFanColors.border),
                ),
                child: Row(
                  children: [
                    // Image placeholder
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: EvioFanColors.muted,
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                    ),
                    
                    SizedBox(width: EvioSpacing.md),
                    
                    // Info placeholders
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                            width: 120,
                            height: 12,
                            decoration: BoxDecoration(
                              color: EvioFanColors.border.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: EvioFanColors.border.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(width: EvioSpacing.md),
                    
                    // Icon placeholder
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: EvioFanColors.border,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
