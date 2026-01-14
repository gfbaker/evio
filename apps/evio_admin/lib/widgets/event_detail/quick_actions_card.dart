import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import 'detail_card.dart';

/// Card de acciones rápidas: generar ticket, marcar sold out, invitaciones.
class QuickActionsCard extends StatelessWidget {
  final Event event;
  final VoidCallback onGenerateTicket;
  final VoidCallback onMarkSoldOut;
  final VoidCallback onSendInvitations;

  const QuickActionsCard({
    required this.event,
    required this.onGenerateTicket,
    required this.onMarkSoldOut,
    required this.onSendInvitations,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DetailCard(
      title: 'Acciones Rápidas',
      icon: Icons.bolt,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 600;
          
          if (isDesktop) {
            return Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Generar Ticket',
                    subtitle: 'Crear entrada manual',
                    onTap: onGenerateTicket,
                  ),
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Marcar Sold Out',
                    subtitle: 'Finalizar ventas',
                    onTap: onMarkSoldOut,
                  ),
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.send_outlined,
                    label: 'Invitaciones',
                    subtitle: 'Tickets gratuitos',
                    onTap: onSendInvitations,
                  ),
                ),
              ],
            );
          }
          
          return Column(
            children: [
              _ActionButton(
                icon: Icons.confirmation_number_outlined,
                label: 'Generar Ticket Manual',
                subtitle: 'Crear entrada directa',
                onTap: onGenerateTicket,
              ),
              SizedBox(height: EvioSpacing.md),
              _ActionButton(
                icon: Icons.check_circle_outline,
                label: 'Marcar Sold Out',
                subtitle: 'Finalizar ventas',
                onTap: onMarkSoldOut,
              ),
              SizedBox(height: EvioSpacing.md),
              _ActionButton(
                icon: Icons.send_outlined,
                label: 'Enviar Invitaciones',
                subtitle: 'Tickets gratuitos',
                onTap: onSendInvitations,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        backgroundColor: EvioLightColors.surface,
        side: BorderSide(color: EvioLightColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EvioRadius.button),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: EvioLightColors.accent),
          SizedBox(height: EvioSpacing.sm),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: EvioLightColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: EvioLightColors.mutedForeground,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
