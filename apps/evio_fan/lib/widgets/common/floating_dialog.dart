import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

/// Widget para mostrar mensajes flotantes tipo toast
class FloatingDialog {
  /// Muestra un mensaje de éxito
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: EvioFanColors.success,
      iconColor: Colors.white,
      duration: duration,
    );
  }

  /// Muestra un mensaje de error
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.error,
      backgroundColor: EvioFanColors.error,
      iconColor: Colors.white,
      duration: duration,
    );
  }

  /// Muestra un mensaje de información
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.info,
      backgroundColor: EvioFanColors.primary,
      iconColor: EvioFanColors.primaryForeground,
      duration: duration,
    );
  }

  /// Muestra un mensaje de advertencia
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: Icons.warning,
      backgroundColor: EvioFanColors.warning,
      iconColor: Colors.white,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _FloatingDialogWidget(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove después del duration
    Future.delayed(duration + const Duration(milliseconds: 300), () {
      overlayEntry.remove();
    });
  }
}

class _FloatingDialogWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Duration duration;

  const _FloatingDialogWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.duration,
  });

  @override
  State<_FloatingDialogWidget> createState() => _FloatingDialogWidgetState();
}

class _FloatingDialogWidgetState extends State<_FloatingDialogWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    // Trigger exit animation before removal
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + EvioSpacing.md,
      left: EvioSpacing.md,
      right: EvioSpacing.md,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(EvioSpacing.md),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(EvioRadius.card),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: widget.iconColor,
                    size: 24,
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: EvioTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
