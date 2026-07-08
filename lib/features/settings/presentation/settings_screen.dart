import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../features/auth/domain/auth_user.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import 'widgets/profile_edit_dialog.dart';

/// Pantalla de Configuración de Usuario.
///
/// Permite gestionar las preferencias del sistema en caliente (tema e idioma)
/// y realizar acciones de cuenta de forma segura (cambio de contraseña y logout).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  String _getPlanDisplayName(AuthUser? user) {
    if (user == null) return 'Cargando...';
    if (user.role == 'admin' || user.role == 'manager') {
      return 'Administrador (Todos los planes)';
    }
    final slug = user.planSlug;
    if (slug == null) return 'Sin plan activo';
    switch (slug.toLowerCase()) {
      case 'bronze':
        return 'Plan Bronce';
      case 'silver':
        return 'Plan Plata';
      case 'gold':
        return 'Plan Oro';
      case 'platinum':
        return 'Plan Platino';
      default:
        return 'Plan ${slug[0].toUpperCase()}${slug.substring(1)}';
    }
  }

  Color _getPlanColor(String? slug) {
    if (slug == null) return Colors.grey;
    switch (slug.toLowerCase()) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'platinum':
        return const Color(0xFFE5E4E2);
      default:
        return AppColors.accent;
    }
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        content: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(LucideIcons.logOut, size: 40, color: glassTheme.negative),
              const SizedBox(height: 16),
              Text(
                '¿Cerrar sesión?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: glassTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Vas a salir de tu sesión actual y vas a tener que re-autenticarte para volver a ingresar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: glassTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(l10n.commonCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: glassTheme.negative,
                      ),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await ref.read(supabaseClientProvider).auth.signOut();
                      },
                      child: Text(l10n.confirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    AuthUser? user,
  ) {
    if (user == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProfileEditDialog(user: user),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final gate = ref.watch(authGateProvider);
    final user = gate is GateAuthenticated ? gate.user : null;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.settings, size: 22),
              const SizedBox(width: 10),
              Text(l10n.navSettings),
            ],
          ),
          actions: buildAppBarActions(context),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // --- SECCIÓN INTERFAZ ---
                  _SectionHeader(title: l10n.settingsInterface),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Selector de Tema
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.sun,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.settingsTheme,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: glassTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: Text(l10n.settingsThemeLight),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: Text(l10n.settingsThemeDark),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: Text(l10n.settingsThemeSystem),
                            ),
                          ],
                          selected: {themeMode},
                          onSelectionChanged: (s) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(s.first);
                          },
                        ),
                        const SizedBox(height: 24),
                        // Selector de Idioma
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  LucideIcons.languages,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  l10n.settingsLanguage,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: glassTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SegmentedButton<Locale>(
                          segments: [
                            ButtonSegment(
                              value: const Locale('es'),
                              label: Text(l10n.settingsLanguageEs),
                            ),
                            ButtonSegment(
                              value: const Locale('en'),
                              label: Text(l10n.settingsLanguageEn),
                            ),
                          ],
                          selected: {locale},
                          onSelectionChanged: (s) {
                            ref
                                .read(localeProvider.notifier)
                                .setLocale(s.first);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- SECCIÓN PLAN ---
                  const _SectionHeader(title: 'Plan de la Academia'),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.award,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Tu Plan Actual',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: glassTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getPlanDisplayName(user),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getPlanColor(user?.planSlug),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.go('/academy'),
                          icon: const Icon(LucideIcons.graduationCap, size: 18),
                          label: Text(
                            user?.planSlug == null &&
                                    user?.role != 'admin' &&
                                    user?.role != 'manager'
                                ? 'Ver Planes'
                                : 'Actualizar Plan',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- SECCIÓN PERFIL ---
                  const _SectionHeader(title: 'Datos Personales'),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProfileInfoRow(
                          icon: LucideIcons.user,
                          label: 'Nombre y apellidos',
                          value:
                              user?.fullName != null &&
                                  user!.fullName!.isNotEmpty
                              ? user.fullName!
                              : 'No especificado',
                        ),
                        Divider(
                          height: 24,
                          thickness: 0.5,
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.12),
                        ),
                        _ProfileInfoRow(
                          icon: LucideIcons.mail,
                          label: 'Email',
                          value: user?.email ?? 'No especificado',
                        ),
                        Divider(
                          height: 24,
                          thickness: 0.5,
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.12),
                        ),
                        _ProfileInfoRow(
                          icon: LucideIcons.phone,
                          label: 'Phone number',
                          value: user?.phone != null && user!.phone!.isNotEmpty
                              ? user.phone!
                              : 'No especificado',
                        ),
                        Divider(
                          height: 24,
                          thickness: 0.5,
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.12),
                        ),
                        _ProfileInfoRow(
                          icon: LucideIcons.globe,
                          label: 'Country',
                          value:
                              user?.country != null && user!.country!.isNotEmpty
                              ? user.country!
                              : 'No especificado',
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showEditProfileDialog(context, ref, user),
                          icon: const Icon(LucideIcons.edit3, size: 18),
                          label: const Text('Editar Perfil'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- SECCIÓN CUENTA ---
                  _SectionHeader(title: l10n.settingsAccount),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push('/change-password'),
                          icon: const Icon(LucideIcons.key, size: 18),
                          label: Text(l10n.settingsChangePassword),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: glassTheme.negative.withOpacity(
                              0.12,
                            ),
                            foregroundColor: glassTheme.negative,
                          ),
                          onPressed: () => _showSignOutDialog(context, ref),
                          icon: const Icon(LucideIcons.logOut, size: 18),
                          label: Text(l10n.settingsSignOut),
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
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: context.glass.textSecondary,
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: glassTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
