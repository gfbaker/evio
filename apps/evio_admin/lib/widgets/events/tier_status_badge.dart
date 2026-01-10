import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

enum TierStatusType {
  upcoming, // Próximamente
  active, // Activo
  ending, // Por finalizar
  soldOut, // Agotado
  inactive, // Inactivo
}

class TierStatusInfo {
  final TierStatusType type;
  final String label;
  final Color badgeColor;
  final Color borderColor;
  final Color bgColor;
  final Color progressColor;
  final Color priceColor;
  final IconData icon;

  TierStatusInfo({
    required this.type,
    required this.label,
    required this.badgeColor,
    required this.borderColor,
    required this.bgColor,
    required this.progressColor,
    required this.priceColor,
    required this.icon,
  });

  static TierStatusInfo fromTier(TicketTier tier, {TicketTier? previousTier}) {
    final now = DateTime.now();
    final isSoldOut = tier.soldCount >= tier.quantity;
    final isInactive = !tier.isActive;
    final isUpcoming =
        tier.saleStartsAt != null && tier.saleStartsAt!.isAfter(now);
    final isEnding =
        tier.saleEndsAt != null &&
        tier.saleEndsAt!.isAfter(now) &&
        tier.saleEndsAt!.difference(now).inHours < 48;
    
    // Verificar si está en espera (esperando que el tier anterior se agote/desactive)
    final isWaiting = previousTier != null && 
        tier.isActive && 
        !isSoldOut && 
        !isUpcoming &&
        previousTier.isActive && 
        !previousTier.isSoldOut;

    // Prioridad: Agotado > Inactivo > En espera > Próximamente > Por finalizar > Activo
    if (isSoldOut) {
      return TierStatusInfo(
        type: TierStatusType.soldOut,
        label: 'Agotado',
        badgeColor: EvioLightColors.destructive,
        borderColor: EvioLightColors.destructive.withValues(alpha: 0.3),
        bgColor: EvioLightColors.destructive.withValues(alpha: 0.05),
        progressColor: EvioLightColors.destructive,
        priceColor: EvioLightColors.destructive,
        icon: Icons.block,
      );
    }

    if (isInactive) {
      return TierStatusInfo(
        type: TierStatusType.inactive,
        label: 'Pausado',
        badgeColor: const Color(0xFF64748B), // slate-500 (azul grisáceo)
        borderColor: const Color(0xFF64748B).withValues(alpha: 0.3),
        bgColor: const Color(0xFF64748B).withValues(alpha: 0.08),
        progressColor: const Color(0xFF64748B),
        priceColor: const Color(0xFF64748B),
        icon: Icons.pause_circle_outline,
      );
    }

    if (isWaiting) {
      return TierStatusInfo(
        type: TierStatusType.upcoming,
        label: 'En espera',
        badgeColor: const Color(0xFFF59E0B), // amber-500
        borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.05),
        progressColor: const Color(0xFFF59E0B),
        priceColor: EvioLightColors.mutedForeground,
        icon: Icons.hourglass_empty,
      );
    }

    if (isUpcoming) {
      final hoursUntilStart = tier.saleStartsAt!.difference(now).inHours;
      String label = 'Próximamente';
      if (hoursUntilStart < 24) {
        label = 'Inicia en ${hoursUntilStart}h';
      } else if (hoursUntilStart < 48) {
        label = 'Inicia mañana';
      }

      return TierStatusInfo(
        type: TierStatusType.upcoming,
        label: label,
        badgeColor: EvioLightColors.info,
        borderColor: EvioLightColors.info.withValues(alpha: 0.3),
        bgColor: EvioLightColors.info.withValues(alpha: 0.05),
        progressColor: EvioLightColors.info,
        priceColor: EvioLightColors.info,
        icon: Icons.schedule,
      );
    }

    if (isEnding) {
      final hoursUntilEnd = tier.saleEndsAt!.difference(now).inHours;
      String label = 'Por finalizar';
      if (hoursUntilEnd < 24) {
        label = 'Finaliza en ${hoursUntilEnd}h';
      } else if (hoursUntilEnd < 48) {
        label = 'Finaliza pronto';
      }

      return TierStatusInfo(
        type: TierStatusType.ending,
        label: label,
        badgeColor: EvioLightColors.warning,
        borderColor: EvioLightColors.warning.withValues(alpha: 0.3),
        bgColor: EvioLightColors.warning.withValues(alpha: 0.05),
        progressColor: EvioLightColors.warning,
        priceColor: EvioLightColors.warning,
        icon: Icons.access_time,
      );
    }

    // Default: Activo
    return TierStatusInfo(
      type: TierStatusType.active,
      label: 'Activo',
      badgeColor: EvioLightColors.success,
      borderColor: EvioLightColors.success.withValues(alpha: 0.3),
      bgColor: EvioLightColors.success.withValues(alpha: 0.05),
      progressColor: EvioLightColors.success,
      priceColor: EvioLightColors.primary,
      icon: Icons.check_circle_outline,
    );
  }
}

class TierStatusBadge extends StatelessWidget {
  final TierStatusInfo status;

  const TierStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: status.badgeColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 10, color: EvioLightColors.primaryForeground),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: EvioLightColors.primaryForeground,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
