import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../domain/auth_user.dart';
import 'login_controller.dart';

/// Vista de Autenticación para validar el flujo completo de dos patas.
///
/// Si la configuración del entorno no está lista o contiene placeholders,
/// muestra un aviso explicativo de configuración antes de permitir el login.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(loginControllerProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final LoginState loginState = ref.watch(loginControllerProvider);
    final isValidConfig = AppConfig.isValidSupabaseConfig;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 24,
                color: AppColors.accentSoft,
              ),
              SizedBox(width: 10),
              Text('Investep Auth'),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!isValidConfig) ...[
                    _buildConfigWarningCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildLoginContent(loginState, isValidConfig),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigWarningCard() {
    return GlassCard(
      borderRadius: 16,
      blur: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: AppColors.negative,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                'FALTA CONFIGURACIÓN',
                style: TextStyle(
                  color: AppColors.negative,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'No se detectó una configuración válida de Supabase. '
            'Asegurate de correr la app usando --dart-define-from-file o definiendo las variables necesarias.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const Divider(height: 20, color: AppColors.glassBorder),
          _buildInfoRow('API Base URL', AppConfig.apiBaseUrl),
          const SizedBox(height: 4),
          _buildInfoRow('Supabase URL', AppConfig.supabaseUrl),
          const SizedBox(height: 4),
          _buildInfoRow(
            'Anon Key',
            AppConfig.supabaseAnonKey.isEmpty
                ? '(Vacío)'
                : AppConfig.supabaseAnonKey.length > 15
                ? '${AppConfig.supabaseAnonKey.substring(0, 15)}...'
                : AppConfig.supabaseAnonKey,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '(No configurado)' : value,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginContent(LoginState state, bool isValidConfig) {
    switch (state) {
      case LoginSuccess(:final user):
        return _buildSuccessCard(user);
      case LoginLoading():
        return const GlassCard(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Autenticando y validando...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      case LoginInitial() || LoginFailure():
        return Column(
          children: [
            if (state is LoginFailure) ...[
              _buildErrorCard(state.message),
              const SizedBox(height: 16),
            ],
            _buildLoginFormCard(isValidConfig),
          ],
        );
    }
  }

  Widget _buildErrorCard(String message) {
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.xCircle, color: AppColors.negative, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error de Autenticación',
                  style: TextStyle(
                    color: AppColors.negative,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(AuthUser user) {
    final email = user.email;
    final id = user.id;
    final mustReset = user.mustResetPassword;

    return GlassCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Icon(
              LucideIcons.badgeCheck,
              color: AppColors.positive,
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              '¡Conexión Exitosa!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.positive,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Autenticación y validación de API correctas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          _buildDetailRow('Email del Usuario', email),
          const SizedBox(height: 12),
          _buildDetailRow('ID de Usuario', id),
          const SizedBox(height: 12),
          _buildDetailRow(
            'Contraseña Expirada',
            mustReset ? 'SÍ (DEBÉS CAMBIAR TU CONTRASEÑA)' : 'NO',
            valueColor: mustReset ? AppColors.negative : AppColors.positive,
            fontWeight: mustReset ? FontWeight.bold : FontWeight.normal,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ref.read(loginControllerProvider.notifier).reset();
            },
            icon: const Icon(LucideIcons.logOut, size: 18),
            label: const Text('Cerrar sesión / Probar de nuevo'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color valueColor = AppColors.textPrimary,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: fontWeight,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFormCard(bool isEnabled) {
    return GlassCard(
      borderRadius: 20,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Iniciar Sesión',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ingresá tus credenciales para validar el acceso.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              enabled: isEnabled,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(LucideIcons.mail, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresá tu email';
                }
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingresá un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              enabled: isEnabled,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => isEnabled ? _submit() : null,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(LucideIcons.lock, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresá tu contraseña';
                }
                if (value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: AppColors.accent.withValues(
                  alpha: 0.3,
                ),
              ),
              onPressed: isEnabled ? _submit : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ingresar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(LucideIcons.arrowRight, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
