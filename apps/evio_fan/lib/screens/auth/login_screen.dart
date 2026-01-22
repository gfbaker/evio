import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evio_core/evio_core.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final VoidCallback onRegisterTap;
  final VoidCallback onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.onRegisterTap,
    required this.onLoginSuccess,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _isDisposed = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _isDisposed = true;
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isDisposed) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ).timeout(const Duration(seconds: 15));

      if (_isDisposed || !mounted) return;
      widget.onLoginSuccess();
    } catch (e) {
      if (_isDisposed || !mounted) return;
      setState(() {
        _error = 'Email o contraseña incorrectos';
      });
    } finally {
      if (!_isDisposed && mounted) {
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
                  'Iniciar Sesión',
                  style: EvioTypography.titleLarge.copyWith(
                    color: EvioFanColors.foreground,
                  ),
                ),

                SizedBox(height: EvioSpacing.xs),

                Text(
                  'Ingresá a tu cuenta para continuar',
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
                      return 'Ingresá tu contraseña';
                    }
                    return null;
                  },
                ),

                SizedBox(height: EvioSpacing.sm),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Implement forgot password
                    },
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: EvioTypography.bodySmall.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: EvioSpacing.lg),

                // Login button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                        : Text('Iniciar Sesión', style: EvioTypography.button),
                  ),
                ),

                SizedBox(height: EvioSpacing.xl),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tenés cuenta? ',
                      style: EvioTypography.bodyMedium.copyWith(
                        color: EvioFanColors.mutedForeground,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onRegisterTap,
                      child: Text(
                        'Registrate',
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
