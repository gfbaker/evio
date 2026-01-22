import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:evio_core/evio_core.dart';
import 'package:intl/intl.dart';

class TicketCard extends StatelessWidget {
  final Ticket ticket;

  const TicketCard({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navegar a detalle del ticket
      },
      child: SizedBox(
        height: 600,
        child: Stack(
          children: [
            // SVG Background con el diseño del ticket
            CustomPaint(
              size: Size(double.infinity, 600),
              painter: TicketBackgroundPainter(),
            ),

            // Contenido del ticket
            Padding(
              padding: EdgeInsets.all(EvioSpacing.xl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header: Evento info
                  _buildHeader(),

                  SizedBox(height: EvioSpacing.xl),

                  // QR Code
                  _buildQRCode(),

                  SizedBox(height: EvioSpacing.xl),

                  // Footer: Ticket ID
                  _buildFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final dateFormat = DateFormat('E, dd MMM - HH:mm', 'es');

    return Column(
      children: [
        Text(
          ticket.event?.title ?? 'Evento',
          style: EvioTypography.h2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: EvioSpacing.sm),
        Text(
          ticket.event?.startDatetime != null
              ? dateFormat.format(ticket.event!.startDatetime)
              : '',
          style: EvioTypography.bodyLarge.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        Text(
          ticket.tier?.name ?? 'General',
          style: EvioTypography.bodyMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildQRCode() {
    // Generar payload seguro con HMAC (compatible con evio_queue)
    final qrPayload = QrService.generateQrPayload(ticket.id, ticket.eventId);
    
    return Container(
      padding: EdgeInsets.all(EvioSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: Color(0xFFC6A664), width: 3),
      ),
      child: QrImageView(
        data: qrPayload,
        version: QrVersions.auto,
        size: 200,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'Ticket ID: ${ticket.id.substring(0, 10)}',
          style: EvioTypography.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: EvioSpacing.lg),

        // Botón Agregar a Wallet (placeholder)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Wallet integration
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFC6A664),
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
            ),
            child: Text('Agregar a Wallet', style: EvioTypography.button),
          ),
        ),
      ],
    );
  }
}

// Custom Painter para el fondo del ticket
class TicketBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF383838)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Esquinas redondeadas superiores
    path.moveTo(0, 20);
    path.quadraticBezierTo(0, 0, 20, 0);

    // Semicírculo superior (muesca)
    path.lineTo(size.width * 0.35, 0);
    path.arcToPoint(
      Offset(size.width * 0.65, 0),
      radius: Radius.circular(50),
      clockwise: false,
    );

    path.lineTo(size.width - 20, 0);
    path.quadraticBezierTo(size.width, 0, size.width, 20);

    // Lado derecho hasta la línea punteada
    path.lineTo(size.width, size.height * 0.67);

    // Muesca derecha
    path.arcToPoint(
      Offset(size.width, size.height * 0.72),
      radius: Radius.circular(15),
      clockwise: false,
    );

    // Continuar hasta abajo
    path.lineTo(size.width, size.height - 20);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - 20,
      size.height,
    );

    // Parte inferior
    path.lineTo(20, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 20);

    // Muesca izquierda
    path.lineTo(0, size.height * 0.72);
    path.arcToPoint(
      Offset(0, size.height * 0.67),
      radius: Radius.circular(15),
      clockwise: false,
    );

    path.close();

    canvas.drawPath(path, paint);

    // Línea punteada
    final dashedPaint = Paint()
      ..color = Color(0xFF1a1a1a).withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8;
    const dashSpace = 5;
    double startX = 25;
    final y = size.height * 0.69;

    while (startX < size.width - 25) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        dashedPaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
