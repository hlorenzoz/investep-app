import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/theme_selector.dart';
import 'last_email_provider.dart';
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
  void initState() {
    super.initState();
    // Precarga el email recordado (p. ej. tras un cambio de contraseña que
    // desloguea y vuelve al login).
    final lastEmail = ref.read(lastEmailProvider);
    if (lastEmail != null && lastEmail.isNotEmpty) {
      _emailController.text = lastEmail;
    }
  }

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
      decoration: BoxDecoration(gradient: context.glass.backgroundGradient),
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
          actions: const [
            LanguageSelector(),
            ThemeSelector(),
            SizedBox(width: 16),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
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
      ),
    );
  }

  Widget _buildConfigWarningCard() {
    final glassTheme = context.glass;
    return GlassCard(
      borderRadius: 16,
      blur: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                color: glassTheme.negative,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'FALTA CONFIGURACIÓN',
                style: TextStyle(
                  color: glassTheme.negative,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'No se detectó una configuración válida de Supabase. '
            'Asegurate de correr la app usando --dart-define-from-file o definiendo las variables necesarias.',
            style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
          ),
          Divider(height: 20, color: glassTheme.glassBorder),
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
    final glassTheme = context.glass;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: glassTheme.textPrimary,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '(No configurado)' : value,
            style: TextStyle(
              fontFamily: 'monospace',
              color: glassTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginContent(LoginState state, bool isValidConfig) {
    final glassTheme = context.glass;
    final l10n = AppLocalizations.of(context);
    switch (state) {
      case LoginLoading():
        return GlassCard(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                l10n.loginAuthenticating,
                style: TextStyle(color: glassTheme.textSecondary),
              ),
            ],
          ),
        );
      case LoginInitial() || LoginFailure():
        return Column(
          children: [
            Image.asset(
              'web/investep/logo.webp',
              height: 60,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
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
    final glassTheme = context.glass;
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.xCircle, color: glassTheme.negative, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.loginAuthError,
                  style: TextStyle(
                    color: glassTheme.negative,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: glassTheme.textSecondary,
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

  Widget _buildLoginFormCard(bool isEnabled) {
    final glassTheme = context.glass;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      borderRadius: 20,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.loginTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: glassTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loginSubtitle,
              style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              enabled: isEnabled,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: glassTheme.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.loginEmailLabel,
                labelStyle: TextStyle(color: glassTheme.textSecondary),
                prefixIcon: Icon(
                  LucideIcons.mail,
                  size: 20,
                  color: glassTheme.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: glassTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
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
              style: TextStyle(color: glassTheme.textPrimary),
              decoration: InputDecoration(
                labelText: l10n.loginPasswordLabel,
                labelStyle: TextStyle(color: glassTheme.textSecondary),
                prefixIcon: Icon(
                  LucideIcons.lock,
                  size: 20,
                  color: glassTheme.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 20,
                    color: glassTheme.textSecondary,
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
                  borderSide: BorderSide(color: glassTheme.glassBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresá tu contraseña';
                }
                final email = _emailController.text.trim().toLowerCase();
                final isDemo = email == 'demo@hlorenzoz.com';
                if (!isDemo && value.length < 6) {
                  return 'La contraseña debe tener al menos 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
                disabledBackgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.3,
                ),
              ),
              onPressed: isEnabled ? _submit : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.loginSubmitButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.arrowRight, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => launchUrl(
                    Uri.parse('https://investepacademy.com/team'),
                    mode: LaunchMode.externalApplication,
                  ),
                  child: Text(
                    l10n.loginRegisterButton,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.loginRegisterHint,
              style: TextStyle(
                color: glassTheme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
