import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import 'setup_mode.dart';

/// Wizard reutilizable de configuración de cuentas de broker.
///
/// NOTA (Fase 1): placeholder mínimo para habilitar la ruta `/setup` y el
/// gating. El PageView completo con slides (capital, broker, tipo, plan,
/// depósito, resumen, post-confirmación) se implementa en la Fase 2.
class BrokerSetupFlow extends ConsumerWidget {
  const BrokerSetupFlow({super.key, required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Configuración de broker',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Modo: ${mode.name} (wizard en construcción)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Configurar más tarde'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
