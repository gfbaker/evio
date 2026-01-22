import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

import 'tier_card.dart';

class CategoryTicketsSection extends StatelessWidget {
  final AsyncValue<List<TicketCategory>> categoriesAsync;
  final Map<String, int> quantities; // tierId -> quantity
  final Function(String tierId, int quantity) onQuantityChanged;

  const CategoryTicketsSection({
    super.key,
    required this.categoriesAsync,
    required this.quantities,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return categoriesAsync.when(
      data: (categories) => _buildContent(categories),
      loading: () => _buildLoading(),
      error: (e, st) => _buildError(),
    );
  }

  Widget _buildContent(List<TicketCategory> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'No hay entradas disponibles',
            style: TextStyle(color: EvioFanColors.mutedForeground),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Título afuera (igual que "Productora") con ícono
        Row(
          children: [
            Icon(
              Icons.confirmation_number_rounded,
              color: EvioFanColors.primary,
              size: 24,
            ),
            SizedBox(width: EvioSpacing.sm),
            Text(
              'Entradas',
              style: TextStyle(
                color: EvioFanColors.foreground,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.md),
        
        // ✅ Container igual al de productora
        Container(
          padding: EdgeInsets.all(EvioSpacing.md),
          decoration: BoxDecoration(
            color: EvioFanColors.card,
            borderRadius: BorderRadius.circular(EvioRadius.card),
            border: Border.all(color: EvioFanColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categorías
              ...categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Separador entre categorías (excepto la primera)
                    if (index > 0) ...[
                      SizedBox(height: EvioSpacing.lg),
                      Container(
                        height: 1,
                        color: EvioFanColors.border.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: EvioSpacing.lg),
                    ],

                    // Nombre de categoría
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: EvioFanColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: EvioSpacing.sm),
                        Text(
                          category.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: EvioFanColors.foreground,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (category.maxPerPurchase != null) ...[
                          SizedBox(width: EvioSpacing.sm),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: EvioSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: EvioFanColors.muted,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: EvioFanColors.border),
                            ),
                            child: Text(
                              'Máx. ${category.maxPerPurchase} por persona',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: EvioFanColors.mutedForeground,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    if (category.description != null && category.description!.isNotEmpty) ...[
                      SizedBox(height: EvioSpacing.xs),
                      Text(
                        category.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: EvioFanColors.mutedForeground,
                          height: 1.4,
                        ),
                      ),
                    ],

                    SizedBox(height: EvioSpacing.md),

                    // Tiers
                    ...category.tiers.asMap().entries.map((tierEntry) {
                      final tierIndex = tierEntry.key;
                      final tier = tierEntry.value;
                      final isSelected = quantities.containsKey(tier.id);
                      final quantity = quantities[tier.id] ?? 0;
                      final isLastTier = tierIndex == category.tiers.length - 1;

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: isLastTier ? 0 : EvioSpacing.md,
                        ),
                        child: TierCard(
                          tier: tier,
                          categoryName: category.name,
                          categoryMaxPerPurchase: category.maxPerPurchase,
                          isSelected: isSelected,
                          quantity: quantity,
                          onQuantityChanged: (qty) => onQuantityChanged(tier.id, qty),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'Error cargando entradas',
          style: TextStyle(color: EvioFanColors.mutedForeground),
        ),
      ),
    );
  }
}
