import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:evio_core/evio_core.dart';
import 'package:intl/intl.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../../providers/ticket_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  final int initialIndex;

  const TicketDetailScreen({
    super.key,
    required this.eventId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isDisposed = false;
  late PageController _pageController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  int _currentIndex = 0;

  bool _brightnessRestored = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _increaseBrightness();
  }

  Future<void> _increaseBrightness() async {
    if (_isDisposed) return;
    try {
      // ✅ Solo aumentar brillo al 100%, NO guardamos valor original
      await ScreenBrightness().setScreenBrightness(1.0);
    } catch (e) {
      debugPrint('⚠️ Error aumentando brillo: $e');
      // Silently fail if brightness control is not available
    }
  }

  Future<void> _restoreBrightness() async {
    if (_brightnessRestored) return;

    try {
      // ✅ CRÃTICO: Restaurar usando resetScreenBrightness() que vuelve al brillo del sistema
      // Esto permite que el usuario haya cambiado el brillo mientras navegaba
      await ScreenBrightness().resetScreenBrightness();
      _brightnessRestored = true;
    } catch (e) {
      debugPrint('⚠️ Error restaurando brillo: $e');
      // Silently fail if brightness control is not available
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _pageController.dispose();
    _animationController.dispose();
    _restoreBrightness();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTicketsAsync = ref.watch(myActiveTicketsProvider);

    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      body: allTicketsAsync.when(
        data: (allTickets) {
          final eventTickets = allTickets
              .where((t) => t.eventId == widget.eventId)
              .toList();

          if (eventTickets.isEmpty) {
            return Center(
              child: Text(
                'No se encontraron tickets para este evento',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemCount: eventTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketPage(context, eventTickets[index]);
                  },
                ),
                Positioned(
                  top: EvioSpacing.md + MediaQuery.of(context).padding.top,
                  left: EvioSpacing.md,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () async {
                        await _restoreBrightness();
                        if (mounted) context.pop();
                      },
                    ),
                  ),
                ),
                if (eventTickets.length > 1)
                  Positioned(
                    bottom: 40 + MediaQuery.of(context).padding.bottom,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF1a1a1a),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xFFD4AF37).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${_currentIndex + 1}/${eventTickets.length}',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
        error: (e, st) => Center(
          child: Text('Error: $e', style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildTicketPage(BuildContext context, Ticket ticket) {
    return Center(
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 80),
          child: _buildTicketCard(context, ticket),
        ),
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, Ticket ticket) {
    final dateFormat = DateFormat('E, dd MMM - HH:mm', 'es');

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0xFFD4AF37).withValues(alpha: 0.12),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // ✅ Forma del ticket con recortes
          Positioned.fill(
            child: CustomPaint(
              painter: TicketShapePainter(),
            ),
          ),
          
          // ✅ Contenido del ticket
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: Título + Info
                Column(
                  children: [
                    Text(
                      ticket.event?.title ?? 'Evento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      ticket.event?.startDatetime != null
                          ? dateFormat.format(ticket.event!.startDatetime)
                          : '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${ticket.event?.venueName ?? "Venue"} • ${ticket.event?.city ?? "Ciudad"}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    
                    // ✅ Categoría del ticket
                    if (ticket.categoryName != null) ...[
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFD4AF37).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0xFFD4AF37).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          ticket.categoryName!,
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                SizedBox(height: 24),
                
                // ✅ Línea punteada divisoria
                CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
                
                SizedBox(height: 24),
                
                // QR Code
                Container(
                  width: 240,
                  height: 240,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: ticket.qrData,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                  ),
                ),
                
                SizedBox(height: 24),
                
                // ✅ Línea punteada divisoria
                CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
                
                SizedBox(height: 24),
                
                // Footer: Ticket ID
                Text(
                  'Ticket ID: ${ticket.id.substring(0, 8).toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Painter de la forma del ticket (con recortes laterales)
class TicketShapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF1a1a1a)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Color(0xFFD4AF37).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final borderRadius = 20.0;
    final notchRadius = 12.0;
    
    // Posiciones de los recortes (divisiones)
    final divider1Y = size.height * 0.32; // Después del header
    final divider2Y = size.height * 0.75; // Después del QR

    // ✅ Top edge (con esquinas redondeadas)
    path.moveTo(borderRadius, 0);
    path.lineTo(size.width - borderRadius, 0);
    path.arcToPoint(
      Offset(size.width, borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // ✅ Right edge con recortes
    path.lineTo(size.width, divider1Y - notchRadius);
    path.arcToPoint(
      Offset(size.width, divider1Y + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, divider2Y - notchRadius);
    path.arcToPoint(
      Offset(size.width, divider2Y + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height - borderRadius);

    // ✅ Bottom edge
    path.arcToPoint(
      Offset(size.width - borderRadius, size.height),
      radius: Radius.circular(borderRadius),
    );
    path.lineTo(borderRadius, size.height);
    path.arcToPoint(
      Offset(0, size.height - borderRadius),
      radius: Radius.circular(borderRadius),
    );

    // ✅ Left edge con recortes
    path.lineTo(0, divider2Y + notchRadius);
    path.arcToPoint(
      Offset(0, divider2Y - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, divider1Y + notchRadius);
    path.arcToPoint(
      Offset(0, divider1Y - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, borderRadius);

    // ✅ Top left corner
    path.arcToPoint(
      Offset(borderRadius, 0),
      radius: Radius.circular(borderRadius),
    );

    path.close();

    // Dibujar relleno y borde
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ✅ Painter de línea punteada
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF444444).withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 6.0;
    const dashSpace = 6.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
