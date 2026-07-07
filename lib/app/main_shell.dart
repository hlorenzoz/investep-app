import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/auth/auth_gate.dart';
import '../core/providers/supabase_provider.dart';
import '../l10n/gen/app_localizations.dart';
import '../shared/widgets/glass/glass_card.dart';
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

    // Índices de rama (StatefulShellRoute):
    //   0 Dashboard · 1 Portafolio · 2 Academia · 3 Relaciones · 4 Tienda · 5 Libros (Books) · 6 Admin · 7 Configuración
    // Admin (rama 6) se oculta si el usuario no es admin/manager, por eso el
    // mapeo entre índices de UI e índices de rama es manual.

    int mobileSelectedIndex() {
      final currentBranch = navigationShell.currentIndex;
      if (currentBranch == 0) return 0;
      if (currentBranch == 1) return 1;
      return 2;
    }

    void onMobileDestinationSelected(int uiIndex) {
      if (uiIndex == 0) {
        navigationShell.goBranch(
          0,
          initialLocation: 0 == navigationShell.currentIndex,
        );
      } else if (uiIndex == 1) {
        navigationShell.goBranch(
          1,
          initialLocation: 1 == navigationShell.currentIndex,
        );
      } else if (uiIndex == 2) {
        _showMobileMenu(context, ref, navigationShell, isAdminOrManager);
      }
    }

    // No bottomRailSelectedIndex/onBottomRailSelected needed, handled directly via _RailButton below.

    int? railSelectedIndex() {
      final currentBranch = navigationShell.currentIndex;
      return switch (currentBranch) {
        0 => 0,
        1 => 1,
        3 => 2,
        4 => 3,
        5 => 4,
        _ => null,
      };
    }

    void onRailDestinationSelected(int uiIndex) {
      final targetBranch = switch (uiIndex) {
        0 => 0,
        1 => 1,
        2 => 3,
        3 => 4,
        4 => 5,
        _ => 0,
      };
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
                  selectedIndex: mobileSelectedIndex(),
                  onDestinationSelected: onMobileDestinationSelected,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(LucideIcons.chartPie),
                      label: l10n.navDashboard,
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.chartCandlestick),
                      label: l10n.navPortfolio,
                    ),
                    NavigationDestination(
                      icon: const Icon(LucideIcons.menu),
                      label: l10n.navMenu,
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
                            selectedIndex: railSelectedIndex(),
                            onDestinationSelected: onRailDestinationSelected,
                            labelType: NavigationRailLabelType.all,
                            destinations: [
                              NavigationRailDestination(
                                icon: const Icon(LucideIcons.chartPie),
                                label: Text(l10n.navDashboard),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(LucideIcons.chartCandlestick),
                                label: Text(l10n.navPortfolio),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(LucideIcons.waypoints),
                                label: Text(l10n.navRelations),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(LucideIcons.shoppingBag),
                                label: Text(l10n.navStore),
                              ),
                              NavigationRailDestination(
                                icon: const Icon(LucideIcons.library),
                                label: Text(l10n.navBooks),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdminOrManager) ...[
                                _RailButton(
                                  icon: LucideIcons.shieldAlert,
                                  label: l10n.navAdmin,
                                  isSelected: navigationShell.currentIndex == 6,
                                  onTap: () => navigationShell.goBranch(
                                    6,
                                    initialLocation:
                                        6 == navigationShell.currentIndex,
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                              _RailButton(
                                icon: LucideIcons.settings,
                                label: l10n.navSettings,
                                isSelected: navigationShell.currentIndex == 7,
                                onTap: () => navigationShell.goBranch(
                                  7,
                                  initialLocation:
                                      7 == navigationShell.currentIndex,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const _LogoutButton(),
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

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    return InkWell(
      onTap: () => _showSignOutDialog(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.logOut, color: glassTheme.negative, size: 24),
            const SizedBox(height: 4),
            Text(
              l10n.settingsSignOut,
              style: TextStyle(
                color: glassTheme.negative,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = context.glass;
    final color = isSelected
        ? (theme.navigationRailTheme.selectedIconTheme?.color ??
              theme.colorScheme.primary)
        : (theme.navigationRailTheme.unselectedIconTheme?.color ??
              glassTheme.textSecondary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void _showMobileMenu(
  BuildContext context,
  WidgetRef ref,
  StatefulNavigationShell navigationShell,
  bool isAdminOrManager,
) {
  final l10n = AppLocalizations.of(context);
  final currentBranch = navigationShell.currentIndex;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'MobileMenu',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 250),
    transitionBuilder: (ctx, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutQuad)),
          child: child,
        ),
      );
    },
    pageBuilder: (ctx, anim1, anim2) {
      final isWide = MediaQuery.of(ctx).size.width >= 600;
      if (isWide) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ctx.mounted) {
            Navigator.of(ctx).pop();
          }
        });
      }

      final paddingBottom = MediaQuery.of(ctx).padding.bottom;
      final bottomInset = 80.0 + paddingBottom + 8;

      return Stack(
        children: [
          Positioned(
            right: 16,
            bottom: bottomInset,
            child: Material(
              color: Colors.transparent,
              child: GlassCard(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: SizedBox(
                  width: 220,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _MobileMenuItem(
                        icon: LucideIcons.waypoints,
                        label: l10n.navRelations,
                        isSelected: currentBranch == 3,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          navigationShell.goBranch(
                            3,
                            initialLocation: 3 == currentBranch,
                          );
                        },
                      ),
                      _MobileMenuItem(
                        icon: LucideIcons.shoppingBag,
                        label: l10n.navStore,
                        isSelected: currentBranch == 4,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          navigationShell.goBranch(
                            4,
                            initialLocation: 4 == currentBranch,
                          );
                        },
                      ),
                      _MobileMenuItem(
                        icon: LucideIcons.library,
                        label: l10n.navBooks,
                        isSelected: currentBranch == 5,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          navigationShell.goBranch(
                            5,
                            initialLocation: 5 == currentBranch,
                          );
                        },
                      ),
                      if (isAdminOrManager)
                        _MobileMenuItem(
                          icon: LucideIcons.shieldAlert,
                          label: l10n.navAdmin,
                          isSelected: currentBranch == 6,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            navigationShell.goBranch(
                              6,
                              initialLocation: 6 == currentBranch,
                            );
                          },
                        ),
                      _MobileMenuItem(
                        icon: LucideIcons.settings,
                        label: l10n.navSettings,
                        isSelected: currentBranch == 7,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          navigationShell.goBranch(
                            7,
                            initialLocation: 7 == currentBranch,
                          );
                        },
                      ),
                      const Divider(height: 16, thickness: 0.5),
                      _MobileMenuItem(
                        icon: LucideIcons.logOut,
                        label: l10n.settingsSignOut,
                        isSelected: false,
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _showSignOutDialog(context, ref);
                        },
                        isNegative: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _MobileMenuItem extends StatelessWidget {
  const _MobileMenuItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isNegative = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = context.glass;

    final color = isNegative
        ? glassTheme.negative
        : (isSelected
              ? (theme.navigationBarTheme.iconTheme?.resolve({
                      WidgetState.selected,
                    })?.color ??
                    theme.colorScheme.primary)
              : glassTheme.textSecondary);

    final textColor = isNegative
        ? glassTheme.negative
        : (isSelected
              ? (theme.navigationBarTheme.iconTheme?.resolve({
                      WidgetState.selected,
                    })?.color ??
                    theme.colorScheme.primary)
              : glassTheme.textPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
