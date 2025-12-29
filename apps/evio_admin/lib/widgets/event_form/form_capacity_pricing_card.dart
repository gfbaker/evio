import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';
import '../common/form_card.dart';

class FormCapacityPricingCard extends StatefulWidget {
  final TextEditingController capacityCtrl;
  final List<TicketType> ticketTypes;
  final bool showAllTicketTypes;  // ✅ Nuevo
  final Function(String name, String? description, int price, int qty, int? maxPerPurchase) onAddTier;
  final Function(int index, String name, String? description, int price, int qty, int? maxPerPurchase) onEditTier;
  final Function(int index) onRemoveTier;
  final Function(int oldIndex, int newIndex) onReorderTiers;
  final Function(int index) onToggleActive;  // ✅ Nuevo
  final Function(bool value) onToggleShowAll;  // ✅ Nuevo

  const FormCapacityPricingCard({
    required this.capacityCtrl,
    required this.ticketTypes,
    required this.showAllTicketTypes,
    required this.onAddTier,
    required this.onEditTier,
    required this.onRemoveTier,
    required this.onReorderTiers,
    required this.onToggleActive,
    required this.onToggleShowAll,
    super.key,
  });

  @override
  State<FormCapacityPricingCard> createState() => _FormCapacityPricingCardState();
}

class _FormCapacityPricingCardState extends State<FormCapacityPricingCard> {
  bool _isFormVisible = false;
  int? _editingIndex;
  
  final _tierNameController = TextEditingController();
  final _tierDescriptionController = TextEditingController();
  final _tierPriceController = TextEditingController();
  final _tierQuantityController = TextEditingController();
  final _tierMaxPerPurchaseController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _tierNameController.dispose();
    _tierDescriptionController.dispose();
    _tierPriceController.dispose();
    _tierQuantityController.dispose();
    _tierMaxPerPurchaseController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _tierNameController.clear();
    _tierDescriptionController.clear();
    _tierPriceController.clear();
    _tierQuantityController.clear();
    _tierMaxPerPurchaseController.clear();
    _editingIndex = null;
  }

  void _loadTierData(TicketType ticket, int index) {
    setState(() {
      _isFormVisible = true;
      _editingIndex = index;
      _tierNameController.text = ticket.name;
      _tierDescriptionController.text = ticket.description ?? '';
      _tierPriceController.text = (ticket.price ~/ 100).toString();
      _tierQuantityController.text = ticket.totalQuantity.toString();
      _tierMaxPerPurchaseController.text = ticket.maxPerPurchase?.toString() ?? '';
    });
  }

  void _saveTier() {
    if (!_formKey.currentState!.validate()) return;

    final name = _tierNameController.text.trim();
    final description = _tierDescriptionController.text.trim().isEmpty
        ? null
        : _tierDescriptionController.text.trim();
    final price = int.parse(_tierPriceController.text) * 100;
    final qty = int.parse(_tierQuantityController.text);
    final maxPerPurchase = _tierMaxPerPurchaseController.text.isEmpty
        ? null
        : int.parse(_tierMaxPerPurchaseController.text);

    if (_editingIndex != null) {
      widget.onEditTier(_editingIndex!, name, description, price, qty, maxPerPurchase);
    } else {
      widget.onAddTier(name, description, price, qty, maxPerPurchase);
    }

    setState(() {
      _isFormVisible = false;
      _clearForm();
    });
  }

  void _cancelForm() {
    setState(() {
      _isFormVisible = false;
      _clearForm();
    });
  }

  int get _totalTicketsCreated {
    return widget.ticketTypes.fold(0, (sum, ticket) => sum + ticket.totalQuantity);
  }

  int get _remainingCapacity {
    final maxCapacity = int.tryParse(widget.capacityCtrl.text) ?? 0;
    return maxCapacity - _totalTicketsCreated;
  }

  @override
  Widget build(BuildContext context) {
    final maxCapacity = int.tryParse(widget.capacityCtrl.text) ?? 0;
    final hasCapacity = maxCapacity > 0;

    return FormCard(
      title: 'Capacidad, Precios y Tandas',
      icon: Icons.confirmation_number_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capacidad Total
          Text(
            'Capacidad Total *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: EvioLightColors.foreground,
            ),
          ),
          SizedBox(height: EvioSpacing.xs),
          TextField(
            controller: widget.capacityCtrl,
            decoration: InputDecoration(
              hintText: 'Ej: 500',
              hintStyle: TextStyle(fontSize: 13),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EvioRadius.input),
                borderSide: BorderSide(color: EvioLightColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(EvioRadius.input),
                borderSide: BorderSide(color: EvioLightColors.border),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: EvioSpacing.sm,
                vertical: EvioSpacing.sm,
              ),
            ),
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 14),
          ),

          // Indicador de capacidad restante
          if (hasCapacity && widget.ticketTypes.isNotEmpty) ...[
            SizedBox(height: EvioSpacing.sm),
            Container(
              padding: EdgeInsets.all(EvioSpacing.sm),
              decoration: BoxDecoration(
                color: _remainingCapacity < 0
                    ? EvioLightColors.destructive.withOpacity(0.1)
                    : _remainingCapacity == 0
                        ? EvioLightColors.primary.withOpacity(0.1)
                        : EvioLightColors.muted,
                borderRadius: BorderRadius.circular(EvioRadius.button),
                border: Border.all(
                  color: _remainingCapacity < 0
                      ? EvioLightColors.destructive
                      : _remainingCapacity == 0
                          ? EvioLightColors.primary
                          : EvioLightColors.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _remainingCapacity < 0
                        ? Icons.warning_amber_rounded
                        : _remainingCapacity == 0
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                    size: 18,
                    color: _remainingCapacity < 0
                        ? EvioLightColors.destructive
                        : _remainingCapacity == 0
                            ? EvioLightColors.primary
                            : EvioLightColors.mutedForeground,
                  ),
                  SizedBox(width: EvioSpacing.xs),
                  Expanded(
                    child: Text(
                      _remainingCapacity < 0
                          ? 'Excediste la capacidad por ${-_remainingCapacity} tickets'
                          : _remainingCapacity == 0
                              ? 'Capacidad completa: $_totalTicketsCreated/$maxCapacity'
                              : 'Capacidad restante: $_remainingCapacity de $maxCapacity',
                      style: TextStyle(
                        fontSize: 12,
                        color: _remainingCapacity < 0
                            ? EvioLightColors.destructive
                            : _remainingCapacity == 0
                                ? EvioLightColors.primary
                                : EvioLightColors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          SizedBox(height: EvioSpacing.lg),
          Divider(color: EvioLightColors.border),
          SizedBox(height: EvioSpacing.lg),

          // Header de Tandas con botón toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tandas de Pre-venta',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: EvioLightColors.foreground,
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    if (_isFormVisible && _editingIndex == null) {
                      // Si el form está abierto en modo crear, cerrarlo
                      _isFormVisible = false;
                      _clearForm();
                    } else {
                      // Abrir form en modo crear
                      _isFormVisible = true;
                      _clearForm();
                    }
                  });
                },
                icon: Icon(
                  _isFormVisible && _editingIndex == null ? Icons.close : Icons.add,
                  size: 16,
                ),
                label: Text(_isFormVisible && _editingIndex == null ? 'Cancelar' : 'Añadir'),
                style: FilledButton.styleFrom(
                  backgroundColor: EvioLightColors.foreground,
                  foregroundColor: EvioLightColors.background,
                  padding: EdgeInsets.symmetric(
                    horizontal: EvioSpacing.md,
                    vertical: EvioSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                  minimumSize: Size(0, 36),
                ),
              ),
            ],
          ),

          // Formulario inline (NUEVO)
          if (_isFormVisible) ...[
            SizedBox(height: EvioSpacing.md),
            _buildInlineForm(),
          ],

          // Lista de tandas
          if (widget.ticketTypes.isEmpty && !_isFormVisible) ...[
            SizedBox(height: EvioSpacing.lg),
            Center(
              child: Text(
                'No hay tandas creadas aún',
                style: TextStyle(
                  color: EvioLightColors.mutedForeground,
                  fontSize: 13,
                ),
              ),
            ),
          ] else if (widget.ticketTypes.isNotEmpty) ...[
            SizedBox(height: EvioSpacing.md),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: widget.ticketTypes.length,
              onReorder: widget.onReorderTiers,
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 2,
                  color: Colors.transparent,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final ticket = widget.ticketTypes[index];
                return _TierItem(
                  key: ValueKey(ticket.id),
                  ticket: ticket,
                  index: index,
                  onEdit: () => _loadTierData(ticket, index),
                  onDelete: () => widget.onRemoveTier(index),
                  onToggleActive: () => widget.onToggleActive(index),
                );
              },
            ),
            
            // ✅ Toggle: Mostrar todas las tandas en la app (MOVIDO ABAJO)
            SizedBox(height: EvioSpacing.lg),
            Container(
              padding: EdgeInsets.all(EvioSpacing.md),
              decoration: BoxDecoration(
                color: EvioLightColors.muted,
                borderRadius: BorderRadius.circular(EvioRadius.button),
                border: Border.all(color: EvioLightColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 20,
                    color: EvioLightColors.mutedForeground,
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mostrar todas las tandas en la app',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: EvioLightColors.foreground,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.showAllTicketTypes
                              ? 'Los fans verán todas las tandas (activas e inactivas)'
                              : 'Los fans solo verán las tandas activas',
                          style: TextStyle(
                            fontSize: 12,
                            color: EvioLightColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: widget.showAllTicketTypes,
                    onChanged: widget.onToggleShowAll,
                    activeColor: EvioLightColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✨ NUEVO: Formulario inline moderno
  Widget _buildInlineForm() {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EvioLightColors.surface,
            EvioLightColors.surfaceVariant,
          ],
        ),
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(
          color: _editingIndex != null
              ? EvioLightColors.primary.withValues(alpha: 0.3)
              : EvioLightColors.border,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del form
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(EvioSpacing.xs),
                  decoration: BoxDecoration(
                    color: _editingIndex != null
                        ? EvioLightColors.primary
                        : EvioLightColors.foreground,
                    borderRadius: BorderRadius.circular(EvioRadius.button),
                  ),
                  child: Icon(
                    _editingIndex != null ? Icons.edit : Icons.add_circle_outline,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: EvioSpacing.sm),
                Text(
                  _editingIndex != null ? 'Editar Tanda' : 'Nueva Tanda de Tickets',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: EvioSpacing.lg),
            
            // Nombre
            Text(
              'Nombre *',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: EvioSpacing.xxs),
            TextFormField(
              controller: _tierNameController,
              decoration: InputDecoration(
                hintText: 'Ej: Early Bird, VIP, General',
                hintStyle: TextStyle(fontSize: 13, color: EvioLightColors.mutedForeground),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioLightColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioLightColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioLightColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.sm,
                  vertical: EvioSpacing.sm,
                ),
              ),
              style: TextStyle(fontSize: 14),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            
            SizedBox(height: EvioSpacing.md),
            
            // Descripción
            Text(
              'Descripción (opcional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: EvioSpacing.xxs),
            TextFormField(
              controller: _tierDescriptionController,
              decoration: InputDecoration(
                hintText: 'Ej: Precio especial para los primeros compradores',
                hintStyle: TextStyle(fontSize: 13, color: EvioLightColors.mutedForeground),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioLightColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioLightColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioLightColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.sm,
                  vertical: EvioSpacing.sm,
                ),
              ),
              style: TextStyle(fontSize: 14),
              maxLines: 2,
            ),
            
            SizedBox(height: EvioSpacing.md),
            
            // Precio y Cantidad en fila
            Row(
              children: [
                // Precio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Precio (ARS) *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: EvioLightColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: EvioSpacing.xxs),
                      TextFormField(
                        controller: _tierPriceController,
                        decoration: InputDecoration(
                          hintText: '2500',
                          prefixText: '\$ ',
                          hintStyle: TextStyle(fontSize: 13, color: EvioLightColors.mutedForeground),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(EvioRadius.input),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(EvioRadius.input),
                            borderSide: BorderSide(color: EvioLightColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(EvioRadius.input),
                            borderSide: BorderSide(color: EvioLightColors.primary, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: EvioSpacing.sm,
                            vertical: EvioSpacing.sm,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: EvioSpacing.md),
                
                // Cantidad
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cantidad *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: EvioLightColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: EvioSpacing.xxs),
                      TextFormField(
                        controller: _tierQuantityController,
                        decoration: InputDecoration(
                          hintText: '100',
                          hintStyle: TextStyle(fontSize: 13, color: EvioLightColors.mutedForeground),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(EvioRadius.input),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(EvioRadius.input),
                            borderSide: BorderSide(color: EvioLightColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(EvioRadius.input),
                            borderSide: BorderSide(color: EvioLightColors.primary, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: EvioSpacing.sm,
                            vertical: EvioSpacing.sm,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: 14),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Inválido';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: EvioSpacing.md),
            
            // Máximo por persona
            Text(
              'Máximo por persona (opcional)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: EvioSpacing.xxs),
            TextFormField(
              controller: _tierMaxPerPurchaseController,
              decoration: InputDecoration(
                hintText: 'Ej: 4',
                hintStyle: TextStyle(fontSize: 13, color: EvioLightColors.mutedForeground),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioLightColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(EvioRadius.input),
                  borderSide: BorderSide(color: EvioLightColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.sm,
                  vertical: EvioSpacing.sm,
                ),
              ),
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14),
              validator: (value) {
                if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                  return 'Número inválido';
                }
                return null;
              },
            ),
            
            SizedBox(height: EvioSpacing.lg),
            
            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelForm,
                  style: TextButton.styleFrom(
                    foregroundColor: EvioLightColors.mutedForeground,
                    padding: EdgeInsets.symmetric(
                      horizontal: EvioSpacing.md,
                      vertical: EvioSpacing.sm,
                    ),
                  ),
                  child: Text('Cancelar'),
                ),
                SizedBox(width: EvioSpacing.sm),
                FilledButton.icon(
                  onPressed: _saveTier,
                  icon: Icon(
                    _editingIndex != null ? Icons.save : Icons.add,
                    size: 18,
                  ),
                  label: Text(_editingIndex != null ? 'Guardar' : 'Crear Tanda'),
                  style: FilledButton.styleFrom(
                    backgroundColor: EvioLightColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: EvioSpacing.lg,
                      vertical: EvioSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(EvioRadius.button),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ❌ ELIMINAR: Método del modal antiguo
  // void _showAddEditDialog(...) { ... }
}

class _TierItem extends StatelessWidget {
  final TicketType ticket;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _TierItem({
    required this.ticket,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(ticket.id),
      margin: EdgeInsets.only(bottom: EvioSpacing.sm),
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: EvioLightColors.border),
        borderRadius: BorderRadius.circular(EvioRadius.button),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drag handle
          ReorderableDragStartListener(
            index: index,
            child: Icon(
              Icons.drag_indicator,
              color: EvioLightColors.mutedForeground,
              size: 20,
            ),
          ),
          
          SizedBox(width: EvioSpacing.sm),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ticket.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: EvioLightColors.textPrimary,
                  ),
                ),
                if (ticket.description != null && ticket.description!.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    ticket.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: EvioLightColors.mutedForeground,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 4),
                Text(
                  'Cant: ${ticket.totalQuantity}${ticket.maxPerPurchase != null ? " • Máx. ${ticket.maxPerPurchase}/persona" : ""}',
                  style: TextStyle(
                    fontSize: 11,
                    color: EvioLightColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: EvioSpacing.md),
          
          // Precio
          Text(
            '\$ ${ticket.price ~/ 100}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: EvioLightColors.textPrimary,
            ),
          ),
          
          SizedBox(width: EvioSpacing.md),
          
          // Toggle "Activa"
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ticket.isActive ? 'Activa' : 'Inactiva',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: ticket.isActive 
                      ? EvioLightColors.primary 
                      : EvioLightColors.mutedForeground,
                ),
              ),
              SizedBox(width: 4),
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: ticket.isActive,
                  onChanged: (_) => onToggleActive(),
                  activeColor: EvioLightColors.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          
          SizedBox(width: EvioSpacing.sm),
          
          // Dropdown menu con acciones
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: EvioLightColors.mutedForeground,
              size: 18,
            ),
            tooltip: '',
            padding: EdgeInsets.zero,
            offset: Offset(0, 40),
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(EvioRadius.xs),
            ),
            color: EvioLightColors.background,
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: EvioLightColors.mutedForeground,
                    ),
                    SizedBox(width: EvioSpacing.xs),
                    Text('Editar', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                height: 40,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: EvioLightColors.destructive,
                    ),
                    SizedBox(width: EvioSpacing.xs),
                    Text(
                      'Eliminar',
                      style: TextStyle(
                        fontSize: 14,
                        color: EvioLightColors.destructive,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
