import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/glass/glass_card.dart';

/// Pantalla placeholder de cartera. Demuestra el lenguaje visual de la app
/// (degradado de fondo + superficies glass + iconografía Lucide nativa).
///
/// NO contiene datos reales: la carga de cartera se hará vía el cliente OpenAPI
/// contra `investep-app-api`, en solo lectura. Esto es sólo el scaffold visual.
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(LucideIcons.wallet, size: 22),
              SizedBox(width: 10),
              Text('Cartera'),
            ],
          ),
        ),
        body: const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BalanceCard(),
                SizedBox(height: 16),
                _PlaceholderCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo total agregado',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            '—',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 34,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.trendingUp, size: 16, color: AppColors.positive),
              SizedBox(width: 6),
              Text(
                'Conectá tus brókers para ver tus posiciones',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return const GlassCard(
      child: Row(
        children: [
          Icon(LucideIcons.chartPie, size: 28, color: AppColors.accentSoft),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              'Aquí irán las posiciones, órdenes y transacciones (solo lectura).',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
