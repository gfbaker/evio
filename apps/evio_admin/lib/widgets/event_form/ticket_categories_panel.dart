import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/event_providers.dart';
import '../../widgets/events/tier_status_badge.dart';
import 'tier_drawer.dart';

/// Panel principal para gestionar categorías y tiers de tickets
class TicketCategoriesPanel extends ConsumerWidget {
  final String? eventId;

  const TicketCategoriesPanel({this.eventId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = eventFormNotifierProvider(eventId);
    final notifier = ref.read(provider.notifier);
    final state = ref.watch(provider).state;
    final categories = state.ticketCategories;

    return Container(
      decoration: BoxDecoration(
        color: EvioLightColors.card,
        borderRadius: BorderRadius.circular(EvioRadius.card),
        border: Border.all(color: EvioLightColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(EvioSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categorías de Tickets',
                      style: EvioTypography.h3,
                    ),
                    SizedBox(height: EvioSpacing.xxs),
                    Text(
                      'Configura las categorías y sus precios escalonados',
                      style: EvioTypography.bodySmall.copyWith(
                        color: EvioLightColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: EvioLightColors.border),

          // Categories List or Empty State
          if (categories.isEmpty)
            _buildEmptyState(context, notifier)
          else ...[
            _buildCategoriesList(context, ref, categories),
            
            // Add Category Button (solo cuando hay categorías)
            Padding(
              padding: EdgeInsets.all(EvioSpacing.lg),
              child: OutlinedButton.icon(
                onPressed: () => _showAddCategoryDialog(context, notifier),
                icon: Icon(Icons.add, size: 20),
                label: Text('Agregar categoría'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EvioLightColors.primary,
                  side: BorderSide(color: EvioLightColors.border),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, EventFormNotifier notifier) {
    return Padding(
      padding: EdgeInsets.all(EvioSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.confirmation_number_outlined,
              size: 64,
              color: EvioLightColors.mutedForeground,
            ),
            SizedBox(height: EvioSpacing.md),
            Text(
              'No hay categorías de tickets',
              style: EvioTypography.h4,
            ),
            SizedBox(height: EvioSpacing.xs),
            Text(
              'Crea categorías como General, VIP, etc.',
              style: EvioTypography.bodySmall.copyWith(
                color: EvioLightColors.mutedForeground,
              ),
            ),
            SizedBox(height: EvioSpacing.lg),
            ElevatedButton.icon(
              onPressed: () => _showAddCategoryDialog(context, notifier),
              icon: Icon(Icons.add),
              label: Text('Crear primera categoría'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EvioLightColors.primary,
                foregroundColor: Colors.white,  // ✅ Texto blanco para contraste
                padding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.xl,
                  vertical: EvioSpacing.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList(
    BuildContext context,
    WidgetRef ref,
    List<TicketCategory> categories,
  ) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(eventFormNotifierProvider(eventId).notifier)
            .reorderCategories(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryAccordionItem(
          key: ValueKey(category.id),
          category: category,
          index: index,
          eventId: eventId,
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, EventFormNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => _AddCategoryDialog(notifier: notifier),
    );
  }
}

/// Dialog para agregar categoría (con validación inline)
class _AddCategoryDialog extends StatefulWidget {
  final EventFormNotifier notifier;

  const _AddCategoryDialog({required this.notifier});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxPerPurchaseController = TextEditingController();
  
  String? _nameError;
  String? _maxPerPurchaseError;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _descriptionController.dispose();
    _maxPerPurchaseController.dispose();
    super.dispose();
  }

  void _validate() {
    if (_isDisposed) return;
    
    setState(() {
      _nameError = null;
      _maxPerPurchaseError = null;

      if (_nameController.text.trim().isEmpty) {
        _nameError = 'El nombre es obligatorio';
      }

      if (_maxPerPurchaseController.text.isNotEmpty) {
        final value = int.tryParse(_maxPerPurchaseController.text);
        if (value == null) {
          _maxPerPurchaseError = 'Debe ser un número válido';
        } else if (value <= 0) {
          _maxPerPurchaseError = 'Debe ser mayor a 0';
        }
      }
    });

    // Si no hay errores, crear la categoría
    if (_nameError == null && _maxPerPurchaseError == null) {
      widget.notifier.addCategory(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        maxPerPurchase: _maxPerPurchaseController.text.isEmpty
            ? null
            : int.parse(_maxPerPurchaseController.text),
      );
      if (!_isDisposed && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 500,
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(EvioSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nueva Categoría', style: EvioTypography.h3),
              SizedBox(height: EvioSpacing.lg),
              
              // Nombre
              Text(
                'Nombre *',
                style: EvioTypography.labelMedium.copyWith(
                  color: EvioLightColors.foreground,
                ),
              ),
              SizedBox(height: EvioSpacing.xs),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ej: General, VIP, Estacionamiento',
                  hintStyle: TextStyle(
                    color: EvioLightColors.mutedForeground,
                  ),
                  errorText: _nameError,
                  filled: true,
                  fillColor: EvioLightColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.input),
                    borderSide: BorderSide(
                      color: _nameError != null ? Colors.red : EvioLightColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.input),
                    borderSide: BorderSide(
                      color: _nameError != null ? Colors.red : EvioLightColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.input),
                    borderSide: BorderSide(
                      color: _nameError != null ? Colors.red : EvioLightColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: EvioSpacing.md,
                    vertical: EvioSpacing.sm,
                  ),
                ),
                autofocus: true,
                onChanged: (_) {
                  if (_nameError != null && !_isDisposed) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              SizedBox(height: EvioSpacing.lg),
              
              // Descripción
              Text(
                'Descripción',
                style: EvioTypography.labelMedium.copyWith(
                  color: EvioLightColors.foreground,
                ),
              ),
              SizedBox(height: EvioSpacing.xxs),
              Text(
                'Escribe una descripción detallada del evento',
                style: EvioTypography.caption.copyWith(
                  color: EvioLightColors.mutedForeground,
                ),
              ),
              SizedBox(height: EvioSpacing.xs),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  hintText: 'Ej: Vuelve la reina del Psy-trance y vos no te lo podés perder...',
                  hintStyle: TextStyle(
                    color: EvioLightColors.mutedForeground,
                  ),
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
                minLines: 3,
                maxLines: 10,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: EvioSpacing.lg),
              
              // Máximo por persona
              Text(
                'Máximo por persona',
                style: EvioTypography.labelMedium.copyWith(
                  color: EvioLightColors.foreground,
                ),
              ),
              SizedBox(height: EvioSpacing.xs),
              TextField(
                controller: _maxPerPurchaseController,
                decoration: InputDecoration(
                  hintText: 'Ej: 4',
                  hintStyle: TextStyle(
                    color: EvioLightColors.mutedForeground,
                  ),
                  errorText: _maxPerPurchaseError,
                  filled: true,
                  fillColor: EvioLightColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.input),
                    borderSide: BorderSide(
                      color: _maxPerPurchaseError != null ? Colors.red : EvioLightColors.border,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.input),
                    borderSide: BorderSide(
                      color: _maxPerPurchaseError != null ? Colors.red : EvioLightColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(EvioRadius.input),
                    borderSide: BorderSide(
                      color: _maxPerPurchaseError != null ? Colors.red : EvioLightColors.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: EvioSpacing.md,
                    vertical: EvioSpacing.sm,
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (_) {
                  if (_maxPerPurchaseError != null && !_isDisposed) {
                    setState(() => _maxPerPurchaseError = null);
                  }
                },
              ),
              SizedBox(height: EvioSpacing.xl),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: EvioLightColors.mutedForeground,
                    ),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: EvioSpacing.sm),
                  ElevatedButton(
                    onPressed: _validate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EvioLightColors.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: EvioSpacing.lg,
                        vertical: EvioSpacing.sm,
                      ),
                    ),
                    child: Text('Crear'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item individual de categoría (expandible)
class CategoryAccordionItem extends ConsumerStatefulWidget {
  final TicketCategory category;
  final int index;
  final String? eventId;

  const CategoryAccordionItem({
    required this.category,
    required this.index,
    required this.eventId,
    super.key,
  });

  @override
  ConsumerState<CategoryAccordionItem> createState() =>
      _CategoryAccordionItemState();
}

class _CategoryAccordionItemState extends ConsumerState<CategoryAccordionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: EvioSpacing.lg,
        vertical: EvioSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: EvioLightColors.border),
        borderRadius: BorderRadius.circular(EvioRadius.card),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(EvioRadius.card),
            child: Padding(
              padding: EdgeInsets.all(EvioSpacing.md),
              child: Row(
                children: [
                  // Drag handle
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: Icon(
                      Icons.drag_indicator,
                      color: EvioLightColors.mutedForeground,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: EvioSpacing.sm),

                  // Expand icon
                  Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: EvioLightColors.mutedForeground,
                  ),
                  SizedBox(width: EvioSpacing.sm),

                  // Category info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.name,
                          style: EvioTypography.h4,
                        ),
                        if (widget.category.tiers.isNotEmpty) ...[
                          SizedBox(height: EvioSpacing.xxs),
                          Text(
                            '${widget.category.tiers.length} tier(s) configurado(s)',
                            style: EvioTypography.bodySmall.copyWith(
                              color: EvioLightColors.mutedForeground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, size: 20),
                    padding: EdgeInsets.all(EvioSpacing.xs),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          // TODO: Implementar edición de categoría
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Edición próximamente')),
                          );
                          break;
                        case 'duplicate':
                          // TODO: Implementar duplicación
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Duplicación próximamente')),
                          );
                          break;
                        case 'delete':
                          _confirmDelete(context);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: EvioLightColors.foreground),
                            SizedBox(width: EvioSpacing.sm),
                            Text('Editar categoría'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.content_copy, size: 18, color: EvioLightColors.foreground),
                            SizedBox(width: EvioSpacing.sm),
                            Text('Duplicar categoría'),
                          ],
                        ),
                      ),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: EvioSpacing.sm),
                            Text(
                              'Eliminar categoría',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded content (tiers)
          if (_isExpanded) ...[
            Divider(height: 1, color: EvioLightColors.border),
            _buildTiersList(),
            _buildAddTierButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildTiersList() {
    if (widget.category.tiers.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(EvioSpacing.lg),
        child: Center(
          child: Text(
            'No hay tiers configurados',
            style: EvioTypography.bodySmall.copyWith(
              color: EvioLightColors.mutedForeground,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(EvioSpacing.md),
      itemCount: widget.category.tiers.length,
      separatorBuilder: (_, __) => SizedBox(height: EvioSpacing.sm),
      itemBuilder: (context, index) {
        final tier = widget.category.tiers[index];
        return _buildTierItem(tier, index);
      },
    );
  }

  Widget _buildTierItem(TicketTier tier, int index) {
    return Container(
      padding: EdgeInsets.all(EvioSpacing.md),
      decoration: BoxDecoration(
        color: EvioLightColors.background,
        borderRadius: BorderRadius.circular(EvioRadius.button),
        border: Border.all(color: EvioLightColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tier name + actions
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: EvioSpacing.sm,
                  vertical: EvioSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: EvioLightColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(EvioRadius.button),
                ),
                child: Text(
                  'Tier ${index + 1}',
                  style: EvioTypography.labelSmall.copyWith(
                    color: EvioLightColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: EvioSpacing.sm),
              Expanded(
                child: Text(
                  tier.name,
                  style: EvioTypography.h4,
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _showEditTierDrawer(context, tier),
                padding: EdgeInsets.all(EvioSpacing.xs),
                constraints: BoxConstraints(),
                tooltip: 'Editar tier',
              ),
              SizedBox(width: EvioSpacing.xs),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18),
                onPressed: () => _confirmDeleteTier(context, tier),
                padding: EdgeInsets.all(EvioSpacing.xs),
                constraints: BoxConstraints(),
                color: Colors.red,
                tooltip: 'Eliminar tier',
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.md),

          // Price & Quantity
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precio',
                      style: EvioTypography.labelSmall.copyWith(
                        color: EvioLightColors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: EvioSpacing.xxs),
                    Text(
                      '\$ ${tier.price ~/ 100}',
                      style: EvioTypography.bodyLarge.copyWith(
                        color: EvioLightColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: EvioLightColors.border,
              ),
              SizedBox(width: EvioSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cantidad',
                      style: EvioTypography.labelSmall.copyWith(
                        color: EvioLightColors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: EvioSpacing.xxs),
                    Text(
                      '${tier.quantity} unidades',
                      style: EvioTypography.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: EvioSpacing.md),

          // Status
          _buildTierStatus(tier, index),
        ],
      ),
    );
  }

  Widget _buildTierStatus(TicketTier tier, int tierIndex) {
    // Obtener tier anterior para detectar estado "en espera"
    final previousTier = tierIndex > 0 ? widget.category.tiers[tierIndex - 1] : null;
    
    // Usar la misma lógica que en detail
    final status = TierStatusInfo.fromTier(tier, previousTier: previousTier);

    return Row(
      children: [
        Icon(status.icon, size: 14, color: status.badgeColor),
        SizedBox(width: EvioSpacing.xxs),
        Flexible(
          child: Text(
            status.label,
            style: EvioTypography.caption.copyWith(color: status.badgeColor),
          ),
        ),
      ],
    );
  }

  Widget _buildAddTierButton() {
    return Padding(
      padding: EdgeInsets.all(EvioSpacing.md),
      child: OutlinedButton.icon(
        onPressed: () => _showAddTierDialog(context),
        icon: Icon(Icons.add, size: 18),
        label: Text('Agregar tier a ${widget.category.name}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: EvioLightColors.primary,
          side: BorderSide(color: EvioLightColors.border),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar categoría'),
        content: Text(
          '¿Estás seguro que deseas eliminar "${widget.category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(eventFormNotifierProvider(widget.eventId).notifier)
                  .removeCategory(widget.category.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddTierDialog(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TierDrawer(
          categoryId: widget.category.id,
          categoryName: widget.category.name,
          notifier: ref.read(eventFormNotifierProvider(widget.eventId).notifier),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _showEditTierDrawer(BuildContext context, TicketTier tier) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TierDrawer(
          categoryId: widget.category.id,
          categoryName: widget.category.name,
          notifier: ref.read(eventFormNotifierProvider(widget.eventId).notifier),
          tier: tier, // Pasar el tier para editar
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  void _confirmDeleteTier(BuildContext context, TicketTier tier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar tier'),
        content: Text('¿Estás seguro que deseas eliminar "${tier.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(eventFormNotifierProvider(widget.eventId).notifier)
                  .removeTier(widget.category.id, tier.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
