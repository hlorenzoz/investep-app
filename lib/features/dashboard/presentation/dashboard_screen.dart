import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.chartPie, size: 22),
              const SizedBox(width: 10),
              Text(l10n.navDashboard),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.chartPie,
                      size: 64,
                      color: glassTheme.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.navDashboard,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: glassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esta sección está por implementar.',
                      style: TextStyle(
                        fontSize: 16,
                        color: glassTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
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
