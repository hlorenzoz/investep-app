import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/glass/glass_card.dart';

class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;

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
                title: 'Planes de la Academia',
                subtitle: 'Gestionar paquetes de membresía, precios y estados.',
                icon: LucideIcons.award,
                route: '/admin/academy/plans',
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: 'Características de la Academia',
                subtitle: 'Crear, editar y organizar características globales.',
                icon: LucideIcons.listTodo,
                route: '/admin/academy/features',
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: 'Gestión de Usuarios',
                subtitle: 'Visualizar perfiles de usuario y roles.',
                icon: LucideIcons.users2,
                route: null,
                enabled: false,
              ),
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
                  color: (enabled
                          ? Theme.of(context).colorScheme.secondary
                          : glassTheme.textSecondary)
                      .withOpacity(0.15),
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
