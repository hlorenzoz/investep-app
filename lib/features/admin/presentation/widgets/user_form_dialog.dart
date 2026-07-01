import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../domain/user_admin.dart';
import '../providers/admin_users_provider.dart';

/// Formulario modal para crear (aprovisionar) y editar usuarios.
class UserFormDialog extends ConsumerStatefulWidget {
  const UserFormDialog({super.key, this.user});

  final UserAdmin? user;

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'user';
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final user = widget.user!;
      _emailController.text = user.email;
      _fullNameController.text = user.fullName;
      _selectedRole = user.role.toLowerCase();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'email': _emailController.text.trim(),
      'fullName': _fullNameController.text.trim(),
      'role': _selectedRole,
    };

    if (_passwordController.text.isNotEmpty) {
      data['password'] = _passwordController.text;
    }

    try {
      if (_isEditing) {
        await ref
            .read(adminUsersProvider.notifier)
            .updateUser(widget.user!.id, data);
      } else {
        await ref.read(adminUsersProvider.notifier).createUser(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Usuario actualizado con éxito.'
                  : 'Usuario aprovisionado y creado con éxito.',
            ),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      _isEditing ? LucideIcons.edit3 : LucideIcons.userPlus2,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEditing ? 'Editar Usuario' : 'Aprovisionar Usuario',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: glassTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.negative.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.negative,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Email
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Correo Electrónico',
                    prefixIcon: Icon(LucideIcons.mail, size: 20),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: glassTheme.textPrimary),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'El correo es requerido';
                    }
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                    if (!emailRegex.hasMatch(val.trim())) {
                      return 'Formato de correo inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Nombre Completo
                TextFormField(
                  controller: _fullNameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                    prefixIcon: Icon(LucideIcons.user, size: 20),
                  ),
                  style: TextStyle(color: glassTheme.textPrimary),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'El nombre completo es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Rol
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol del Sistema',
                    prefixIcon: Icon(LucideIcons.shield, size: 20),
                  ),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  style: TextStyle(color: glassTheme.textPrimary),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (val) {
                          if (val != null) {
                            setState(() {
                              _selectedRole = val;
                            });
                          }
                        },
                ),
                const SizedBox(height: 16),
                // Contraseña
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: _isEditing
                        ? 'Nueva Contraseña (Opcional)'
                        : 'Contraseña (Opcional)',
                    prefixIcon: const Icon(LucideIcons.lock, size: 20),
                    helperText: _isEditing
                        ? 'Si se modifica, obligará a resetearla en su próximo login.'
                        : 'Si se omite, se generará una clave aleatoria de alta entropía.',
                    helperMaxLines: 2,
                  ),
                  obscureText: true,
                  style: TextStyle(color: glassTheme.textPrimary),
                ),
                const SizedBox(height: 24),
                // Acciones
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: glassTheme.textSecondary),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _isEditing ? 'Guardar Cambios' : 'Aprovisionar',
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
