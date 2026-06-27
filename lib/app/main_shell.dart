import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/gen/app_localizations.dart';
import 'theme/app_theme.dart';

/// Contenedor de navegación responsivo y adaptativo.
///
/// Implementa un [StatefulNavigationShell] para persistir el estado de navegación
/// de cada rama (Portafolio, Academia y Configuración).
///
/// Adaptabilidad de viewports basada en buenas prácticas de diseño:
/// - Móvil (ancho < 600 dp): Muestra un [NavigationBar] inferior táctil.
/// - Tablet/Desktop (ancho >= 600 dp): Muestra un [NavigationRail] lateral izquierdo.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // Si el usuario toca la pestaña en la que ya está, recarga al primer frame de la rama.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: navigationShell,
              bottomNavigationBar: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: glassTheme.glassBorder, width: 0.5),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(LucideIcons.pieChart),
                      label: l10n.navPortfolio,
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.graduationCap),
                      label: l10n.navAcademy,
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.settings),
                      label: l10n.navSettings,
                    ),
                  ],
                ),
              ),
            );
          } else {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: glassTheme.glassBorder, width: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 28),
                        Expanded(
                          child: NavigationRail(
                            selectedIndex: navigationShell.currentIndex < 2
                                ? navigationShell.currentIndex
                                : null,
                            onDestinationSelected: _onDestinationSelected,
                            labelType: NavigationRailLabelType.all,
                            destinations: [
                              NavigationRailDestination(
                                icon: const Icon(LucideIcons.pieChart),
                                label: Text(l10n.navPortfolio),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(LucideIcons.graduationCap),
                                label: Text(l10n.navAcademy),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: NavigationRail(
                            selectedIndex: navigationShell.currentIndex == 2 ? 0 : null,
                            onDestinationSelected: (_) => _onDestinationSelected(2),
                            labelType: NavigationRailLabelType.all,
                            destinations: [
                              NavigationRailDestination(
                                icon: const Icon(LucideIcons.settings),
                                label: Text(l10n.navSettings),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: navigationShell,
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
