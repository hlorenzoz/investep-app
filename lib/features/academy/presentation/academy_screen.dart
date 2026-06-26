import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';

/// Pantalla placeholder de la Academia (Investep Academy).
class AcademyScreen extends StatelessWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final glassTheme = context.glass;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.graduationCap, size: 22),
              const SizedBox(width: 10),
              Text(l10n.navAcademy),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 36,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        LucideIcons.graduationCap,
                        size: 64,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Investep Academy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: glassTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.academyComingSoon,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: glassTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
