import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../domain/user_admin.dart';
import 'providers/admin_users_provider.dart';
import 'widgets/user_form_dialog.dart';
import '../../../shared/widgets/app_bar_actions.dart';

/// Pantalla administrativa para la gestión de usuarios (CRUD).
///
/// Muestra un listado de usuarios con scroll y permite su creación,
/// edición y eliminación destructiva previa confirmación.
/// Aplica una restricción de ancho máximo al 80% en viewports grandes.
class UserListView extends ConsumerWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final usersAsync = ref.watch(adminUsersProvider);

    final listContent = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.users2, size: 22),
            SizedBox(width: 10),
            Text('Gestión de Usuarios'),
          ],
        ),
        actions: buildAppBarActions(context),
      ),
      body: SafeArea(
        child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.alertTriangle,
                    size: 48,
                    color: AppColors.negative,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar usuarios: $err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: glassTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(adminUsersProvider.notifier).refresh(),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (users) {
            if (users.isEmpty) {
              return Center(
                child: Text(
                  'No hay usuarios registrados.',
                  style: TextStyle(color: glassTheme.textSecondary),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.read(adminUsersProvider.notifier).refresh(),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _UserCard(user: user),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserForm(context),
        child: const Icon(LucideIcons.plus),
      ),
    );

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth >= 600;
          if (isLarge) {
            return Center(
              child: SizedBox(
                width: constraints.maxWidth * 0.8,
                child: listContent,
              ),
            );
          }
          return listContent;
        },
      ),
    );
  }

  void _showUserForm(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UserFormDialog(),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({required this.user});

  final UserAdmin user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar inicial
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : user.email[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Información del usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : 'Sin Nombre',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 13,
                    color: glassTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildRoleTag(context, user.role),
                    if (user.mustResetPassword) ...[
                      const SizedBox(width: 8),
                      _buildResetBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Botones de acción
          IconButton(
            icon: Icon(
              LucideIcons.edit3,
              color: glassTheme.textSecondary,
              size: 20,
            ),
            onPressed: () => _showEditForm(context),
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.trash2,
              color: AppColors.negative,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTag(BuildContext context, String role) {
    final Color bgColor;
    final Color textColor;
    final String label;

    switch (role.toLowerCase()) {
      case 'admin':
        bgColor = AppColors.negative.withValues(alpha: 0.15);
        textColor = AppColors.negative;
        label = 'Admin';
        break;
      case 'manager':
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        textColor = const Color(0xFFD97706);
        label = 'Manager';
        break;
      default:
        bgColor = AppColors.accent.withValues(alpha: 0.15);
        textColor = AppColors.accent;
        label = 'User';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildResetBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.keyRound, size: 10, color: Color(0xFFD97706)),
          SizedBox(width: 4),
          Text(
            'Forzar Clave',
            style: TextStyle(
              color: Color(0xFFD97706),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditForm(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            const Icon(LucideIcons.alertTriangle, color: AppColors.negative),
            const SizedBox(width: 10),
            Text(
              '¿Eliminar usuario?',
              style: TextStyle(color: glassTheme.textPrimary),
            ),
          ],
        ),
        content: Text(
          'Esta acción es destructiva e irreversible. Se eliminarán permanentemente el perfil y los accesos de ${user.email}.',
          style: TextStyle(color: glassTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: glassTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(adminUsersProvider.notifier).deleteUser(user.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Usuario eliminado exitosamente.'),
                      backgroundColor: AppColors.positive,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar usuario: $e'),
                      backgroundColor: AppColors.negative,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
