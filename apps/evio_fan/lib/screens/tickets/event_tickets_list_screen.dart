import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/ticket_provider.dart';

/// Screen que muestra la lista de tickets de un evento
class EventTicketsListScreen extends ConsumerWidget {
  final String eventId;

  const EventTicketsListScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTicketsAsync = ref.watch(myActiveTicketsProvider);

    return Scaffold(
      backgroundColor: EvioFanColors.background,
      body: Container(
        decoration: EvioBackgrounds.screenBackground(EvioFanColors.background),
        child: allTicketsAsync.when(
          data: (allTickets) {
            final eventTickets = allTickets
                .where((t) => t.eventId == eventId)
                .toList();

            if (eventTickets.isEmpty) {
              return _buildEmptyState(context);
            }

            final firstTicket = eventTickets.first;
            final event = firstTicket.event;

            return CustomScrollView(
              slivers: [
                // Simple App Bar
                SliverAppBar(
                  backgroundColor: EvioFanColors.background,
                  pinned: true,
                  title: Text(
                    event?.title ?? 'Mis Tickets',
                    style: EvioTypography.h3.copyWith(
                      color: EvioFanColors.foreground,
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: EvioFanColors.foreground),
                    onPressed: () => context.pop(),
                  ),
                ),

                // QR Availability Warning (una sola vez arriba)
                if (!_canShowQR(firstTicket))
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(EvioSpacing.lg),
                      child: Container(
                        padding: EdgeInsets.all(EvioSpacing.md),
                        decoration: BoxDecoration(
                          color: EvioFanColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(EvioRadius.card),
                          border: Border.all(
                            color: EvioFanColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: EvioFanColors.warning,
                            ),
                            SizedBox(width: EvioSpacing.sm),
                            Expanded(
                              child: Text(
                                'Los códigos QR se habilitarán el día del evento',
                                style: EvioTypography.bodyMedium.copyWith(
                                  color: EvioFanColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Tickets Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      EvioSpacing.lg,
                      EvioSpacing.xl,
                      EvioSpacing.lg,
                      EvioSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'TUS TICKETS',
                          style: EvioTypography.labelSmall.copyWith(
                            color: EvioFanColors.mutedForeground,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: EvioSpacing.sm),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: EvioSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: EvioFanColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${eventTickets.length}',
                            style: EvioTypography.labelSmall.copyWith(
                              color: EvioFanColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tickets List
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final ticket = eventTickets[index];
                        return Padding(
                          padding: EdgeInsets.only(bottom: EvioSpacing.md),
                          child: _TicketItem(
                            ticket: ticket,
                            ticketNumber: index + 1,
                            canShowQR: _canShowQR(ticket),
                            onView: () {
                              context.push('/ticket-detail/$eventId?initialIndex=$index');
                            },
                            onTransfer: ticket.transferAllowed && !ticket.isUsed
                                ? () => _showTransferBottomSheet(context, ticket)
                                : null,
                          ),
                        );
                      },
                      childCount: eventTickets.length,
                    ),
                  ),
                ),

                // Bottom spacing
                SliverToBoxAdapter(
                  child: SizedBox(height: EvioSpacing.xxl),
                ),
              ],
            );
          },
          loading: () => Center(
            child: CircularProgressIndicator(color: EvioFanColors.primary),
          ),
          error: (e, st) => Center(
            child: Text(
              'Error: $e',
              style: TextStyle(color: EvioFanColors.error),
            ),
          ),
        ),
      ),
    );
  }

  bool _canShowQR(Ticket ticket) {
    if (ticket.event == null) return false;
    final now = DateTime.now();
    final eventStart = ticket.event!.startDatetime;
    final eventDay = DateTime(eventStart.year, eventStart.month, eventStart.day);
    return now.isAfter(eventDay) || now.isAtSameMomentAs(eventDay);
  }

  void _showTransferBottomSheet(BuildContext context, Ticket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TransferTicketBottomSheet(ticket: ticket),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: EvioFanColors.mutedForeground,
          ),
          SizedBox(height: EvioSpacing.md),
          Text(
            'No hay tickets',
            style: EvioTypography.h3.copyWith(color: EvioFanColors.foreground),
          ),
          SizedBox(height: EvioSpacing.sm),
          Text(
            'No se encontraron tickets para este evento',
            style: EvioTypography.bodyMedium.copyWith(
              color: EvioFanColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

// Bottom Sheet para transferir ticket con búsqueda de usuarios
class _TransferTicketBottomSheet extends StatefulWidget {
  final Ticket ticket;

  const _TransferTicketBottomSheet({required this.ticket});

  @override
  State<_TransferTicketBottomSheet> createState() =>
      _TransferTicketBottomSheetState();
}

class _TransferTicketBottomSheetState
    extends State<_TransferTicketBottomSheet> {
  final _searchController = TextEditingController();
  final _userRepo = UserRepository();
  final _ticketRepo = TicketRepository();
  
  String _searchQuery = '';
  List<User> _searchResults = [];
  bool _isSearching = false;
  String? _selectedUserId;
  String? _selectedUserEmail;
  bool _isTransferring = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: EvioFanColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(EvioRadius.card * 2),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: EvioSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: EvioFanColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.all(EvioSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transferir Ticket',
                            style: EvioTypography.h3.copyWith(
                              color: EvioFanColors.foreground,
                            ),
                          ),
                          SizedBox(height: EvioSpacing.xxs),
                          Text(
                            'Busca por email al usuario que recibirá el ticket',
                            style: EvioTypography.bodySmall.copyWith(
                              color: EvioFanColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: EvioFanColors.foreground),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por email...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: EvioFanColors.mutedForeground,
                    ),
                    filled: true,
                    fillColor: EvioFanColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(EvioRadius.input),
                      borderSide: BorderSide(color: EvioFanColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(EvioRadius.input),
                      borderSide: BorderSide(color: EvioFanColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(EvioRadius.input),
                      borderSide: BorderSide(
                        color: EvioFanColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _performSearch(value);
                  },
                ),
              ),

              SizedBox(height: EvioSpacing.md),

              // Results list
              Expanded(
                child: _searchQuery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 64,
                              color: EvioFanColors.mutedForeground,
                            ),
                            SizedBox(height: EvioSpacing.md),
                            Text(
                              'Escribe para buscar usuarios',
                              style: EvioTypography.bodyMedium.copyWith(
                                color: EvioFanColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildSearchResults(scrollController),
              ),

              // Confirm button
              if (_selectedUserId != null)
                Container(
                  padding: EdgeInsets.all(EvioSpacing.lg),
                  decoration: BoxDecoration(
                    color: EvioFanColors.background,
                    border: Border(
                      top: BorderSide(color: EvioFanColors.border),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.all(EvioSpacing.sm),
                          decoration: BoxDecoration(
                            color: EvioFanColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(EvioRadius.button),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                color: EvioFanColors.primary,
                                size: 20,
                              ),
                              SizedBox(width: EvioSpacing.xs),
                              Expanded(
                                child: Text(
                                  'Enviar a: $_selectedUserEmail',
                                  style: EvioTypography.bodyMedium.copyWith(
                                    color: EvioFanColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: EvioSpacing.md),
                        ElevatedButton(
                          onPressed: _isTransferring ? null : _confirmTransfer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: EvioFanColors.primary,
                            foregroundColor: EvioFanColors.primaryForeground,
                            padding: EdgeInsets.symmetric(
                              vertical: EvioSpacing.md,
                            ),
                          ),
                          child: _isTransferring
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      EvioFanColors.primaryForeground,
                                    ),
                                  ),
                                )
                              : const Text('Confirmar Transferencia'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _userRepo.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Widget _buildSearchResults(ScrollController scrollController) {
    if (_isSearching) {
      return Center(
        child: CircularProgressIndicator(color: EvioFanColors.primary),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron usuarios',
          style: EvioTypography.bodyMedium.copyWith(
            color: EvioFanColors.mutedForeground,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.symmetric(horizontal: EvioSpacing.lg),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => SizedBox(height: EvioSpacing.sm),
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        final isSelected = _selectedUserId == user.id;

        return InkWell(
          onTap: () {
            setState(() {
              _selectedUserId = user.id;
              _selectedUserEmail = user.email;
            });
          },
          borderRadius: BorderRadius.circular(EvioRadius.card),
          child: Container(
            padding: EdgeInsets.all(EvioSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? EvioFanColors.primary.withValues(alpha: 0.1)
                  : EvioFanColors.surface,
              borderRadius: BorderRadius.circular(EvioRadius.card),
              border: Border.all(
                color: isSelected
                    ? EvioFanColors.primary
                    : EvioFanColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      EvioFanColors.primary.withValues(alpha: 0.2),
                  backgroundImage: user.avatarUrl != null
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  child: user.avatarUrl == null
                      ? Text(
                          (user.fullName ?? user.email)[0].toUpperCase(),
                          style: TextStyle(
                            color: EvioFanColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName ?? user.email,
                        style: EvioTypography.bodyMedium.copyWith(
                          color: EvioFanColors.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user.fullName != null)
                        Text(
                          user.email,
                          style: EvioTypography.bodySmall.copyWith(
                            color: EvioFanColors.mutedForeground,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: EvioFanColors.primary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmTransfer() async {
    if (_selectedUserId == null) return;

    setState(() => _isTransferring = true);

    try {
      await _ticketRepo.transferTicket(
        ticketId: widget.ticket.id,
        toUserId: _selectedUserId!,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket transferido exitosamente'),
            backgroundColor: EvioFanColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al transferir: $e'),
            backgroundColor: EvioFanColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }
}

// Ticket Item Widget
class _TicketItem extends StatelessWidget {
  final Ticket ticket;
  final int ticketNumber;
  final bool canShowQR;
  final VoidCallback onView;
  final VoidCallback? onTransfer;

  const _TicketItem({
    required this.ticket,
    required this.ticketNumber,
    required this.canShowQR,
    required this.onView,
    this.onTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = ticket.isInvitation
        ? 'Invitación'
        : (ticket.tier?.name ?? 'General');

    return Container(
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioFanColors.surface,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(
          color: EvioFanColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: EvioFanColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '#$ticketNumber',
                    style: EvioTypography.labelLarge.copyWith(
                      color: EvioFanColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: EvioSpacing.md),

              // Category info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: EvioTypography.labelLarge.copyWith(
                        color: EvioFanColors.foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (ticket.isInvitation && ticket.transferAllowed) ...[
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: EvioSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EvioFanColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: EvioFanColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz,
                              size: 10,
                              color: EvioFanColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Transferible',
                              style: EvioTypography.bodySmall.copyWith(
                                color: EvioFanColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status badge
              if (ticket.isUsed)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: EvioSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: EvioFanColors.mutedForeground.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'USADO',
                    style: EvioTypography.labelSmall.copyWith(
                      color: EvioFanColors.mutedForeground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: EvioSpacing.md),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onView,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EvioFanColors.primary,
                    foregroundColor: EvioFanColors.primaryForeground,
                    padding: EdgeInsets.symmetric(
                      vertical: EvioSpacing.sm,
                    ),
                  ),
                  child: const Text('VER TICKET'),
                ),
              ),
              if (onTransfer != null) ...[
                SizedBox(width: EvioSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTransfer,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: EvioFanColors.foreground,
                      side: BorderSide(color: EvioFanColors.border),
                      padding: EdgeInsets.symmetric(
                        vertical: EvioSpacing.sm,
                      ),
                    ),
                    child: const Text('TRANSFERIR'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

