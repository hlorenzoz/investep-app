import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/tickers/presentation/favorites_controller.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../app/theme/app_theme.dart';

/// Estrella de favorito reutilizable en todas las superficies (relaciones,
/// chips x2/x3/inverso y tiles de la sección Favoritos).
///
/// El estado efectivo sale del overlay optimista (`favoritesOverrideProvider`)
/// por encima del `isFavorite` base del dato, así el toggle se refleja al
/// instante en cualquier lugar donde aparezca el mismo símbolo.
class FavoriteStarButton extends ConsumerWidget {
  const FavoriteStarButton({
    super.key,
    required this.symbol,
    required this.isFavorite,
    this.size = 20,
  });

  /// Símbolo del activo (se normaliza a mayúsculas en el server).
  final String symbol;

  /// Valor base del dato (relations-overview / ticker). El overlay tiene prioridad.
  final bool isFavorite;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final override = ref.watch(favoritesOverrideProvider);
    final effective = override[symbol] ?? isFavorite;
    final glassTheme = context.glass;

    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size + 16, height: size + 16),
      iconSize: size,
      tooltip: symbol,
      icon: Icon(
        effective ? Icons.star_rounded : Icons.star_border_rounded,
        color: effective ? const Color(0xFFFFC107) : glassTheme.textSecondary,
      ),
      onPressed: () => _toggle(context, ref, effective),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool current,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(favoritesOverrideProvider.notifier)
          .toggle(symbol, !current);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.favoriteError)));
    }
  }
}
