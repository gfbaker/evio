import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';

import '../../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authController = ref.read(authControllerProvider);
      await authController.resetPassword(_emailController.text.trim());

      if (!mounted) return;
      setState(() => _emailSent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: EvioLightColors.destructive,
        ),
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
                    if (!_emailSent) ...[
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
                        'Recuperar contraseña',
                        style: EvioTypography.h1.copyWith(fontSize: 28),
                      ),
                      SizedBox(height: EvioSpacing.xs),
                      Text(
                        'Te enviaremos un link para restablecer tu contraseña',
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
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 20,
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
                                  return 'Ingresá tu email';
                                }
                                if (!value.contains('@')) {
                                  return 'Email inválido';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: EvioSpacing.xl),

                            // Submit button
                            SizedBox(
                              height: EvioSpacing.buttonHeight,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _handleResetPassword,
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
                                        'Enviar link',
                                        style: EvioTypography.button,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Success state
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mark_email_read_outlined,
                            size: 40,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      SizedBox(height: EvioSpacing.xl),

                      Text(
                        '¡Email enviado!',
                        style: EvioTypography.h1.copyWith(fontSize: 28),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: EvioSpacing.sm),
                      Text(
                        'Revisá tu correo ${_emailController.text} para restablecer tu contraseña.',
                        style: EvioTypography.bodyMedium.copyWith(
                          color: EvioLightColors.mutedForeground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: EvioSpacing.xxl),

                      // Back to login button
                      SizedBox(
                        height: EvioSpacing.buttonHeight,
                        child: OutlinedButton(
                          onPressed: () => context.go('/login'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: EvioLightColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                EvioRadius.button,
                              ),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Volver al login'),
                        ),
                      ),
                    ],
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
