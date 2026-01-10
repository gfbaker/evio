import 'package:flutter/material.dart';
import 'package:evio_core/evio_core.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterSuccess;

  const RegisterScreen({
    super.key,
    required this.onLoginTap,
    required this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authRepository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
      );

      if (mounted) {
        widget.onRegisterSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al crear la cuenta. Intentá de nuevo.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EvioFanColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: EvioSpacing.screenHorizontal,
            vertical: EvioSpacing.screenVertical,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: EvioSpacing.xxxl),

                // Logo
                Text(
                  'EVIO',
                  style: EvioTypography.displayLarge.copyWith(
                    color: EvioFanColors.primary,
                    letterSpacing: 8,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: EvioSpacing.xs),

                Text(
                  'CLUB',
                  style: EvioTypography.titleLarge.copyWith(
                    color: EvioFanColors.mutedForeground,
                    letterSpacing: 12,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: EvioSpacing.xxxl),

                // Título
                Text(
                  'Crear Cuenta',
                  style: EvioTypography.titleLarge.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                ),

                SizedBox(height: EvioSpacing.xs),

                Text(
                  'Completá tus datos para registrarte',
                  style: EvioTypography.bodyMedium.copyWith(
                    color: EvioFanColors.mutedForeground,
                  ),
                ),

                SizedBox(height: EvioSpacing.xl),

                // Error
                if (_error != null) ...[
                  Container(
                    padding: EdgeInsets.all(EvioSpacing.md),
                    decoration: BoxDecoration(
                      color: EvioFanColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(EvioRadius.card),
                      border: Border.all(
                        color: EvioFanColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: EvioFanColors.error,
                          size: EvioSpacing.iconM,
                        ),
                        SizedBox(width: EvioSpacing.sm),
                        Expanded(
                          child: Text(
                            _error!,
                            style: EvioTypography.bodyMedium.copyWith(
                              color: EvioFanColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: EvioSpacing.lg),
                ],

                // Nombre y Apellido
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: EvioTypography.bodyLarge.copyWith(
                          color: EvioFanColors.foreground,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Juan',
                          prefixIcon: Icon(
                            Icons.person_outline,
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: EvioSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _surnameController,
                        textCapitalization: TextCapitalization.words,
                        style: EvioTypography.bodyLarge.copyWith(
                          color: EvioFanColors.foreground,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Apellido',
                          hintText: 'Pérez',
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: EvioSpacing.md),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: EvioTypography.bodyLarge.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'tu@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
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
                  style: EvioTypography.bodyLarge.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    hintText: '••••••••',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: EvioFanColors.mutedForeground,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: EvioFanColors.mutedForeground,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresá una contraseña';
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
                  style: EvioTypography.bodyLarge.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Confirmar Contraseña',
                    hintText: '••••••••',
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: EvioFanColors.mutedForeground,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: EvioFanColors.mutedForeground,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
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
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EvioFanColors.primary,
                      foregroundColor: EvioFanColors.primaryForeground,
                      disabledBackgroundColor: EvioFanColors.mutedForeground
                          .withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EvioRadius.button),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: EvioFanColors.primaryForeground,
                            ),
                          )
                        : Text('Crear Cuenta', style: EvioTypography.button),
                  ),
                ),

                SizedBox(height: EvioSpacing.xl),

                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tenés cuenta? ',
                      style: EvioTypography.bodyMedium.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onLoginTap,
                      child: Text(
                        'Iniciá Sesión',
                        style: EvioTypography.button.copyWith(
                          color: EvioFanColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
