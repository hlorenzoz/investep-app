import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';

/// Pantalla de arranque mostrada mientras el [AuthGate] valida la sesión.
///
/// - `GateChecking` → spinner.
/// - `GateRetrying503` → card de "servicio no disponible" con reintento. La
///   sesión sigue viva: NO se desloguea.
///
/// El resto de los estados los maneja el `redirect` del router (esta pantalla no
/// navega por su cuenta).
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(authGateProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: switch (gate) {
                GateRetrying503(:final message) => _RetryCard(message: message),
                _ => const _CheckingCard(),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckingCard extends StatelessWidget {
  const _CheckingCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            l10n.splashChecking,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RetryCard extends ConsumerWidget {
  const _RetryCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return GlassCard(
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Center(
            child: Icon(
              LucideIcons.serverCrash,
              color: AppColors.negative,
              size: 56,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.serviceUnavailableTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
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
            onPressed: () => ref.read(authGateProvider.notifier).retry503(),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
