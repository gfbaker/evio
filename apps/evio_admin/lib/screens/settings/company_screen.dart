import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/settings_provider.dart';

class CompanyScreen extends ConsumerStatefulWidget {
  const CompanyScreen({super.key});

  @override
  ConsumerState<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends ConsumerState<CompanyScreen> {
  bool _isDisposed = false;
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _loadProducerData(Producer producer) {
    if (_isDisposed) return;
    _nameController.text = producer.name;
    _emailController.text = producer.email ?? '';
    _websiteController.text = producer.description ?? '';
  }

  Future<void> _saveChanges() async {
    if (_isDisposed || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final producerAsync = ref.read(currentProducerProvider);
      final producer = producerAsync.value;

      if (producer == null || _isDisposed) return;

      final repo = ref.read(producerRepositoryProvider);
      final updatedProducer = Producer(
        id: producer.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        description: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        logoUrl: producer.logoUrl,
        createdAt: producer.createdAt,
      );

      await repo.updateProducer(updatedProducer);

      if (_isDisposed || !mounted) return;

      ref.invalidate(currentProducerProvider);

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Productora actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _toggleEdit() {
    if (_isDisposed) return;
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        final producer = ref.read(currentProducerProvider).value;
        if (producer != null) _loadProducerData(producer);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final producerAsync = ref.watch(currentProducerProvider);

    return producerAsync.when(
      data: (producer) {
        if (producer == null) {
          return const Center(
            child: Text('No se encontró información de la productora'),
          );
        }

        if (_nameController.text.isEmpty && !_isEditing) {
          _loadProducerData(producer);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos de la Productora Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: EvioLightColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Datos de la Productora',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isEditing)
                          Row(
                            children: [
                              TextButton(
                                onPressed: _isSaving ? null : _toggleEdit,
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isSaving ? null : _saveChanges,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: EvioLightColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Guardar'),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: _toggleEdit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: const Text('Editar Información'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Logo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: EvioLightColors.muted,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: EvioLightColors.border,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.business,
                                size: 50,
                                color: EvioLightColors.mutedForeground,
                              ),
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: EvioLightColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Upload de logo pendiente',
                                          ),
                                        ),
                                      );
                                    },
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Logo de la productora',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EvioLightColors.mutedForeground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                producer.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Form Fields
                    _buildTextField(
                      label: 'Nombre Comercial',
                      controller: _nameController,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      enabled: _isEditing,
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: 'Instagram o Sitio Web',
                      controller: _websiteController,
                      enabled: _isEditing,
                      icon: Icons.language,
                      hint: '@productora o www.productora.com',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    IconData? icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: EvioLightColors.mutedForeground),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: EvioLightColors.foreground,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: EvioLightColors.mutedForeground),
            filled: true,
            fillColor: enabled
                ? EvioLightColors.inputBackground
                : EvioLightColors.muted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: EvioLightColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: EvioLightColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: EvioLightColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
