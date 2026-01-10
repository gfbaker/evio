import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common/floating_snackbar.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authController = ref.read(authControllerProvider);
      await authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        role: UserRole.admin,
      );

      if (!mounted) return;

      FloatingSnackBar.show(
        context,
        message: 'Cuenta creada exitosamente',
        type: SnackBarType.success,
      );

      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      
      // Mapear errores técnicos a mensajes user-friendly
      String errorMessage;
      final errorStr = e.toString().toLowerCase();
      
      if (errorStr.contains('user already registered') || 
          errorStr.contains('email already exists') ||
          errorStr.contains('duplicate') ||
          errorStr.contains('already in use')) {
        errorMessage = 'Este email ya está registrado. ¿Querés iniciar sesión?';
      } else if (errorStr.contains('invalid email')) {
        errorMessage = 'Email inválido. Verificá el formato.';
      } else if (errorStr.contains('weak password') || errorStr.contains('password')) {
        errorMessage = 'La contraseña debe tener al menos 6 caracteres.';
      } else if (errorStr.contains('network') || errorStr.contains('timeout')) {
        errorMessage = 'Error de conexión. Verificá tu internet.';
      } else {
        errorMessage = 'Error al crear la cuenta. Intentá de nuevo.';
      }
      
      FloatingSnackBar.show(
        context,
        message: errorMessage,
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvioLightColors.muted,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(EvioSpacing.lg),
          child: Container(
            constraints: BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(EvioRadius.card),
                side: BorderSide(color: EvioLightColors.border),
              ),
              color: EvioLightColors.card,
              child: Padding(
                padding: EdgeInsets.all(EvioSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, size: 20),
                        onPressed: () => context.go('/login'),
                        style: IconButton.styleFrom(
                          backgroundColor: EvioLightColors.muted,
                          padding: EdgeInsets.all(10),
                        ),
                      ),
                    ),
                    SizedBox(height: EvioSpacing.md),

                    // Title
                    Text(
                      'Evio Admin',
                      style: EvioTypography.h1.copyWith(fontSize: 28),
                    ),
                    SizedBox(height: EvioSpacing.xs),
                    Text(
                      'Creá tu cuenta de productor',
                      style: EvioTypography.bodyMedium.copyWith(
                        color: EvioLightColors.mutedForeground,
                      ),
                    ),
                    SizedBox(height: EvioSpacing.xxl),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nombre',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                              filled: true,
                              fillColor: EvioLightColors.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.mutedForeground,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresá tu nombre';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: EvioSpacing.md),

                          // Surname
                          TextFormField(
                            controller: _surnameController,
                            decoration: InputDecoration(
                              labelText: 'Apellido',
                              prefixIcon: Icon(Icons.person_outline, size: 20),
                              filled: true,
                              fillColor: EvioLightColors.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.mutedForeground,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresá tu apellido';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: EvioSpacing.md),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, size: 20),
                              filled: true,
                              fillColor: EvioLightColors.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.mutedForeground,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresá tu email';
                              }
                              if (!value.contains('@')) {
                                return 'Email inválido';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: EvioSpacing.md),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                              filled: true,
                              fillColor: EvioLightColors.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.mutedForeground,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Ingresá tu contraseña';
                              }
                              if (value.length < 6) {
                                return 'Mínimo 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: EvioSpacing.md),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirmar contraseña',
                              prefixIcon: Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  );
                                },
                              ),
                              filled: true,
                              fillColor: EvioLightColors.inputBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  EvioRadius.input,
                                ),
                                borderSide: BorderSide(
                                  color: EvioLightColors.mutedForeground,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirmá tu contraseña';
                              }
                              if (value != _passwordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: EvioSpacing.xl),

                          // Register button
                          SizedBox(
                            height: EvioSpacing.buttonHeight,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: EvioLightColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    EvioRadius.button,
                                  ),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Crear cuenta',
                                      style: EvioTypography.button,
                                    ),
                            ),
                          ),
                          SizedBox(height: EvioSpacing.xl),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: EvioLightColors.border),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: EvioSpacing.md,
                                ),
                                child: Text(
                                  'o',
                                  style: TextStyle(
                                    color: EvioLightColors.mutedForeground,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: EvioLightColors.border),
                              ),
                            ],
                          ),
                          SizedBox(height: EvioSpacing.xl),

                          // Login link - centered properly
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '¿Ya tenés cuenta? ',
                                style: EvioTypography.bodySmall.copyWith(
                                  color: EvioLightColors.mutedForeground,
                                  height: 1.0,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/login'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Ingresá',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
