import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../brokers/data/broker_repository.dart';
import '../../brokers/domain/broker.dart';
import '../../brokers/presentation/broker_logo.dart';
import '../../brokers/presentation/brokers_provider.dart';

/// Pantalla administrativa para la gestión (CRUD) de brokers.
///
/// Muestra un listado de brokers con scroll, permitiendo su creación,
/// edición y eliminación destructiva previa confirmación.
/// Aplica una restricción de ancho máximo al 80% en viewports grandes.
class AdminBrokersScreen extends ConsumerWidget {
  const AdminBrokersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final brokersAsync = ref.watch(brokersProvider);

    final listContent = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.building2, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gestión de Brókers',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: buildAppBarActions(context),
      ),
      body: SafeArea(
        child: brokersAsync.when(
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
                    'Error al cargar brókers: $err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: glassTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(brokersProvider),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (brokers) {
            if (brokers.isEmpty) {
              return Center(
                child: Text(
                  'No hay brókers registrados.',
                  style: TextStyle(color: glassTheme.textSecondary),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(brokersProvider),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: brokers.length,
                itemBuilder: (context, index) {
                  final broker = brokers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BrokerCard(broker: broker),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBrokerForm(context, ref),
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

  void _showBrokerForm(BuildContext context, WidgetRef ref, {Broker? broker}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BrokerFormDialog(broker: broker),
    ).then((_) {
      // Forzar recarga de los brokers al cerrar el diálogo
      ref.invalidate(brokersProvider);
    });
  }
}

class _BrokerCard extends ConsumerWidget {
  const _BrokerCard({required this.broker});

  final Broker broker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
            ),
            child: Center(child: BrokerLogo(broker: broker, size: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  broker.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Slug: ${broker.slug}',
                  style: TextStyle(
                    fontSize: 12,
                    color: glassTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
                if (broker.url != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    broker.url!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              LucideIcons.edit3,
              color: glassTheme.textSecondary,
              size: 20,
            ),
            onPressed: () {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (context) => _BrokerFormDialog(broker: broker),
              ).then((_) {
                ref.invalidate(brokersProvider);
              });
            },
            tooltip: 'Editar Bróker',
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.trash2,
              color: AppColors.negative,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Eliminar Bróker',
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.glass.glassFill,
        title: Text(
          'Eliminar Bróker',
          style: TextStyle(color: context.glass.textPrimary),
        ),
        content: Text(
          '¿Estás seguro de que querés eliminar a ${broker.name}? '
          'Esta acción es destructiva y fallará si hay asignaciones activas.',
          style: TextStyle(color: context.glass.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: context.glass.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(brokerRepositoryProvider)
                    .deleteBroker(broker.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bróker eliminado con éxito.'),
                      backgroundColor: AppColors.positive,
                    ),
                  );
                }
                ref.invalidate(brokersProvider);
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar bróker: ${e.message}'),
                      backgroundColor: AppColors.negative,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ocurrió un error inesperado: $e'),
                      backgroundColor: AppColors.negative,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerFormDialog extends ConsumerStatefulWidget {
  const _BrokerFormDialog({this.broker});

  final Broker? broker;

  @override
  ConsumerState<_BrokerFormDialog> createState() => _BrokerFormDialogState();
}

class _BrokerFormDialogState extends ConsumerState<_BrokerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _slugController = TextEditingController();
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _urlSecondaryController = TextEditingController();
  final _logoController = TextEditingController();
  final _iconController = TextEditingController();
  final _faviconController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.broker != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final b = widget.broker!;
      _slugController.text = b.slug;
      _nameController.text = b.name;
      _urlController.text = b.url ?? '';
      _urlSecondaryController.text = b.urlSecondary ?? '';
      _logoController.text = b.logo ?? '';
      _iconController.text = b.icon ?? '';
      _faviconController.text = b.favicon ?? '';
    }

    // Agregar listeners para actualizar la previsualización del logo en tiempo real.
    _logoController.addListener(_onPreviewFieldsChanged);
    _iconController.addListener(_onPreviewFieldsChanged);
    _faviconController.addListener(_onPreviewFieldsChanged);
  }

  void _onPreviewFieldsChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _logoController.removeListener(_onPreviewFieldsChanged);
    _iconController.removeListener(_onPreviewFieldsChanged);
    _faviconController.removeListener(_onPreviewFieldsChanged);

    _slugController.dispose();
    _nameController.dispose();
    _urlController.dispose();
    _urlSecondaryController.dispose();
    _logoController.dispose();
    _iconController.dispose();
    _faviconController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = <String, dynamic>{
      'slug': _slugController.text.trim(),
      'name': _nameController.text.trim(),
      'url': _urlController.text.trim(),
      'urlSecondary': _urlSecondaryController.text.trim().isEmpty
          ? null
          : _urlSecondaryController.text.trim(),
      'logo': _logoController.text.trim().isEmpty
          ? null
          : _logoController.text.trim(),
      'icon': _iconController.text.trim().isEmpty
          ? null
          : _iconController.text.trim(),
      'favicon': _faviconController.text.trim().isEmpty
          ? null
          : _faviconController.text.trim(),
    };

    try {
      if (_isEditing) {
        await ref
            .read(brokerRepositoryProvider)
            .updateBroker(widget.broker!.id, data);
      } else {
        await ref.read(brokerRepositoryProvider).createBroker(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Bróker actualizado con éxito.'
                  : 'Bróker creado con éxito.',
            ),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    final width = MediaQuery.of(context).size.width;
    final isLarge = width >= 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SizedBox(
        width: isLarge ? width * 0.8 : null,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      _isEditing ? LucideIcons.edit3 : LucideIcons.plusCircle,
                      color: Theme.of(context).colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isEditing ? 'Editar Bróker' : 'Crear Bróker',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: glassTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.negative.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.negative.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          color: AppColors.negative,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.negative,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      TextFormField(
                        controller: _slugController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Slug',
                          labelStyle: TextStyle(
                            color: glassTheme.textSecondary,
                          ),
                          hintText: 'ej. interactive-brokers',
                          hintStyle: TextStyle(
                            color: glassTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: glassTheme.textPrimary),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El slug es requerido.';
                          }
                          final regExp = RegExp(r'^[a-z0-9_-]+$');
                          if (!regExp.hasMatch(value.trim())) {
                            return 'Solo minúsculas, números, guiones y guiones bajos.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          labelStyle: TextStyle(
                            color: glassTheme.textSecondary,
                          ),
                          hintText: 'ej. Interactive Brokers',
                          hintStyle: TextStyle(
                            color: glassTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: glassTheme.textPrimary),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _urlController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'URL Principal',
                          labelStyle: TextStyle(
                            color: glassTheme.textSecondary,
                          ),
                          hintText: 'https://...',
                          hintStyle: TextStyle(
                            color: glassTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: glassTheme.textPrimary),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La URL principal es requerida.';
                          }
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null ||
                              !uri.hasScheme ||
                              !uri.hasAuthority ||
                              (uri.scheme != 'http' && uri.scheme != 'https')) {
                            return 'Ingresá una URL válida (con http o https).';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _urlSecondaryController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'URL Secundaria (Opcional)',
                          labelStyle: TextStyle(
                            color: glassTheme.textSecondary,
                          ),
                          hintText: 'https://...',
                          hintStyle: TextStyle(
                            color: glassTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: glassTheme.textPrimary),
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final uri = Uri.tryParse(value.trim());
                            if (uri == null ||
                                !uri.hasScheme ||
                                !uri.hasAuthority ||
                                (uri.scheme != 'http' &&
                                    uri.scheme != 'https')) {
                              return 'Ingresá una URL válida (con http o https).';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _logoController,
                        enabled: !_isLoading,
                        maxLines: 3,
                        minLines: 1,
                        decoration: InputDecoration(
                          labelText: 'Logo (URL, data URI o SVG crudo)',
                          labelStyle: TextStyle(
                            color: glassTheme.textSecondary,
                          ),
                          hintText: 'https://... o <svg>...',
                          hintStyle: TextStyle(
                            color: glassTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: glassTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _iconController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Icono (Opcional)',
                          labelStyle: TextStyle(
                            color: glassTheme.textSecondary,
                          ),
                          hintText: 'https://...',
                          hintStyle: TextStyle(
                            color: glassTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: glassTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _faviconController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Favicon (Opcional)',
                          labelStyle: TextStyle(
                            color: glassTheme.textSecondary,
                          ),
                          hintText: 'https://...',
                          hintStyle: TextStyle(
                            color: glassTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                        style: TextStyle(color: glassTheme.textPrimary),
                      ),
                      const SizedBox(height: 20),
                      // Previsualización dinámica
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            BrokerLogo(
                              broker: Broker(
                                id: 0,
                                slug: _slugController.text,
                                name: _nameController.text,
                                logo: _logoController.text.trim().isNotEmpty
                                    ? _logoController.text.trim()
                                    : null,
                                icon: _iconController.text.trim().isNotEmpty
                                    ? _iconController.text.trim()
                                    : null,
                                favicon:
                                    _faviconController.text.trim().isNotEmpty
                                    ? _faviconController.text.trim()
                                    : null,
                              ),
                              size: 36,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Previsualización en tiempo real del logo/icono.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: glassTheme.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: glassTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isEditing ? 'Guardar Cambios' : 'Crear Bróker',
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
