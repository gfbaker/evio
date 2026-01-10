import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/common/label_input.dart';
import '../../widgets/common/floating_snackbar.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isDisposed = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProducer() async {
    if (_isDisposed) return;
    
    if (!_formKey.currentState!.validate()) return;

    if (_isDisposed || !mounted) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(onboardingControllerProvider).createProducerAndLinkUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        logoBytes: null,
      ).timeout(Duration(seconds: 15));

      if (_isDisposed || !mounted) return;

      // Refresh auth state
      ref.invalidate(currentUserProvider);

      context.go('/admin/dashboard');
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
    return Scaffold(
      backgroundColor: EvioLightColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(EvioSpacing.xxl),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo/evio-logo.png',
                    height: 48,
                  ),
                  SizedBox(height: EvioSpacing.xl),

                  // Título
                  Text(
                    'Bienvenido a Evio Admin',
                    style: EvioTypography.h1.copyWith(
                    color: EvioLightColors.foreground,
                    ),
                    textAlign: TextAlign.center,
                    ),
                    SizedBox(height: EvioSpacing.sm),
                    Text(
                    'Creá tu productora para empezar',
                    style: EvioTypography.bodyLarge.copyWith(
                    color: EvioLightColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: EvioSpacing.xxl),

                  // Card contenedor
                  Container(
                    padding: EdgeInsets.all(EvioSpacing.xl),
                    decoration: BoxDecoration(
                      color: EvioLightColors.card,
                      borderRadius: BorderRadius.circular(EvioRadius.card),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Nombre de la productora (obligatorio)
                        LabelInput(
                          label: 'Nombre de la productora',
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

                        // Email (opcional)
                        LabelInput(
                          label: 'Email de contacto',
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
                        SizedBox(height: EvioSpacing.lg),

                        // Descripción (opcional)
                        LabelInput(
                          label: 'Descripción',
                          controller: _descriptionController,
                          hint: 'Contanos sobre tu productora...',
                          maxLines: 3,
                        ),
                        SizedBox(height: EvioSpacing.xxl),

                        // Botón crear
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _createProducer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: EvioLightColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.button,
                                ),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
