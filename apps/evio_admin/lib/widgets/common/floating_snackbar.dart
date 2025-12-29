import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

enum SnackBarType { success, error, info, warning }

class FloatingSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    bool showCloseButton = true,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _FloatingSnackBarWidget(
        message: message,
        type: type,
        duration: duration,
        showCloseButton: showCloseButton,
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-remove después del duration
    Future.delayed(duration + const Duration(milliseconds: 300), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // ✅ Para errores de validación con lista
  static void showValidationErrors(
    BuildContext context, {
    required String title,
    required List<String> fields,
    Duration duration = const Duration(seconds: 5),
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _FloatingValidationErrorWidget(
        title: title,
        fields: fields,
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration + const Duration(milliseconds: 300), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _FloatingSnackBarWidget extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final Duration duration;
  final bool showCloseButton;

  const _FloatingSnackBarWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.showCloseButton,
  });

  @override
  State<_FloatingSnackBarWidget> createState() =>
      _FloatingSnackBarWidgetState();
}

class _FloatingSnackBarWidgetState extends State<_FloatingSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.duration, () {
      if (!_isDisposed && mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDisposed || !mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        if (context.mounted) {
          final overlay = Overlay.of(context);
          overlay.setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = _getConfig(widget.type);

    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: EdgeInsets.all(EvioSpacing.md),
                decoration: BoxDecoration(
                  // ✅ Fondo del color del tipo
                  color: config['bgColor'],
                  borderRadius: BorderRadius.circular(EvioRadius.card),
                  boxShadow: [
                    BoxShadow(
                      color: (config['bgColor'] as Color).withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icono con opacidad
                    Container(
                      padding: EdgeInsets.all(EvioSpacing.xs),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                      child: Icon(
                        config['icon'],
                        size: EvioSpacing.iconM,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: EvioSpacing.sm),

                    // Mensaje en blanco
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Botón close
                    if (widget.showCloseButton) ...[
                      SizedBox(width: EvioSpacing.sm),
                      InkWell(
                        onTap: _dismiss,
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                        child: Padding(
                          padding: EdgeInsets.all(EvioSpacing.xs),
                          child: Icon(
                            Icons.close,
                            size: EvioSpacing.iconS,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return {
          'bgColor': const Color(0xFF10B981), // green-500
          'icon': Icons.check_circle,
        };
      case SnackBarType.error:
        return {'bgColor': EvioLightColors.destructive, 'icon': Icons.error};
      case SnackBarType.warning:
        return {
          'bgColor': const Color(0xFFF59E0B), // amber-500
          'icon': Icons.warning,
        };
      case SnackBarType.info:
      default:
        return {'bgColor': EvioLightColors.primary, 'icon': Icons.info};
    }
  }
}

// -----------------------------------------------------------------------------
// WIDGET ESPECIAL PARA ERRORES DE VALIDACIÓN
// -----------------------------------------------------------------------------

class _FloatingValidationErrorWidget extends StatefulWidget {
  final String title;
  final List<String> fields;
  final Duration duration;

  const _FloatingValidationErrorWidget({
    required this.title,
    required this.fields,
    required this.duration,
  });

  @override
  State<_FloatingValidationErrorWidget> createState() =>
      _FloatingValidationErrorWidgetState();
}

class _FloatingValidationErrorWidgetState
    extends State<_FloatingValidationErrorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (!_isDisposed && mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_isDisposed || !mounted) return;
    _controller.reverse().then((_) {
      if (mounted && context.mounted) {
        final overlay = Overlay.of(context);
        overlay.setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: EdgeInsets.all(EvioSpacing.md),
                decoration: BoxDecoration(
                  // ✅ Todo del mismo color (rojo destructive)
                  color: EvioLightColors.destructive,
                  borderRadius: BorderRadius.circular(EvioRadius.card),
                  boxShadow: [
                    BoxShadow(
                      color: EvioLightColors.destructive.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(EvioSpacing.xs),
                          decoration: BoxDecoration(
                            // ✅ Ícono con opacidad
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              EvioRadius.button,
                            ),
                          ),
                          child: Icon(
                            Icons.error,
                            size: EvioSpacing.iconM,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: EvioSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _dismiss,
                          borderRadius: BorderRadius.circular(
                            EvioRadius.button,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(EvioSpacing.xs),
                            child: Icon(
                              Icons.close,
                              size: EvioSpacing.iconS,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: EvioSpacing.sm),

                    // Lista de campos
                    Container(
                      padding: EdgeInsets.all(EvioSpacing.sm),
                      decoration: BoxDecoration(
                        // ✅ Container con opacidad
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: widget.fields
                            .map(
                              (field) => Padding(
                                padding: EdgeInsets.only(
                                  bottom: widget.fields.last == field
                                      ? 0
                                      : EvioSpacing.xs,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: EvioSpacing.xs),
                                    Expanded(
                                      child: Text(
                                        field,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
