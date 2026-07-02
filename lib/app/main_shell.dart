import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/auth/auth_gate.dart';
import '../l10n/gen/app_localizations.dart';
import 'theme/app_theme.dart';

/// Contenedor de navegación responsivo y adaptativo.
///
/// Implementa un [StatefulNavigationShell] para persistir el estado de navegación
/// de cada rama (Portafolio, Academia, Administración y Configuración).
///
/// Adaptabilidad de viewports basada en buenas prácticas de diseño:
/// - Móvil (ancho < 600 dp): Muestra un [NavigationBar] inferior táctil.
/// - Tablet/Desktop (ancho >= 600 dp): Muestra un [NavigationRail] lateral izquierdo.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    // Verificar si el usuario actual es admin o manager para mostrar/ocultar la pestaña Admin.
    final gate = ref.watch(authGateProvider);
    final role = gate is GateAuthenticated ? gate.user.role : 'user';
    final isAdminOrManager = role == 'admin' || role == 'manager';

    // Mapeo para NavigationBar (Móvil)
    int branchToUiIndex(int branchIndex) {
      if (isAdminOrManager) return branchIndex;
      if (branchIndex >= 3) return branchIndex - 1;
      return branchIndex;
    }

    void onDestinationSelected(int uiIndex) {
      int branchIndex = uiIndex;
      if (!isAdminOrManager) {
        if (uiIndex >= 2) {
          branchIndex = uiIndex + 1;
        }
      }
      navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
    }

    // Mapeo para bottom NavigationRail (Tablet/Desktop)
    final int? bottomRailSelectedIndex;
    if (isAdminOrManager) {
      bottomRailSelectedIndex = navigationShell.currentIndex >= 2
          ? navigationShell.currentIndex - 2
          : null;
    } else {
      bottomRailSelectedIndex = navigationShell.currentIndex == 3 ? 0 : null;
    }

    void onBottomRailSelected(int uiIndex) {
      final int targetBranch;
      if (isAdminOrManager) {
        targetBranch = uiIndex + 2;
      } else {
        targetBranch = 3; // Solo Configuración está disponible
      }
      navigationShell.goBranch(
        targetBranch,
        initialLocation: targetBranch == navigationShell.currentIndex,
      );
    }

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
                  selectedIndex: branchToUiIndex(navigationShell.currentIndex),
                  onDestinationSelected: onDestinationSelected,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(LucideIcons.pieChart),
                      label: l10n.navPortfolio,
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.graduationCap),
                      label: l10n.navAcademy,
                    ),
                    if (isAdminOrManager)
                      NavigationDestination(
                        icon: const Icon(LucideIcons.shieldAlert),
                        label: l10n.navAdmin,
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
                        right: BorderSide(
                          color: glassTheme.glassBorder,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Image.asset(
                          'web/investep/favicon.webp',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: NavigationRail(
                            selectedIndex: navigationShell.currentIndex < 2
                                ? navigationShell.currentIndex
                                : null,
                            onDestinationSelected: (idx) {
                              navigationShell.goBranch(
                                idx,
                                initialLocation:
                                    idx == navigationShell.currentIndex,
                              );
                            },
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
                            selectedIndex: bottomRailSelectedIndex,
                            onDestinationSelected: onBottomRailSelected,
                            labelType: NavigationRailLabelType.all,
                            destinations: [
                              if (isAdminOrManager)
                                NavigationRailDestination(
                                  icon: const Icon(LucideIcons.shieldAlert),
                                  label: Text(l10n.navAdmin),
                                ),
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
                  Expanded(child: navigationShell),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
