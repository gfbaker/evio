import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/event_providers.dart';

/// Drawer lateral para crear o editar un tier
class TierDrawer extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final EventFormNotifier notifier;
  final TicketTier? tier; // null = crear, no-null = editar

  const TierDrawer({
    required this.categoryId,
    required this.categoryName,
    required this.notifier,
    this.tier,
    super.key,
  });

  @override
  State<TierDrawer> createState() => _TierDrawerState();
}

class _TierDrawerState extends State<TierDrawer> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _nameError;
  String? _priceError;
  String? _quantityError;
  bool _isDisposed = false;

  // Opciones de activación
  String _activationMode = 'auto'; // 'auto', 'scheduled', 'manual'
  DateTime? _saleStartsAt;
  DateTime? _saleEndsAt;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.tier != null) {
      _loadTierData();
    }
  }

  void _loadTierData() {
    final tier = widget.tier!;
    _nameController.text = tier.name;
    _priceController.text = (tier.price ~/ 100).toString();
    _quantityController.text = tier.quantity.toString();
    _descriptionController.text = tier.description ?? '';
    _isActive = tier.isActive;
    _saleStartsAt = tier.saleStartsAt;
    _saleEndsAt = tier.saleEndsAt;

    // Determinar modo de activación
    if (tier.saleStartsAt != null) {
      _activationMode = 'scheduled';
    } else if (!tier.isActive) {
      _activationMode = 'manual';
    } else {
      _activationMode = 'auto';
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validate() {
    if (_isDisposed) return;

    setState(() {
      _nameError = null;
      _priceError = null;
      _quantityError = null;

      // Validar nombre
      if (_nameController.text.trim().isEmpty) {
        _nameError = 'El nombre es obligatorio';
      }

      // Validar precio
      if (_priceController.text.isEmpty) {
        _priceError = 'El precio es obligatorio';
      } else {
        final price = int.tryParse(_priceController.text);
        if (price == null) {
          _priceError = 'Debe ser un número válido';
        } else if (price <= 0) {
          _priceError = 'Debe ser mayor a 0';
        } else if (price > 10000000) { // 100k ARS
          _priceError = 'Precio demasiado alto (máx: 10.000.000)';
        }
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
        } else if (qty > 100000) {
          _quantityError = 'Cantidad demasiado alta (máx: 100.000)';
        }
      }

      // Validar fechas si está en modo scheduled
      if (_activationMode == 'scheduled') {
        if (_saleStartsAt == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Debes seleccionar fecha de inicio de venta'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        if (_saleEndsAt != null &&
            _saleEndsAt!.isBefore(_saleStartsAt!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('La fecha de fin debe ser posterior a la de inicio'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    });

    // Si no hay errores, guardar
    if (_nameError == null && _priceError == null && _quantityError == null) {
      _saveTier();
    }
  }

  void _saveTier() {
    final price = int.parse(_priceController.text) * 100; // Convertir a centavos
    final quantity = int.parse(_quantityController.text);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();

    // Determinar valores según modo de activación
    final isActive = _activationMode == 'manual' ? _isActive : true;
    final saleStartsAt = _activationMode == 'scheduled' ? _saleStartsAt : null;
    final saleEndsAt = _activationMode == 'scheduled' ? _saleEndsAt : null;

    if (widget.tier == null) {
      // Crear nuevo tier
      widget.notifier.addTier(
        widget.categoryId,
        name: name,
        price: price,
        quantity: quantity,
        description: description,
      );

      // Si es scheduled o manual, actualizar después
      if (_activationMode != 'auto') {
        // Obtener el tier recién creado (el último de la lista)
        final state = widget.notifier.state;
        final category = state.ticketCategories
            .firstWhere((cat) => cat.id == widget.categoryId);
        if (category.tiers.isNotEmpty) {
          final newTier = category.tiers.last;
          final updatedTier = newTier.copyWith(
            isActive: isActive,
            saleStartsAt: saleStartsAt,
            saleEndsAt: saleEndsAt,
          );
          widget.notifier.updateTier(
            widget.categoryId,
            newTier.id,
            updatedTier,
          );
        }
      }
    } else {
      // Editar tier existente
      final updatedTier = widget.tier!.copyWith(
        name: name,
        description: description,
        price: price,
        quantity: quantity,
        isActive: isActive,
        saleStartsAt: saleStartsAt,
        saleEndsAt: saleEndsAt,
      );
      widget.notifier.updateTier(
        widget.categoryId,
        widget.tier!.id,
        updatedTier,
      );
    }

    if (!_isDisposed && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.tier != null;

    return Drawer(
      width: 500,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(EvioSpacing.lg),
              decoration: BoxDecoration(
                color: EvioLightColors.background,
                border: Border(
                  bottom: BorderSide(color: EvioLightColors.border),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                  SizedBox(width: EvioSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'Editar Tier' : 'Nuevo Tier',
                          style: EvioTypography.h3,
                        ),
                        SizedBox(height: EvioSpacing.xxs),
                        Text(
                          'Categoría: ${widget.categoryName}',
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
                    // Nombre
                    Text(
                      'Nombre del Tier *',
                      style: EvioTypography.labelMedium,
                    ),
                    SizedBox(height: EvioSpacing.xs),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Early Bird, Pre-venta 1, General',
                        errorText: _nameError,
                        filled: true,
                        fillColor: EvioLightColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(EvioRadius.input),
                          borderSide: BorderSide(
                            color: _nameError != null
                                ? Colors.red
                                : EvioLightColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(EvioRadius.input),
                          borderSide: BorderSide(
                            color: _nameError != null
                                ? Colors.red
                                : EvioLightColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(EvioRadius.input),
                          borderSide: BorderSide(
                            color: _nameError != null
                                ? Colors.red
                                : EvioLightColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(EvioSpacing.md),
                      ),
                      autofocus: !isEditing,
                      onChanged: (_) {
                        if (_nameError != null && !_isDisposed) {
                          setState(() => _nameError = null);
                        }
                      },
                    ),
                    SizedBox(height: EvioSpacing.lg),

                    // Precio y Cantidad en row
                    Row(
                      children: [
                        // Precio
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Precio (ARS) *',
                                style: EvioTypography.labelMedium,
                              ),
                              SizedBox(height: EvioSpacing.xs),
                              TextField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  hintText: '3000',
                                  prefixText: '\$ ',
                                  errorText: _priceError,
                                  filled: true,
                                  fillColor: EvioLightColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(EvioRadius.input),
                                    borderSide: BorderSide(
                                      color: _priceError != null
                                          ? Colors.red
                                          : EvioLightColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(EvioRadius.input),
                                    borderSide: BorderSide(
                                      color: _priceError != null
                                          ? Colors.red
                                          : EvioLightColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(EvioRadius.input),
                                    borderSide: BorderSide(
                                      color: _priceError != null
                                          ? Colors.red
                                          : EvioLightColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.all(EvioSpacing.md),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) {
                                  if (_priceError != null && !_isDisposed) {
                                    setState(() => _priceError = null);
                                  }
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
                                style: EvioTypography.labelMedium,
                              ),
                              SizedBox(height: EvioSpacing.xs),
                              TextField(
                                controller: _quantityController,
                                decoration: InputDecoration(
                                  hintText: '100',
                                  errorText: _quantityError,
                                  filled: true,
                                  fillColor: EvioLightColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(EvioRadius.input),
                                    borderSide: BorderSide(
                                      color: _quantityError != null
                                          ? Colors.red
                                          : EvioLightColors.border,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(EvioRadius.input),
                                    borderSide: BorderSide(
                                      color: _quantityError != null
                                          ? Colors.red
                                          : EvioLightColors.border,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(EvioRadius.input),
                                    borderSide: BorderSide(
                                      color: _quantityError != null
                                          ? Colors.red
                                          : EvioLightColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.all(EvioSpacing.md),
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) {
                                  if (_quantityError != null && !_isDisposed) {
                                    setState(() => _quantityError = null);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: EvioSpacing.lg),

                    // Descripción
                    Text(
                      'Descripción',
                      style: EvioTypography.labelMedium,
                    ),
                    SizedBox(height: EvioSpacing.xs),
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Ej: Acceso prioritario + descuento en bar',
                        filled: true,
                        fillColor: EvioLightColors.background,
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
                          borderSide: BorderSide(
                            color: EvioLightColors.primary,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.all(EvioSpacing.md),
                      ),
                      minLines: 2,
                      maxLines: 4,
                      keyboardType: TextInputType.multiline,
                    ),
                    SizedBox(height: EvioSpacing.xl),

                    // Activación
                    _buildActivationSection(),
                  ],
                ),
              ),
            ),

            // Footer actions
            Container(
              padding: EdgeInsets.all(EvioSpacing.lg),
              decoration: BoxDecoration(
                color: EvioLightColors.background,
                border: Border(
                  top: BorderSide(color: EvioLightColors.border),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EvioLightColors.mutedForeground,
                        side: BorderSide(color: EvioLightColors.border),
                        padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
                      ),
                      child: Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: EvioSpacing.md),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _validate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EvioLightColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
                      ),
                      child: Text(isEditing ? 'Guardar Cambios' : 'Crear Tier'),
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

  Widget _buildActivationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Modo de Activación',
          style: EvioTypography.h4,
        ),
        SizedBox(height: EvioSpacing.xs),
        Text(
          'Define cuándo estará disponible este tier para la venta',
          style: EvioTypography.bodySmall.copyWith(
            color: EvioLightColors.mutedForeground,
          ),
        ),
        SizedBox(height: EvioSpacing.md),

        // Opciones de activación (se expanden inline)
        _buildActivationOption(
          value: 'auto',
          title: 'Secuencial Automático',
          description:
              'Se activa automáticamente cuando el tier anterior se agote',
          icon: Icons.auto_awesome,
        ),
        SizedBox(height: EvioSpacing.sm),
        _buildActivationOption(
          value: 'scheduled',
          title: 'Fechas Programadas',
          description: 'Se activa en una fecha específica',
          icon: Icons.schedule,
        ),
        SizedBox(height: EvioSpacing.sm),
        _buildActivationOption(
          value: 'manual',
          title: 'Control Manual',
          description: 'Activas/pausas este tier manualmente',
          icon: Icons.touch_app,
        ),
      ],
    );
  }

  Widget _buildActivationOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _activationMode == value;

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (!_isDisposed) {
              setState(() => _activationMode = value);
            }
          },
          borderRadius: BorderRadius.circular(EvioRadius.card),
          child: Container(
            padding: EdgeInsets.all(EvioSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? EvioLightColors.primary.withOpacity(0.1)
                  : EvioLightColors.background,
              borderRadius: BorderRadius.circular(EvioRadius.card),
              border: Border.all(
                color: isSelected
                    ? EvioLightColors.primary
                    : EvioLightColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? EvioLightColors.primary
                      : EvioLightColors.mutedForeground,
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: EvioTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? EvioLightColors.primary
                              : EvioLightColors.foreground,
                        ),
                      ),
                      SizedBox(height: EvioSpacing.xxs),
                      Text(
                        description,
                        style: EvioTypography.bodySmall.copyWith(
                          color: EvioLightColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: EvioLightColors.primary,
                  ),
              ],
            ),
          ),
        ),

        // ✅ Expandir opciones dentro de la card si está seleccionado
        if (isSelected) ...[
          SizedBox(height: EvioSpacing.sm),
          Container(
            padding: EdgeInsets.all(EvioSpacing.lg),
            decoration: BoxDecoration(
              color: EvioLightColors.background,
              borderRadius: BorderRadius.circular(EvioRadius.card),
              border: Border.all(color: EvioLightColors.border),
            ),
            child: _buildModeOptions(value),
          ),
        ],
      ],
    );
  }

  Widget _buildModeOptions(String mode) {
    switch (mode) {
      case 'scheduled':
        return _buildScheduledOptionsInline();
      case 'manual':
        return _buildManualOptionsInline();
      default:
        return Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 20,
              color: EvioLightColors.mutedForeground,
            ),
            SizedBox(width: EvioSpacing.sm),
            Expanded(
              child: Text(
                'Este tier se activará cuando el anterior se agote',
                style: EvioTypography.bodySmall.copyWith(
                  color: EvioLightColors.mutedForeground,
                ),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildScheduledOptionsInline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Configurar fechas de venta',
          style: EvioTypography.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: EvioSpacing.md),

        // Fecha de inicio
        Text(
          'Fecha de inicio *',
          style: EvioTypography.labelSmall.copyWith(
            color: EvioLightColors.mutedForeground,
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        InkWell(
          onTap: () => _pickDate(isStart: true),
          borderRadius: BorderRadius.circular(EvioRadius.input),
          child: Container(
            padding: EdgeInsets.all(EvioSpacing.md),
            decoration: BoxDecoration(
              color: EvioLightColors.card,
              borderRadius: BorderRadius.circular(EvioRadius.input),
              border: Border.all(color: EvioLightColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: EvioLightColors.primary,
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: Text(
                    _saleStartsAt == null
                        ? 'Seleccionar fecha'
                        : _formatDate(_saleStartsAt!),
                    style: EvioTypography.bodyMedium.copyWith(
                      color: _saleStartsAt == null
                          ? EvioLightColors.mutedForeground
                          : EvioLightColors.foreground,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: EvioLightColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: EvioSpacing.md),

        // Fecha de fin (opcional)
        Text(
          'Fecha de fin (opcional)',
          style: EvioTypography.labelSmall.copyWith(
            color: EvioLightColors.mutedForeground,
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        InkWell(
          onTap: () => _pickDate(isStart: false),
          borderRadius: BorderRadius.circular(EvioRadius.input),
          child: Container(
            padding: EdgeInsets.all(EvioSpacing.md),
            decoration: BoxDecoration(
              color: EvioLightColors.card,
              borderRadius: BorderRadius.circular(EvioRadius.input),
              border: Border.all(color: EvioLightColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 20,
                  color: EvioLightColors.mutedForeground,
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: Text(
                    _saleEndsAt == null
                        ? 'Sin fecha de fin'
                        : _formatDate(_saleEndsAt!),
                    style: EvioTypography.bodyMedium.copyWith(
                      color: _saleEndsAt == null
                          ? EvioLightColors.mutedForeground
                          : EvioLightColors.foreground,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: EvioLightColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManualOptionsInline() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado inicial del tier',
                style: EvioTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: EvioSpacing.xxs),
              Text(
                _isActive
                    ? 'El tier estará activo desde el inicio'
                    : 'El tier comenzará pausado',
                style: EvioTypography.bodySmall.copyWith(
                  color: EvioLightColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: EvioSpacing.md),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.sm,
            vertical: EvioSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: _isActive
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(EvioRadius.button),
          ),
          child: Row(
            children: [
              Icon(
                _isActive ? Icons.check_circle : Icons.pause_circle,
                size: 16,
                color: _isActive ? Colors.green : Colors.orange,
              ),
              SizedBox(width: EvioSpacing.xs),
              Text(
                _isActive ? 'Activo' : 'Pausado',
                style: EvioTypography.labelSmall.copyWith(
                  color: _isActive ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: EvioSpacing.sm),
        Switch(
          value: _isActive,
          onChanged: (value) {
            if (!_isDisposed) {
              setState(() => _isActive = value);
            }
          },
          activeColor: EvioLightColors.primary,
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    // ✅ Check disposed ANTES de async operation
    if (_isDisposed || !mounted) return;

    final now = DateTime.now();
    final initialDate = isStart
        ? (_saleStartsAt ?? now)
        : (_saleEndsAt ?? _saleStartsAt ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(Duration(days: 365)),
    );

    // ✅ Check disposed Y mounted DESPUÉS de async operation
    if (_isDisposed || !mounted) return;

    if (picked != null) {
      setState(() {
        if (isStart) {
          _saleStartsAt = picked;
        } else {
          _saleEndsAt = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
