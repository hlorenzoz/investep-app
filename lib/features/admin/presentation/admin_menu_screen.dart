import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../shared/widgets/glass/glass_card.dart';

class AdminMenuScreen extends ConsumerWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;

    // Obtener rol del usuario actual.
    final gate = ref.watch(authGateProvider);
    final role = gate is GateAuthenticated ? gate.user.role : 'user';
    final isAdmin = role == 'admin';

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.shieldAlert, size: 22),
              SizedBox(width: 10),
              Text('Panel de Administración'),
            ],
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _buildMenuCard(
                context,
                title: 'Academia',
                subtitle:
                    'Gestionar paquetes de membresía, precios y características globales.',
                icon: LucideIcons.graduationCap,
                route: '/admin/academy',
              ),
              if (isAdmin) ...[
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  title: 'Gestión de Usuarios',
                  subtitle:
                      'Visualizar perfiles de usuario, roles y aprovisionar.',
                  icon: LucideIcons.users2,
                  route: '/admin/users',
                  enabled: true,
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  title: 'Configuración de Brókers',
                  subtitle: 'Gestionar el catálogo de brókers del sistema.',
                  icon: LucideIcons.building2,
                  route: '/admin/brokers',
                  enabled: true,
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  title: 'Configuración de Activos (Tickers)',
                  subtitle:
                      'Gestionar el catálogo de activos del sistema y sus relaciones.',
                  icon: LucideIcons.candlestickChart,
                  route: '/admin/tickers',
                  enabled: true,
                ),
              ],
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: 'Configuración Global',
                subtitle: 'Configuración general del sistema y métricas.',
                icon: LucideIcons.sliders,
                route: null,
                enabled: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String? route,
    bool enabled = true,
  }) {
    final glassTheme = context.glass;

    return InkWell(
      onTap: enabled && route != null ? () => context.push(route) : null,
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (enabled
                              ? Theme.of(context).colorScheme.secondary
                              : glassTheme.textSecondary)
                          .withValues(alpha: 0.15),
                ),
                child: Icon(
                  icon,
                  color: enabled
                      ? Theme.of(context).colorScheme.secondary
                      : glassTheme.textSecondary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: glassTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: glassTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (enabled)
                Icon(
                  LucideIcons.chevronRight,
                  color: glassTheme.textSecondary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
