import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../widgets/common/floating_snackbar.dart';

/// Drawer lateral para gestionar invitaciones de un evento
class InvitationsDrawer extends ConsumerStatefulWidget {
  final String eventId;

  const InvitationsDrawer({
    required this.eventId,
    super.key,
  });

  @override
  ConsumerState<InvitationsDrawer> createState() => _InvitationsDrawerState();
}

class _InvitationsDrawerState extends ConsumerState<InvitationsDrawer> {
  final _emailController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String? _emailError;
  String? _quantityError;
  bool _isTransferable = false;
  bool _isDisposed = false;
  bool _isSending = false;

  final _invitationRepo = TicketInvitationRepository();
  
  // ✅ Cachear futures para evitar rebuilds
  late final Future<Map<String, int>> _statsFuture;
  late Future<List<TicketInvitation>> _invitationsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _invitationRepo.getInvitationStats(widget.eventId);
    _invitationsFuture = _invitationRepo.getInvitations(widget.eventId);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _validate() {
    if (_isDisposed) return;

    setState(() {
      _emailError = null;
      _quantityError = null;

      // Validar email
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'El email es obligatorio';
      } else if (!_isValidEmail(email)) {
        _emailError = 'Email inválido';
      }

      // Validar cantidad
      if (_quantityController.text.isEmpty) {
        _quantityError = 'La cantidad es obligatoria';
      } else {
        final qty = int.tryParse(_quantityController.text);
        if (qty == null) {
          _quantityError = 'Debe ser un número válido';
        } else if (qty <= 0) {
          _quantityError = 'Debe ser mayor a 0';
        } else if (qty > 100) {
          _quantityError = 'Máximo 100 invitaciones por envío';
        }
      }
    });

    // Si no hay errores, enviar
    if (_emailError == null && _quantityError == null) {
      _sendInvitation();
    }
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  Future<void> _sendInvitation() async {
    if (_isDisposed || _isSending) return;

    setState(() => _isSending = true);

    try {
      final email = _emailController.text.trim();
      final quantity = int.parse(_quantityController.text);

      await _invitationRepo.sendInvitation(
        eventId: widget.eventId,
        recipientEmail: email,
        quantity: quantity,
        isTransferable: _isTransferable,
        message: null, // Sin mensaje
      );

      if (_isDisposed || !mounted) return;

      // Limpiar form
      _emailController.clear();
      _quantityController.text = '1';
      setState(() {
        _isTransferable = false;
        _isSending = false;
        // ✅ Refrescar futures
        _statsFuture = _invitationRepo.getInvitationStats(widget.eventId);
        _invitationsFuture = _invitationRepo.getInvitations(widget.eventId);
      });

      FloatingSnackBar.show(
        context,
        message: 'Invitación enviada exitosamente',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;

      setState(() => _isSending = false);

      FloatingSnackBar.show(
        context,
        message: 'Error al enviar invitación: $e',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    if (_isDisposed) return;

    try {
      await _invitationRepo.cancelInvitation(invitationId);

      if (_isDisposed || !mounted) return;

      setState(() {
        // ✅ Refrescar futures
        _statsFuture = _invitationRepo.getInvitationStats(widget.eventId);
        _invitationsFuture = _invitationRepo.getInvitations(widget.eventId);
      });

      FloatingSnackBar.show(
        context,
        message: 'Invitación cancelada',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;

      FloatingSnackBar.show(
        context,
        message: 'Error al cancelar: $e',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 600,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + EvioSpacing.lg,
              left: EvioSpacing.lg,
              right: EvioSpacing.lg,
              bottom: EvioSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: EvioLightColors.background,
              border: Border(
                bottom: BorderSide(color: EvioLightColors.border),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enviar Invitaciones',
                        style: EvioTypography.h3,
                      ),
                      SizedBox(height: EvioSpacing.xxs),
                      Text(
                        'Tickets gratuitos para invitados',
                        style: EvioTypography.bodySmall.copyWith(
                          color: EvioLightColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(EvioSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Card
                  _buildStatsCard(),
                  SizedBox(height: EvioSpacing.xl),

                  // Divider
                  Divider(color: EvioLightColors.border),
                  SizedBox(height: EvioSpacing.xl),

                  // Nueva Invitación Form
                  Text('Nueva Invitación', style: EvioTypography.h4),
                  SizedBox(height: EvioSpacing.md),

                  // Email
                  Text('Email del invitado *', style: EvioTypography.labelMedium),
                  SizedBox(height: EvioSpacing.xs),
                  _buildEmailField(),
                  SizedBox(height: EvioSpacing.lg),

                  // Cantidad
                  Text('Cantidad de tickets *', style: EvioTypography.labelMedium),
                  SizedBox(height: EvioSpacing.xs),
                  _buildQuantityField(),
                  SizedBox(height: EvioSpacing.lg),

                  // Transferible checkbox
                  _buildTransferableCheckbox(),
                  SizedBox(height: EvioSpacing.xl),

                  // Botón Enviar
                  _buildSendButton(),
                  SizedBox(height: EvioSpacing.xxl),

                  // Divider
                  Divider(color: EvioLightColors.border),
                  SizedBox(height: EvioSpacing.xl),

                  // Lista de invitaciones
                  _buildInvitationsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'nombre@ejemplo.com',
        errorText: _emailError,
        filled: true,
        fillColor: EvioLightColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EvioRadius.input),
          borderSide: BorderSide(
            color: _emailError != null ? Colors.red : EvioLightColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EvioRadius.input),
          borderSide: BorderSide(
            color: _emailError != null ? Colors.red : EvioLightColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EvioRadius.input),
          borderSide: BorderSide(
            color: _emailError != null ? Colors.red : EvioLightColors.primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.all(EvioSpacing.md),
      ),
      keyboardType: TextInputType.emailAddress,
      autofocus: true,
      onChanged: (_) {
        if (_emailError != null && !_isDisposed) {
          setState(() => _emailError = null);
        }
      },
    );
  }

  Widget _buildQuantityField() {
    return TextField(
      controller: _quantityController,
      decoration: InputDecoration(
        hintText: '1',
        errorText: _quantityError,
        filled: true,
        fillColor: EvioLightColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EvioRadius.input),
          borderSide: BorderSide(
            color: _quantityError != null ? Colors.red : EvioLightColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EvioRadius.input),
          borderSide: BorderSide(
            color: _quantityError != null ? Colors.red : EvioLightColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EvioRadius.input),
          borderSide: BorderSide(
            color: _quantityError != null ? Colors.red : EvioLightColors.primary,
            width: 2,
          ),
        ),
        contentPadding: EdgeInsets.all(EvioSpacing.md),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) {
        if (_quantityError != null && !_isDisposed) {
          setState(() => _quantityError = null);
        }
      },
    );
  }

  Widget _buildTransferableCheckbox() {
    return InkWell(
      onTap: () {
        if (!_isDisposed) {
          setState(() => _isTransferable = !_isTransferable);
        }
      },
      borderRadius: BorderRadius.circular(EvioRadius.card),
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.md),
        decoration: BoxDecoration(
          color: _isTransferable
              ? EvioLightColors.primary.withValues(alpha: 0.1)
              : EvioLightColors.background,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          border: Border.all(
            color: _isTransferable
                ? EvioLightColors.primary
                : EvioLightColors.border,
          ),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _isTransferable,
              onChanged: (value) {
                if (!_isDisposed) {
                  setState(() => _isTransferable = value ?? false);
                }
              },
              activeColor: EvioLightColors.primary,
            ),
            SizedBox(width: EvioSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket Transferible',
                    style: EvioTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: EvioSpacing.xxs),
                  Text(
                    'El invitado podrá reenviar este ticket a otra persona (1 vez)',
                    style: EvioTypography.bodySmall.copyWith(
                      color: EvioLightColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSending ? null : _validate,
        style: ElevatedButton.styleFrom(
          backgroundColor: EvioLightColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
          disabledBackgroundColor: EvioLightColors.muted,
        ),
        child: _isSending
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text('Enviar Invitación'),
      ),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: snapshot.connectionState == ConnectionState.waiting ? 0.5 : 1.0,
          child: Container(
            padding: EdgeInsets.all(EvioSpacing.lg),
            decoration: BoxDecoration(
              color: EvioLightColors.card,
              borderRadius: BorderRadius.circular(EvioRadius.card),
              border: Border.all(color: EvioLightColors.border),
            ),
            child: snapshot.connectionState == ConnectionState.waiting
                ? _buildStatsSkeleton()
                : _buildStatsContent(snapshot.data ?? {}),
          ),
        );
      },
    );
  }

  Widget _buildStatsSkeleton() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: EvioLightColors.muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: EvioSpacing.sm),
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: EvioLightColors.muted,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.md),
        Row(
          children: [
            Expanded(child: _buildSkeletonStatItem()),
            Expanded(child: _buildSkeletonStatItem()),
          ],
        ),
        SizedBox(height: EvioSpacing.sm),
        Row(
          children: [
            Expanded(child: _buildSkeletonStatItem()),
            Expanded(child: _buildSkeletonStatItem()),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonStatItem() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 24,
          decoration: BoxDecoration(
            color: EvioLightColors.muted,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: EvioSpacing.xxs),
        Container(
          width: 60,
          height: 12,
          decoration: BoxDecoration(
            color: EvioLightColors.muted,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsContent(Map<String, int> stats) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.email_outlined, color: EvioLightColors.primary, size: 20),
            SizedBox(width: EvioSpacing.sm),
            Text(
              'Estadísticas',
              style: EvioTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.md),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Total Enviadas',
                value: stats['total_sent'].toString(),
                color: EvioLightColors.primary,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Asignadas',
                value: stats['assigned'].toString(),
                color: EvioLightColors.success,
              ),
            ),
          ],
        ),
        SizedBox(height: EvioSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _StatItem(
                label: 'Pendientes',
                value: stats['pending'].toString(),
                color: Colors.orange,
              ),
            ),
            Expanded(
              child: _StatItem(
                label: 'Canceladas',
                value: stats['cancelled'].toString(),
                color: EvioLightColors.mutedForeground,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInvitationsList() {
    return FutureBuilder<List<TicketInvitation>>(
      future: _invitationsFuture,
      builder: (context, snapshot) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: snapshot.connectionState == ConnectionState.waiting ? 0.5 : 1.0,
          child: Container(
            constraints: BoxConstraints(minHeight: 200),
            child: snapshot.connectionState == ConnectionState.waiting
                ? _buildInvitationsListSkeleton()
                : _buildInvitationsListContent(snapshot),
          ),
        );
      },
    );
  }

  Widget _buildInvitationsListSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 140,
          height: 20,
          decoration: BoxDecoration(
            color: EvioLightColors.muted,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(height: EvioSpacing.md),
        ...List.generate(2, (index) => _buildInvitationItemSkeleton()),
      ],
    );
  }

  Widget _buildInvitationItemSkeleton() {
    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.sm),
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.background,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: EvioLightColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 16,
            decoration: BoxDecoration(
              color: EvioLightColors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: EvioSpacing.xs),
          Container(
            width: 120,
            height: 14,
            decoration: BoxDecoration(
              color: EvioLightColors.muted,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsListContent(
      AsyncSnapshot<List<TicketInvitation>> snapshot) {
    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Error al cargar invitaciones',
          style: TextStyle(color: EvioLightColors.destructive),
        ),
      );
    }

    final invitations = snapshot.data ?? [];

    if (invitations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(EvioSpacing.xl),
          child: Text(
            'No hay invitaciones enviadas',
            style: TextStyle(color: EvioLightColors.mutedForeground),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Invitaciones Enviadas', style: EvioTypography.h4),
        SizedBox(height: EvioSpacing.md),
        ...invitations.map((invitation) {
          return _InvitationItem(
            invitation: invitation,
            onCancel: () => _cancelInvitation(invitation.id),
          );
        }),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: EvioSpacing.xxs),
        Text(
          label,
          style: EvioTypography.bodySmall.copyWith(
            color: EvioLightColors.mutedForeground,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _InvitationItem extends StatelessWidget {
  final TicketInvitation invitation;
  final VoidCallback onCancel;

  const _InvitationItem({
    required this.invitation,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (invitation.status) {
      case TicketInvitationStatus.assigned:
        statusColor = EvioLightColors.success;
        statusLabel = 'Asignada';
        statusIcon = Icons.check_circle;
        break;
      case TicketInvitationStatus.cancelled:
        statusColor = EvioLightColors.mutedForeground;
        statusLabel = 'Cancelada';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = 'Pendiente';
        statusIcon = Icons.schedule;
    }

    return Container(
      margin: EdgeInsets.only(bottom: EvioSpacing.sm),
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.background,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: EvioLightColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email, size: 16, color: EvioLightColors.primary),
              SizedBox(width: EvioSpacing.xs),
              Expanded(
                child: Text(
                  invitation.recipientEmail,
                  style: EvioTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.xs,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.xs),
          Row(
            children: [
              Text(
                '${invitation.quantity} ticket${invitation.quantity > 1 ? 's' : ''}',
                style: EvioTypography.bodySmall.copyWith(
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              if (invitation.isTransferable) ...[
                SizedBox(width: EvioSpacing.xs),
                Text('•', style: TextStyle(color: EvioLightColors.mutedForeground)),
                SizedBox(width: EvioSpacing.xs),
                Icon(Icons.swap_horiz, size: 14, color: EvioLightColors.mutedForeground),
                SizedBox(width: 4),
                Text(
                  'Transferible',
                  style: EvioTypography.bodySmall.copyWith(
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
          if (invitation.message != null) ...[
            SizedBox(height: EvioSpacing.xs),
            Text(
              invitation.message!,
              style: EvioTypography.bodySmall.copyWith(
                color: EvioLightColors.mutedForeground,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (invitation.isPending) ...[
            SizedBox(height: EvioSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: EvioLightColors.destructive,
                  side: BorderSide(color: EvioLightColors.destructive),
                  padding: EdgeInsets.symmetric(vertical: EvioSpacing.xs),
                ),
                child: const Text('Cancelar Invitación'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
