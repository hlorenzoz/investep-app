import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/auth/auth_gate.dart';
import '../../../../core/config/countries.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/forms/country_selector.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/auth_user.dart';

/// Diálogo modal interactivo para que el propio usuario edite su perfil.
class ProfileEditDialog extends ConsumerStatefulWidget {
  const ProfileEditDialog({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends ConsumerState<ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _countryController = TextEditingController();

  Country? _selectedCountry;
  List<Country> _availableCountries = countriesList;
  bool _isUpdatingFromPhone = false;
  bool _isUpdatingFromCountry = false;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.user.fullName ?? '';
    _phoneController.text = widget.user.phone ?? '';

    // Buscar país inicial por nombre
    final initialCountryName = widget.user.country ?? '';
    Country? initialCountry;
    for (final c in countriesList) {
      if (c.name.toLowerCase() == initialCountryName.toLowerCase()) {
        initialCountry = c;
        break;
      }
    }
    _selectedCountry = initialCountry;
    if (_selectedCountry != null) {
      _countryController.text = _selectedCountry!.displayName;
    } else {
      _countryController.text = initialCountryName;
    }

    // Escuchar cambios en el teléfono para preselección
    _phoneController.addListener(_onPhoneChanged);
    _onPhoneChanged();
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _fullNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    if (_isUpdatingFromCountry) return;

    final text = _phoneController.text.trim();
    if (text.isEmpty || !text.startsWith('+')) {
      setState(() {
        _availableCountries = countriesList;
        _selectedCountry = null;
        _countryController.clear();
      });
      return;
    }

    final cleanPhone = text.replaceAll(RegExp(r'[^\d+]'), '');

    final matching = countriesList.where((c) {
      if (cleanPhone.length <= c.dialCode.length) {
        return c.dialCode.startsWith(cleanPhone);
      }
      return cleanPhone.startsWith(c.dialCode);
    }).toList();

    setState(() {
      _availableCountries = matching.isEmpty ? countriesList : matching;

      if (matching.length == 1) {
        _isUpdatingFromPhone = true;
        _selectedCountry = matching.first;
        _countryController.text = matching.first.displayName;
        _isUpdatingFromPhone = false;
      } else {
        if (_selectedCountry != null && !matching.contains(_selectedCountry)) {
          _selectedCountry = null;
          _countryController.clear();
        }
      }
    });
  }

  void _onCountrySelected(Country? country) {
    if (_isUpdatingFromPhone) return;
    _isUpdatingFromCountry = true;
    setState(() {
      _selectedCountry = country;
      if (country != null) {
        _countryController.text = country.displayName;

        final currentPhone = _phoneController.text.trim();
        if (currentPhone.isEmpty || currentPhone == '+') {
          _phoneController.text = '${country.dialCode} ';
        } else {
          final cleanPhone = currentPhone.replaceAll(RegExp(r'[^\d+]'), '');
          if (!cleanPhone.startsWith(country.dialCode)) {
            Country? oldCountry;
            for (final c in countriesList) {
              if (cleanPhone.startsWith(c.dialCode)) {
                oldCountry = c;
                break;
              }
            }
            if (oldCountry != null) {
              _phoneController.text = currentPhone.replaceFirst(
                oldCountry.dialCode,
                country.dialCode,
              );
            } else {
              final match = RegExp(r'^\+\d+').firstMatch(cleanPhone);
              if (match != null) {
                _phoneController.text = currentPhone.replaceFirst(
                  match.group(0)!,
                  country.dialCode,
                );
              } else {
                _phoneController.text = '${country.dialCode} $currentPhone';
              }
            }
          }
        }
      } else {
        _countryController.clear();
      }
    });
    _isUpdatingFromCountry = false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phoneTrimmed = _phoneController.text.trim();
    final countryName =
        _selectedCountry?.name ?? _countryController.text.trim();

    final data = <String, dynamic>{
      'fullName': _fullNameController.text.trim(),
      'phone': phoneTrimmed.isNotEmpty ? phoneTrimmed : null,
      'country': countryName.isNotEmpty ? countryName : null,
    };

    try {
      await ref.read(authRepositoryProvider).updateProfile(data);
      // Forzar el refresco en el gate para que recargue GET /auth/me y actualice la UI
      await ref.read(authGateProvider.notifier).forceRefresh();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu perfil ha sido actualizado con éxito.'),
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
                      LucideIcons.user,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Editar Perfil',
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
                // Nombre Completo
                TextFormField(
                  controller: _fullNameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Nombre y apellidos',
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
                // País
                CountrySelector(
                  selectedCountry: _selectedCountry,
                  availableCountries: _availableCountries,
                  onSelected: _onCountrySelected,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                // Teléfono
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (Opcional)',
                    prefixIcon: Icon(LucideIcons.phone, size: 20),
                  ),
                  keyboardType: TextInputType.phone,
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
                          : const Text('Guardar'),
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
