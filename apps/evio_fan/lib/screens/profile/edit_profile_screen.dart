import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:evio_core/evio_core.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isDisposed = false;
  bool _isSaving = false;

  // Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _dniController;
  
  // Campos que solo se setean una vez
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  
  // Flags para saber si los campos readonly ya tienen valor
  bool _dniAlreadySet = false;
  bool _birthDateAlreadySet = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializar controllers vacíos, los llenamos en didChangeDependencies
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _dniController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Cargar datos del usuario cuando esté disponible
    final userAsync = ref.read(currentUserProvider);
    userAsync.whenData((user) {
      if (user != null && !_isDisposed) {
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
        _phoneController.text = user.phone ?? '';
        _dniController.text = user.dni ?? '';
        _selectedBirthDate = user.birthDate;
        _selectedGender = user.gender;
        _dniAlreadySet = user.dni != null && user.dni!.isNotEmpty;
        _birthDateAlreadySet = user.birthDate != null;
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            backgroundColor: EvioFanColors.background,
            appBar: AppBar(
              backgroundColor: EvioFanColors.background,
              title: const Text('Editar perfil'),
            ),
            body: const Center(child: Text('No hay sesión activa')),
          );
        }
        return _buildContent(user);
      },
      loading: () => Scaffold(
        backgroundColor: EvioFanColors.background,
        appBar: AppBar(
          backgroundColor: EvioFanColors.background,
          title: const Text('Editar perfil'),
        ),
        body: Center(
          child: CircularProgressIndicator(color: EvioFanColors.primary),
        ),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: EvioFanColors.background,
        appBar: AppBar(
          backgroundColor: EvioFanColors.background,
          title: const Text('Editar perfil'),
        ),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(User user) {
    return Scaffold(
      backgroundColor: EvioFanColors.background,
      appBar: AppBar(
        backgroundColor: EvioFanColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: EvioFanColors.foreground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Editar perfil',
          style: EvioTypography.h3.copyWith(color: EvioFanColors.foreground),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(EvioSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre
              _buildTextField(
                controller: _firstNameController,
                label: 'Nombre',
                hint: 'Tu nombre',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: EvioSpacing.md),

              // Apellido
              _buildTextField(
                controller: _lastNameController,
                label: 'Apellido',
                hint: 'Tu apellido',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El apellido es obligatorio';
                  }
                  return null;
                },
              ),
              SizedBox(height: EvioSpacing.md),

              // Email (readonly)
              _buildTextField(
                controller: TextEditingController(text: user.email),
                label: 'Email',
                hint: user.email,
                icon: Icons.email_outlined,
                enabled: false,
              ),
              SizedBox(height: EvioSpacing.md),

              // Teléfono
              _buildTextField(
                controller: _phoneController,
                label: 'Teléfono',
                hint: '+54 9 11 1234-5678',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: EvioSpacing.md),

              // DNI (readonly si ya fue establecido)
              _buildTextField(
                controller: _dniController,
                label: 'DNI',
                hint: '12345678',
                icon: Icons.badge_outlined,
                enabled: !_dniAlreadySet,
                keyboardType: TextInputType.number,
                helperText: _dniAlreadySet 
                    ? 'El DNI no puede modificarse' 
                    : 'Solo podrás establecerlo una vez',
                validator: (value) {
                  if (!_dniAlreadySet && (value == null || value.isEmpty)) {
                    return null; // DNI es opcional si no fue establecido
                  }
                  if (value != null && value.isNotEmpty && value.length < 7) {
                    return 'DNI inválido';
                  }
                  return null;
                },
              ),
              SizedBox(height: EvioSpacing.md),

              // Fecha de nacimiento
              _buildDateField(
                label: 'Fecha de nacimiento',
                value: _selectedBirthDate,
                enabled: !_birthDateAlreadySet,
                helperText: _birthDateAlreadySet
                    ? 'La fecha de nacimiento no puede modificarse'
                    : 'Solo podrás establecerla una vez',
                onTap: _birthDateAlreadySet ? null : () => _selectBirthDate(context),
              ),
              SizedBox(height: EvioSpacing.md),

              // Género
              _buildDropdownField(
                label: 'Género',
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Masculino')),
                  DropdownMenuItem(value: 'female', child: Text('Femenino')),
                  DropdownMenuItem(value: 'other', child: Text('Otro')),
                  DropdownMenuItem(
                    value: 'prefer_not_to_say',
                    child: Text('Prefiero no decir'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
              ),
              SizedBox(height: EvioSpacing.xl),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EvioFanColors.primary,
                    foregroundColor: EvioFanColors.primaryForeground,
                    padding: EdgeInsets.symmetric(vertical: EvioSpacing.md),
                    disabledBackgroundColor: EvioFanColors.muted,
                  ),
                  child: _isSaving
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              EvioFanColors.primaryForeground,
                            ),
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // WIDGETS DE FORMULARIO
  // ============================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: EvioTypography.labelMedium.copyWith(
            color: EvioFanColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: EvioTypography.bodyMedium.copyWith(
            color: enabled ? EvioFanColors.foreground : EvioFanColors.mutedForeground,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: EvioFanColors.mutedForeground),
            prefixIcon: Icon(icon, color: EvioFanColors.mutedForeground),
            filled: true,
            fillColor: enabled ? EvioFanColors.surface : EvioFanColors.muted,
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
            helperText: helperText,
            helperStyle: TextStyle(
              color: EvioFanColors.mutedForeground,
              fontSize: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required bool enabled,
    String? helperText,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: EvioTypography.labelMedium.copyWith(
            color: EvioFanColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            padding: EdgeInsets.all(EvioSpacing.md),
            decoration: BoxDecoration(
              color: enabled ? EvioFanColors.surface : EvioFanColors.muted,
              borderRadius: BorderRadius.circular(EvioRadius.input),
              border: Border.all(color: EvioFanColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: EvioFanColors.mutedForeground,
                ),
                SizedBox(width: EvioSpacing.md),
                Expanded(
                  child: Text(
                    value != null
                        ? '${value.day}/${value.month}/${value.year}'
                        : 'Seleccionar fecha',
                    style: EvioTypography.bodyMedium.copyWith(
                      color: value != null
                          ? (enabled ? EvioFanColors.foreground : EvioFanColors.mutedForeground)
                          : EvioFanColors.mutedForeground,
                    ),
                  ),
                ),
                if (enabled)
                  Icon(
                    Icons.arrow_drop_down,
                    color: EvioFanColors.mutedForeground,
                  ),
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          SizedBox(height: EvioSpacing.xxs),
          Text(
            helperText,
            style: TextStyle(
              color: EvioFanColors.mutedForeground,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: EvioTypography.labelMedium.copyWith(
            color: EvioFanColors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: EvioSpacing.xs),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          style: EvioTypography.bodyMedium.copyWith(
            color: EvioFanColors.foreground,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.wc_outlined, color: EvioFanColors.mutedForeground),
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
              borderSide: BorderSide(color: EvioFanColors.primary, width: 2),
            ),
          ),
          dropdownColor: EvioFanColors.surface,
        ),
      ],
    );
  }

  // ============================================
  // ACCIONES
  // ============================================

  Future<void> _selectBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: EvioFanColors.primary,
              onPrimary: EvioFanColors.primaryForeground,
              surface: EvioFanColors.surface,
              onSurface: EvioFanColors.foreground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && !_isDisposed && mounted) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Obtener usuario de la DB directamente
      final userRepo = ref.read(userRepositoryProvider);
      final user = await userRepo.getCurrentUser();
      if (user == null) throw Exception('Usuario no encontrado');

      final profileActions = ref.read(profileActionsProvider);

      await profileActions.updateProfile(
        userId: user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty 
            ? null 
            : _phoneController.text.trim(),
        dni: _dniController.text.trim().isEmpty 
            ? null 
            : _dniController.text.trim(),
        birthDate: _selectedBirthDate,
        gender: _selectedGender,
      );

      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil actualizado correctamente'),
            backgroundColor: EvioFanColors.primary,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: EvioFanColors.error,
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
