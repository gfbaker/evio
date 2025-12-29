import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

import 'ticket_card.dart';

class TicketsSection extends StatelessWidget {
  final AsyncValue<List<TicketType>> ticketsAsync;
  final String? selectedTierId;
  final Map<String, int> quantities;
  final Function(String?) onTierSelected;
  final Function(String, int) onQuantityChanged;

  const TicketsSection({
    super.key,
    required this.ticketsAsync,
    required this.selectedTierId,
    required this.quantities,
    required this.onTierSelected,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ticketsAsync.when(
      data: (tickets) => _buildTicketsContent(tickets),
      loading: () => _buildLoading(),
      error: (e, st) => _buildError(),
    );
  }

  Widget _buildTicketsContent(List<TicketType> tickets) {
    if (tickets.isEmpty) {
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

    // ✅ Separar por estado: activas disponibles, inactivas (próximamente), agotadas
    final activeAvailable = tickets
        .where((t) => t.isActive && !t.isSoldOut)
        .toList();
    final inactive = tickets
        .where((t) => !t.isActive && !t.isSoldOut)
        .toList();
    final soldOut = tickets
        .where((t) => t.isSoldOut)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.confirmation_number_rounded,
              color: EvioFanColors.primary,
              size: 22,
            ),
            SizedBox(width: EvioSpacing.sm),
            Text(
              'Entradas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: EvioFanColors.foreground,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(width: EvioSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: EvioSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: EvioFanColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${activeAvailable.length} disponible${activeAvailable.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EvioFanColors.primary,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: EvioSpacing.lg),

        // ✅ Tandas Activas Disponibles
        ...activeAvailable.map(
          (ticket) => Padding(
            padding: EdgeInsets.only(bottom: EvioSpacing.md),
            child: TicketCard(
              ticket: ticket,
              isActive: true,
              isSelected: selectedTierId == ticket.id,
              quantity: quantities[ticket.id] ?? 1,
              onTap: () => onTierSelected(
                selectedTierId == ticket.id ? null : ticket.id,
              ),
              onQuantityChanged: (qty) => onQuantityChanged(ticket.id, qty),
            ),
          ),
        ),

        // ✅ Tandas Inactivas (Próximamente)
        if (inactive.isNotEmpty) ...[
          SizedBox(height: EvioSpacing.xl),
          
          // Divisor visual
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: EvioFanColors.border,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
                child: Text(
                  'PRÓXIMAMENTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: EvioFanColors.mutedForeground.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: EvioFanColors.border,
                ),
              ),
            ],
          ),
          
          SizedBox(height: EvioSpacing.lg),
          ...inactive.map(
            (ticket) => Padding(
              padding: EdgeInsets.only(bottom: EvioSpacing.md),
              child: TicketCard(
                ticket: ticket,
                isActive: false,
                isSelected: false,
                quantity: 1,
                onTap: () {},
                onQuantityChanged: (_) {},
              ),
            ),
          ),
        ],

        // ✅ Tandas Agotadas
        if (soldOut.isNotEmpty) ...[
          SizedBox(height: EvioSpacing.xl),
          
          // Divisor visual
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: EvioFanColors.border,
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.md),
                child: Text(
                  'AGOTADAS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: EvioFanColors.mutedForeground.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: EvioFanColors.border,
                ),
              ),
            ],
          ),
          
          SizedBox(height: EvioSpacing.lg),
          ...soldOut.map(
            (ticket) => Padding(
              padding: EdgeInsets.only(bottom: EvioSpacing.md),
              child: TicketCard(
                ticket: ticket,
                isActive: false,
                isSelected: false,
                quantity: 1,
                onTap: () {},
                onQuantityChanged: (_) {},
              ),
            ),
          ),
        ],
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
