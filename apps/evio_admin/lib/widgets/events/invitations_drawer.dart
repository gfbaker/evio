import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../widgets/common/floating_snackbar.dart';

/// Drawer lateral para gestionar invitaciones de un evento.
/// Diseño actualizado con estilo amarillo accent.
class InvitationsDrawer extends ConsumerStatefulWidget {
  final String eventId;

  const InvitationsDrawer({required this.eventId, super.key});

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

  late Future<Map<String, int>> _statsFuture;
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

  void _refreshData() {
    if (_isDisposed) return;
    setState(() {
      _statsFuture = _invitationRepo.getInvitationStats(widget.eventId);
      _invitationsFuture = _invitationRepo.getInvitations(widget.eventId);
    });
  }

  void _validate() {
    if (_isDisposed) return;

    setState(() {
      _emailError = null;
      _quantityError = null;

      final email = _emailController.text.trim();
      if (email.isEmpty) {
        _emailError = 'El email es obligatorio';
      } else if (!_isValidEmail(email)) {
        _emailError = 'Email inválido';
      }

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
        message: null,
      );

      if (_isDisposed || !mounted) return;

      _emailController.clear();
      _quantityController.text = '1';
      setState(() {
        _isTransferable = false;
        _isSending = false;
      });
      _refreshData();

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

      _refreshData();

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
      width: 500,
      backgroundColor: EvioLightColors.surface,
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(EvioSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsCard(),
                  SizedBox(height: EvioSpacing.xl),
                  _buildNewInvitationForm(),
                  SizedBox(height: EvioSpacing.xl),
                  _buildInvitationsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + EvioSpacing.lg,
        left: EvioSpacing.lg,
        right: EvioSpacing.lg,
        bottom: EvioSpacing.lg,
      ),
      color: EvioLightColors.surface,
      child: Row(
        children: [
          // Botón cerrar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: EvioLightColors.card,
              borderRadius: BorderRadius.circular(EvioRadius.button),
            ),
            child: IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          SizedBox(width: EvioSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enviar Invitaciones',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Tickets gratuitos para invitados',
                  style: TextStyle(
                    fontSize: 14,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, int>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final stats = snapshot.data ?? {};

        return Container(
          padding: EdgeInsets.all(EvioSpacing.lg),
          decoration: BoxDecoration(
            color: EvioLightColors.card,
            borderRadius: BorderRadius.circular(EvioRadius.card),
          ),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: EvioLightColors.accent,
                      borderRadius: BorderRadius.circular(EvioRadius.button),
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 20,
                      color: EvioLightColors.accentForeground,
                    ),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  Text(
                    'Estadísticas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: EvioLightColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: EvioSpacing.lg),

              // Stats grid
              if (isLoading)
                SizedBox(
                  height: 60,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: EvioLightColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    _StatBox(
                      label: 'Enviadas',
                      value: '${stats['total_sent'] ?? 0}',
                      color: EvioLightColors.accent,
                    ),
                    SizedBox(width: EvioSpacing.sm),
                    _StatBox(
                      label: 'Asignadas',
                      value: '${stats['assigned'] ?? 0}',
                      color: EvioLightColors.success,
                    ),
                    SizedBox(width: EvioSpacing.sm),
                    _StatBox(
                      label: 'Pendientes',
                      value: '${stats['pending'] ?? 0}',
                      color: Colors.orange,
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNewInvitationForm() {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.lg),
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EvioLightColors.accent,
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                ),
                child: Icon(
                  Icons.send_outlined,
                  size: 20,
                  color: EvioLightColors.accentForeground,
                ),
              ),
              SizedBox(width: EvioSpacing.sm),
              Text(
                'Nueva Invitación',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: EvioLightColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.lg),

          // Email field
          Text(
            'Email del invitado *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: EvioLightColors.textPrimary,
            ),
          ),
          SizedBox(height: EvioSpacing.xs),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              hintText: 'nombre@ejemplo.com',
              errorText: _emailError,
              filled: true,
              fillColor: EvioLightColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EvioRadius.input),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(EvioSpacing.md),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) {
              if (_emailError != null && !_isDisposed) {
                setState(() => _emailError = null);
              }
            },
          ),
          SizedBox(height: EvioSpacing.md),

          // Quantity field
          Text(
            'Cantidad de tickets *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: EvioLightColors.textPrimary,
            ),
          ),
          SizedBox(height: EvioSpacing.xs),
          TextField(
            controller: _quantityController,
            decoration: InputDecoration(
              hintText: '1',
              errorText: _quantityError,
              filled: true,
              fillColor: EvioLightColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EvioRadius.input),
                borderSide: BorderSide.none,
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
          ),
          SizedBox(height: EvioSpacing.md),

          // Transferable toggle
          InkWell(
            onTap: () {
              if (!_isDisposed) {
                setState(() => _isTransferable = !_isTransferable);
              }
            },
            borderRadius: BorderRadius.circular(EvioRadius.button),
            child: Container(
              padding: EdgeInsets.all(EvioSpacing.md),
              decoration: BoxDecoration(
                color: _isTransferable
                    ? EvioLightColors.accent.withValues(alpha: 0.1)
                    : EvioLightColors.surface,
                borderRadius: BorderRadius.circular(EvioRadius.button),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _isTransferable,
                    onChanged: (v) {
                      if (!_isDisposed) {
                        setState(() => _isTransferable = v ?? false);
                      }
                    },
                    activeColor: EvioLightColors.accent,
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ticket Transferible',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: EvioLightColors.textPrimary,
                          ),
                        ),
                        Text(
                          'El invitado podrá reenviar este ticket',
                          style: TextStyle(
                            fontSize: 12,
                            color: EvioLightColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: EvioSpacing.lg),

          // Send button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSending ? null : _validate,
              icon: _isSending
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: EvioLightColors.accentForeground,
                      ),
                    )
                  : Icon(Icons.send, size: 18),
              label: Text('Enviar Invitación'),
              style: FilledButton.styleFrom(
                backgroundColor: EvioLightColors.accent,
                foregroundColor: EvioLightColors.accentForeground,
                padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsList() {
    return FutureBuilder<List<TicketInvitation>>(
      future: _invitationsFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final invitations = snapshot.data ?? [];

        return Container(
          padding: EdgeInsets.all(EvioSpacing.lg),
          decoration: BoxDecoration(
            color: EvioLightColors.card,
            borderRadius: BorderRadius.circular(EvioRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: EvioLightColors.accent,
                      borderRadius: BorderRadius.circular(EvioRadius.button),
                    ),
                    child: Icon(
                      Icons.list_alt,
                      size: 20,
                      color: EvioLightColors.accentForeground,
                    ),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  Text(
                    'Invitaciones Enviadas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: EvioLightColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: EvioSpacing.lg),

              // Content
              if (isLoading)
                SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: EvioLightColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (invitations.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(EvioSpacing.lg),
                    child: Text(
                      'No hay invitaciones enviadas',
                      style: TextStyle(color: EvioLightColors.mutedForeground),
                    ),
                  ),
                )
              else
                ...invitations.map((inv) => _InvitationItem(
                      invitation: inv,
                      onCancel: () => _cancelInvitation(inv.id),
                    )),
            ],
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// WIDGETS AUXILIARES
// -----------------------------------------------------------------------------

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(EvioSpacing.md),
        decoration: BoxDecoration(
          color: EvioLightColors.surface,
          borderRadius: BorderRadius.circular(EvioRadius.button),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: EvioLightColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
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
        color: EvioLightColors.surface,
        borderRadius: BorderRadius.circular(EvioRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email, size: 16, color: EvioLightColors.accent),
              SizedBox(width: EvioSpacing.xs),
              Expanded(
                child: Text(
                  invitation.recipientEmail,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
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
                        fontSize: 11,
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
                style: TextStyle(
                  fontSize: 12,
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              if (invitation.isTransferable) ...[
                SizedBox(width: EvioSpacing.sm),
                Icon(Icons.swap_horiz, size: 14, color: EvioLightColors.mutedForeground),
                SizedBox(width: 4),
                Text(
                  'Transferible',
                  style: TextStyle(
                    fontSize: 12,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                ),
                child: Text('Cancelar Invitación'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
