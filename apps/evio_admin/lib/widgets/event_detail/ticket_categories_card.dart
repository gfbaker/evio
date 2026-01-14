import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'detail_card.dart';
import '../events/tier_status_badge.dart';

/// Card de categorías de tickets con sus tiers.
class TicketCategoriesCard extends StatelessWidget {
  final Event event;
  final List<TicketCategory> categories;
  final VoidCallback onManage;

  const TicketCategoriesCard({
    required this.event,
    required this.categories,
    required this.onManage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Categorías de Tickets',
      icon: Icons.confirmation_number,
      headerAction: FilledButton.icon(
        onPressed: onManage,
        icon: Icon(Icons.edit, size: 16),
        label: Text('Gestionar'),
        style: FilledButton.styleFrom(
          backgroundColor: EvioLightColors.accent,
          foregroundColor: EvioLightColors.accentForeground,
          padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EvioRadius.button),
          ),
          minimumSize: Size(0, 36),
        ),
      ),
      child: categories.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(EvioSpacing.lg),
                child: Text(
                  'No hay categorías configuradas.',
                  style: TextStyle(color: EvioLightColors.mutedForeground),
                ),
              ),
            )
          : Column(
              children: categories
                  .map((category) => _CategoryItem(category: category))
                  .toList(),
            ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final TicketCategory category;

  const _CategoryItem({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.md),
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.surface,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de categoría
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
              ),
              if (category.maxPerPurchase != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: EvioLightColors.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Máx ${category.maxPerPurchase}',
                    style: TextStyle(
                      color: EvioLightColors.accentForeground,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          if (category.description != null) ...[
            SizedBox(height: EvioSpacing.xs),
            Text(
              category.description!,
              style: TextStyle(
                fontSize: 13,
                color: EvioLightColors.mutedForeground,
              ),
            ),
          ],
          
          // Tiers
          if (category.tiers.isNotEmpty) ...[
            SizedBox(height: EvioSpacing.sm),
            ...category.tiers.asMap().entries.map((entry) {
              final index = entry.key;
              final tier = entry.value;
              final previousTier = index > 0 ? category.tiers[index - 1] : null;
              return _TierItem(tier: tier, previousTier: previousTier);
            }),
          ],
        ],
      ),
    );
  }
}

class _TierItem extends StatelessWidget {
  final TicketTier tier;
  final TicketTier? previousTier;

  const _TierItem({required this.tier, this.previousTier});

  @override
  Widget build(BuildContext context) {
    final percent = tier.quantity > 0 ? tier.soldCount / tier.quantity : 0.0;
    final status = TierStatusInfo.fromTier(tier, previousTier: previousTier);

    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.xs),
      padding: EdgeInsets.all(EvioSpacing.sm),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(EvioRadius.button),
        border: Border.all(color: status.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          tier.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: EvioLightColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: EvioSpacing.xs),
                        TierStatusBadge(status: status),
                      ],
                    ),
                    if (tier.description != null)
                      Text(
                        tier.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: EvioLightColors.mutedForeground,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: EvioSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${tier.price}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: status.priceColor,
                    ),
                  ),
                  Text(
                    '${tier.soldCount}/${tier.quantity}',
                    style: TextStyle(
                      fontSize: 12,
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.xs),
          
          // Barra de progreso pequeña
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: EvioLightColors.muted,
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percent.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: status.progressColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
