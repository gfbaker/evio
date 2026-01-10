import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import 'label_input.dart';
import 'floating_snackbar.dart';

class ProducerOnboardingDialog extends ConsumerStatefulWidget {
  const ProducerOnboardingDialog({super.key});

  @override
  ConsumerState<ProducerOnboardingDialog> createState() =>
      _ProducerOnboardingDialogState();
}

class _ProducerOnboardingDialogState
    extends ConsumerState<ProducerOnboardingDialog> {
  bool _isDisposed = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _logoBytes;

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    if (_isDisposed) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
      ).timeout(Duration(seconds: 30));

      if (image == null) return;

      final bytes = await image.readAsBytes().timeout(Duration(seconds: 10));

      if (_isDisposed || !mounted) return;
      setState(() => _logoBytes = bytes);
    } on TimeoutException {
      if (_isDisposed || !mounted) return;
      FloatingSnackBar.show(
        context,
        message: 'Timeout: la imagen tardó demasiado en cargarse',
        type: SnackBarType.error,
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;
      FloatingSnackBar.show(
        context,
        message: 'Error al cargar imagen: $e',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _createProducer() async {
    if (_isDisposed) return;

    if (!_formKey.currentState!.validate()) return;

    if (_isDisposed || !mounted) return;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(onboardingControllerProvider)
          .createProducerAndLinkUser(
            name: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            logoBytes: _logoBytes,
          )
          .timeout(Duration(seconds: 15));

      if (_isDisposed || !mounted) return;

      // Refresh user data
      ref.invalidate(currentUserProvider);

      Navigator.of(context).pop();
    } on TimeoutException {
      if (_isDisposed || !mounted) return;

      FloatingSnackBar.show(
        context,
        message: 'Timeout: verifica tu conexión',
        type: SnackBarType.error,
      );
    } catch (e) {
      if (_isDisposed || !mounted) return;

      FloatingSnackBar.show(
        context,
        message: e.toString(),
        type: SnackBarType.error,
      );
    } finally {
      if (_isDisposed || !mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: EvioLightColors.card,
          borderRadius: BorderRadius.circular(EvioRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(EvioSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  '🎉 ¡Bienvenido!',
                  style: EvioTypography.h1.copyWith(
                    color: EvioLightColors.foreground,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: EvioSpacing.sm),
                Text(
                  'Creá tu productora para empezar a organizar eventos',
                  style: EvioTypography.bodyLarge.copyWith(
                    color: EvioLightColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: EvioSpacing.xxl),

                // Logo picker
                Center(
                  child: GestureDetector(
                    onTap: _pickLogo,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: EvioLightColors.inputBackground,
                        borderRadius: BorderRadius.circular(EvioRadius.card),
                        border: Border.all(
                          color: EvioLightColors.border,
                          width: 2,
                        ),
                      ),
                      child: _logoBytes != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(EvioRadius.card - 2),
                              child: Image.memory(
                                _logoBytes!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 40,
                                  color: EvioLightColors.mutedForeground,
                                ),
                                SizedBox(height: EvioSpacing.xs),
                                Text(
                                  'Logo',
                                  style: EvioTypography.caption.copyWith(
                                    color: EvioLightColors.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                SizedBox(height: EvioSpacing.lg),

                // Nombre
                LabelInput(
                  label: 'Nombre de la productora *',
                  controller: _nameController,
                  hint: 'Ej: Evio Events',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                SizedBox(height: EvioSpacing.lg),

                // Email
                LabelInput(
                  label: 'Email de contacto (opcional)',
                  controller: _emailController,
                  hint: 'contacto@productora.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Email inválido';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: EvioSpacing.xxl),

                // Botón crear
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createProducer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EvioLightColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Crear Productora',
                            style: EvioTypography.button,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
