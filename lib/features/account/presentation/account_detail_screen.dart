import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';

/// Pantalla de detalle de una cuenta de broker (allocation).
///
/// Su propósito definitivo se definirá más adelante; por ahora el cuerpo va en
/// blanco. Lo único funcional es el botón de configuración (AppBar) que abre la
/// edición de la cuenta (`/account/:id/edit`).
///
/// Recibe el `id` (no el objeto): lee la allocation VIVA de
/// [capitalControllerProvider], así refleja siempre el último valor guardado y
/// la ruta es deep-link-safe (no depende de `extra`).
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.allocationId});

  final String allocationId;

  Allocation? _find(WidgetRef ref) {
    final overview = ref.watch(capitalControllerProvider).value;
    if (overview == null) return null;
    for (final a in overview.allocations) {
      if (a.id == allocationId) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final allocation = _find(ref);

    return Container(
      decoration: BoxDecoration(gradient: context.glass.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(allocation?.brokerSlug ?? l10n.dashboardTitle),
          actions: [
            if (allocation != null)
              IconButton(
                tooltip: l10n.editAccount,
                icon: const Icon(LucideIcons.settings),
                onPressed: () => context.push('/account/$allocationId/edit'),
              ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Text(
              l10n.accountDetailComingSoon,
              style: TextStyle(color: context.glass.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
