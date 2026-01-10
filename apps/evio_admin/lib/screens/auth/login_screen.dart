import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/common/floating_snackbar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authController = ref.read(authControllerProvider);
      await authController.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      context.go('/admin/dashboard');
    } catch (e) {
      if (!mounted) return;
      FloatingSnackBar.show(
        context,
        message: e.toString(),
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
                    // Title
                    Text(
                      'Evio Admin',
                      style: EvioTypography.h1.copyWith(fontSize: 28),
                    ),
                    SizedBox(height: EvioSpacing.xs),
                    Text(
                      'Ingresá a tu cuenta',
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
                          SizedBox(height: EvioSpacing.sm),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/reset-password'),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: EvioSpacing.xs,
                                  vertical: EvioSpacing.xs,
                                ),
                                minimumSize: Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          SizedBox(height: EvioSpacing.md),

                          // Login button
                          SizedBox(
                            height: EvioSpacing.buttonHeight,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
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
                                      'Ingresar',
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

                          // Register link - centered properly
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '¿No tenés cuenta? ',
                                style: EvioTypography.bodySmall.copyWith(
                                  color: EvioLightColors.mutedForeground,
                                  height: 1.0,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/register'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Registrate',
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
