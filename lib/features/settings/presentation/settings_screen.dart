import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/theme_provider.dart';
import '../../../core/l10n/locale_provider.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/format/money.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../capital/data/capital_repository.dart';
import '../../capital/presentation/capital_controller.dart';

/// Pantalla de Configuración de Usuario.
///
/// Permite gestionar las preferencias del sistema en caliente (tema e idioma)
/// y realizar acciones de cuenta de forma segura (cambio de contraseña y logout).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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

  void _showEditCapitalDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final overview = ref.read(capitalControllerProvider).value;
    if (overview == null) return;

    final currentTotal = overview.capital?.totalCapital ?? 0;
    final allocated = overview.totalAllocated;
    final currency = overview.capital?.currency ?? 'USD';

    final controller = TextEditingController(text: '$currentTotal');

    showDialog<void>(
      context: context,
      builder: (ctx) {
        String? errorMessage;
        bool submitting = false;

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              content: GlassCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.wallet,
                          size: 24,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.settingsEditCapital,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: glassTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.settingsEditCapitalHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: glassTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.allocatedLabel}: ${formatMoney(allocated, currency)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: glassTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.settingsCapitalTotal,
                        suffixText: currency,
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: AppColors.negative,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(dialogCtx).pop(),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    final text = controller.text.trim();
                                    final val = double.tryParse(text);
                                    if (val == null || val <= 0) {
                                      setDialogState(() {
                                        errorMessage =
                                            'Ingresá un monto válido.';
                                      });
                                      return;
                                    }
                                    if (val < allocated) {
                                      setDialogState(() {
                                        errorMessage =
                                            'El capital no puede ser menor al monto asignado (${formatMoney(allocated, currency)}).';
                                      });
                                      return;
                                    }
                                    setDialogState(() {
                                      submitting = true;
                                      errorMessage = null;
                                    });
                                    try {
                                      await ref
                                          .read(capitalRepositoryProvider)
                                          .putCapital(totalCapital: val);
                                      await ref
                                          .read(
                                            capitalControllerProvider.notifier,
                                          )
                                          .refresh();
                                      if (dialogCtx.mounted) {
                                        Navigator.of(dialogCtx).pop();
                                      }
                                    } catch (e) {
                                      setDialogState(() {
                                        submitting = false;
                                        errorMessage =
                                            'No se pudo actualizar el capital.';
                                      });
                                    }
                                  },
                            child: submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.save),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final overview = ref.watch(capitalControllerProvider).value;

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

                  // --- SECCIÓN CAPITAL ---
                  _SectionHeader(title: l10n.settingsCapitalTitle),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.settingsCapitalTotal,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: glassTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatMoney(
                                overview?.capital?.totalCapital ?? 0,
                                overview?.capital?.currency ?? 'USD',
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: glassTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _showEditCapitalDialog(context, ref),
                          icon: const Icon(LucideIcons.pencil, size: 16),
                          label: Text(
                            l10n.save == 'Guardar' ? 'Editar' : 'Edit',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- SECCIÓN ADMINISTRACIÓN ---
                  const _SectionHeader(title: 'ADMINISTRACIÓN'),
                  const SizedBox(height: 10),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push('/admin/academy-plans'),
                          icon: const Icon(LucideIcons.award, size: 18),
                          label: const Text('Gestionar Paquetes Academia'),
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
