import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:evio_core/evio_core.dart';
import 'package:intl/intl.dart';

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
  // ✅ Flag bomb-proof para evitar memory leaks
  bool _isDisposed = false;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _dniController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();

  DateTime? _birthDate;
  String? _selectedGender;
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  final _genderOptions = [
    ('male', 'Masculino'),
    ('female', 'Femenino'),
    ('other', 'Otro'),
    ('prefer_not_to_say', 'Prefiero no decir'),
  ];

  @override
  void dispose() {
    _isDisposed = true;
    _nameController.dispose();
    _surnameController.dispose();
    _dniController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final maxDate = DateTime(now.year - 13, now.month, now.day); // Mínimo 13 años
    final minDate = DateTime(1920);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: minDate,
      lastDate: maxDate,
      locale: const Locale('es', 'AR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: EvioFanColors.primary,
              onPrimary: EvioFanColors.primaryForeground,
              surface: EvioFanColors.surface,
              onSurface: EvioFanColors.foreground,
            ),
            dialogBackgroundColor: EvioFanColors.background,
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _handleRegister() async {
    if (_isDisposed) return; // ✅ Check antes de cualquier operación
    
    if (!_formKey.currentState!.validate()) return;
    
    if (_birthDate == null) {
      setState(() => _error = 'Seleccioná tu fecha de nacimiento');
      return;
    }
    
    if (_selectedGender == null) {
      setState(() => _error = 'Seleccioná tu sexo');
      return;
    }

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
        dni: _dniController.text.trim(),
        birthDate: _birthDate!,
        gender: _selectedGender!,
      ).timeout(const Duration(seconds: 30)); // ✅ Timeout para registro

      if (_isDisposed || !mounted) return; // ✅ Check después de async
      widget.onRegisterSuccess();
    } catch (e) {
      if (_isDisposed || !mounted) return; // ✅ Check después de async
      
      String errorMessage = 'Error al crear la cuenta. Intentá de nuevo.';
      if (e.toString().contains('timeout') || e.toString().contains('Timeout')) {
        errorMessage = 'La conexión tardó demasiado. Verificá tu internet.';
      } else if (e.toString().contains('already registered') || 
                 e.toString().contains('already exists')) {
        errorMessage = 'Este email ya está registrado.';
      }
      
      setState(() => _error = errorMessage);
    } finally {
      if (!_isDisposed && mounted) { // ✅ Check antes de setState final
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: EvioFanColors.surface,
      labelStyle: TextStyle(color: EvioFanColors.mutedForeground),
      hintStyle: TextStyle(color: EvioFanColors.mutedForeground.withValues(alpha: 0.5)),
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
        borderSide: BorderSide(color: EvioFanColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(EvioRadius.input),
        borderSide: BorderSide(color: EvioFanColors.error),
      ),
    );
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
                SizedBox(height: EvioSpacing.xl),

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

                SizedBox(height: EvioSpacing.xxl),

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

                SizedBox(height: EvioSpacing.lg),

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
                        Icon(Icons.error_outline, color: EvioFanColors.error, size: 20),
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
                  SizedBox(height: EvioSpacing.md),
                ],

                // ═══════════════════════════════════════════════════════
                // NOMBRE Y APELLIDO
                // ═══════════════════════════════════════════════════════
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: EvioTypography.bodyLarge.copyWith(color: EvioFanColors.foreground),
                        decoration: _inputDecoration(
                          label: 'Nombre',
                          hint: 'Juan',
                          prefixIcon: Icon(Icons.person_outline, color: EvioFanColors.mutedForeground),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: EvioSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _surnameController,
                        textCapitalization: TextCapitalization.words,
                        style: EvioTypography.bodyLarge.copyWith(color: EvioFanColors.foreground),
                        decoration: _inputDecoration(
                          label: 'Apellido',
                          hint: 'Pérez',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: EvioSpacing.md),

                // ═══════════════════════════════════════════════════════
                // DNI
                // ═══════════════════════════════════════════════════════
                TextFormField(
                  controller: _dniController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(8),
                  ],
                  style: EvioTypography.bodyLarge.copyWith(color: EvioFanColors.foreground),
                  decoration: _inputDecoration(
                    label: 'DNI',
                    hint: '12345678',
                    prefixIcon: Icon(Icons.badge_outlined, color: EvioFanColors.mutedForeground),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresá tu DNI';
                    if (value.length < 7 || value.length > 8) return 'DNI inválido';
                    return null;
                  },
                ),

                SizedBox(height: EvioSpacing.md),

                // ═══════════════════════════════════════════════════════
                // FECHA DE NACIMIENTO Y SEXO
                // ═══════════════════════════════════════════════════════
                Row(
                  children: [
                    // Fecha de nacimiento
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectBirthDate,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: EvioFanColors.surface,
                            borderRadius: BorderRadius.circular(EvioRadius.input),
                            border: Border.all(color: EvioFanColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.cake_outlined, color: EvioFanColors.mutedForeground, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _birthDate != null
                                      ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                                      : 'Fecha de nac.',
                                  style: EvioTypography.bodyLarge.copyWith(
                                    color: _birthDate != null 
                                        ? EvioFanColors.foreground 
                                        : EvioFanColors.mutedForeground.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: EvioFanColors.mutedForeground),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: EvioSpacing.md),
                    
                    // Sexo
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: EvioFanColors.surface,
                          borderRadius: BorderRadius.circular(EvioRadius.input),
                          border: Border.all(color: EvioFanColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            hint: Text(
                              'Sexo',
                              style: EvioTypography.bodyLarge.copyWith(
                                color: EvioFanColors.mutedForeground.withValues(alpha: 0.5),
                              ),
                            ),
                            icon: Icon(Icons.arrow_drop_down, color: EvioFanColors.mutedForeground),
                            dropdownColor: EvioFanColors.surface,
                            isExpanded: true,
                            style: EvioTypography.bodyLarge.copyWith(color: EvioFanColors.foreground),
                            items: _genderOptions.map((option) {
                              return DropdownMenuItem(
                                value: option.$1,
                                child: Text(option.$2),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedGender = value),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: EvioSpacing.md),

                // ═══════════════════════════════════════════════════════
                // EMAIL
                // ═══════════════════════════════════════════════════════
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: EvioTypography.bodyLarge.copyWith(color: EvioFanColors.foreground),
                  decoration: _inputDecoration(
                    label: 'Email',
                    hint: 'tu@email.com',
                    prefixIcon: Icon(Icons.email_outlined, color: EvioFanColors.mutedForeground),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresá tu email';
                    if (!value.contains('@')) return 'Email inválido';
                    return null;
                  },
                ),

                SizedBox(height: EvioSpacing.md),

                // ═══════════════════════════════════════════════════════
                // PASSWORD
                // ═══════════════════════════════════════════════════════
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: EvioTypography.bodyLarge.copyWith(color: EvioFanColors.foreground),
                  decoration: _inputDecoration(
                    label: 'Contraseña',
                    hint: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline, color: EvioFanColors.mutedForeground),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: EvioFanColors.mutedForeground,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresá una contraseña';
                    if (value.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),

                SizedBox(height: EvioSpacing.md),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  style: EvioTypography.bodyLarge.copyWith(color: EvioFanColors.foreground),
                  decoration: _inputDecoration(
                    label: 'Confirmar Contraseña',
                    hint: '••••••••',
                    prefixIcon: Icon(Icons.lock_outline, color: EvioFanColors.mutedForeground),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: EvioFanColors.mutedForeground,
                      ),
                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Confirmá tu contraseña';
                    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),

                SizedBox(height: EvioSpacing.xl),

                // ═══════════════════════════════════════════════════════
                // BOTÓN REGISTRAR
                // ═══════════════════════════════════════════════════════
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EvioFanColors.primary,
                      foregroundColor: EvioFanColors.primaryForeground,
                      disabledBackgroundColor: EvioFanColors.mutedForeground.withValues(alpha: 0.3),
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

                SizedBox(height: EvioSpacing.lg),

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
                
                SizedBox(height: EvioSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
