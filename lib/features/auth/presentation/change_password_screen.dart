import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/language_selector.dart';
import '../../../shared/widgets/theme_selector.dart';
import '../domain/password_policy.dart';
import 'change_password_controller.dart';
import 'login_controller.dart';

/// Pantalla de cambio de contraseña.
///
/// Se llega acá cuando `/auth/me` reporta `mustResetPassword == true`. Al
/// completar el cambio, la sesión se cierra y se vuelve al login para
/// re-autenticarse con la contraseña nueva.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ref
          .read(changePasswordControllerProvider.notifier)
          .submit(_passwordController.text);
    }
  }

  void _goToLogin() {
    // Volvemos al login en estado limpio: ya cerramos sesión en el controller.
    ref.read(loginControllerProvider.notifier).reset();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final ChangePasswordState state = ref.watch(
      changePasswordControllerProvider,
    );

    // Al cambiar la contraseña, el backend revoca la sesión: el controller hace
    // signOut → AuthGate pasa a GateNoSession → el router redirige a /login. Acá
    // sólo avisamos. El ScaffoldMessenger raíz sobrevive el cambio de ruta.
    ref.listen(changePasswordControllerProvider, (prev, next) {
      if (next is ChangePasswordSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).passwordChangedRelogin),
          ),
        );
      }
    });

    return Container(
      decoration: BoxDecoration(gradient: context.glass.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(LucideIcons.lock, size: 24, color: AppColors.accentSoft),
              SizedBox(width: 10),
              Text('Cambiar contraseña'),
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
                child: _buildContent(state),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ChangePasswordState state) {
    switch (state) {
      case ChangePasswordLoading():
        return const GlassCard(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Actualizando tu contraseña...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      case ChangePasswordSuccess():
        return _buildSuccessCard();
      case ChangePasswordSessionExpired(:final message):
        return _buildSessionExpiredCard(message);
      case ChangePasswordInitial() || ChangePasswordFailure():
        return Column(
          children: [
            if (state is ChangePasswordFailure) ...[
              _buildErrorCard(state.message),
              const SizedBox(height: 16),
            ],
            _buildFormCard(),
          ],
        );
    }
  }

  /// Card para `ChangePasswordSessionExpired` (401): la sesión ya no es válida,
  /// así que no se puede cambiar la contraseña con ella. Volvemos al login.
  Widget _buildSessionExpiredCard(String message) {
    final glassTheme = context.glass;
    final theme = Theme.of(context);
    return GlassCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              LucideIcons.shieldAlert,
              color: glassTheme.negative,
              size: 56,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Tu sesión expiró',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: glassTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: glassTheme.textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            onPressed: _goToLogin,
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: const Text('Ir a iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard() {
    final glassTheme = context.glass;
    final theme = Theme.of(context);
    return GlassCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Icon(
              LucideIcons.badgeCheck,
              color: glassTheme.positive,
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '¡Contraseña actualizada!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: glassTheme.positive,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Iniciá sesión nuevamente con tu nueva contraseña.',
              textAlign: TextAlign.center,
              style: TextStyle(color: glassTheme.textSecondary, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const StadiumBorder(),
            ),
            onPressed: _goToLogin,
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: const Text('Ir a iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    final glassTheme = context.glass;
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
                  'No se pudo cambiar la contraseña',
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

  Widget _buildFormCard() {
    final glassTheme = context.glass;
    final theme = Theme.of(context);
    return GlassCard(
      borderRadius: 20,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Definí tu nueva contraseña',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: glassTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu contraseña expiró. Elegí una nueva para continuar.',
              style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: glassTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Contraseña nueva',
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
                    setState(() => _obscurePassword = !_obscurePassword);
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
              validator: validateNewPassword,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: TextStyle(color: glassTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'Repetir contraseña',
                labelStyle: TextStyle(color: glassTheme.textSecondary),
                prefixIcon: Icon(
                  LucideIcons.lock,
                  size: 20,
                  color: glassTheme.textSecondary,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff,
                    size: 20,
                    color: glassTheme.textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _obscureConfirm = !_obscureConfirm);
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
              validator: (value) =>
                  validatePasswordConfirmation(value, _passwordController.text),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              onPressed: _submit,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Guardar contraseña',
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
