import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../domain/academy_models.dart';
import 'providers/academy_providers.dart';

class AdminAcademyFeaturesScreen extends ConsumerWidget {
  const AdminAcademyFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final adminFeaturesAsync = ref.watch(adminAcademyFeaturesProvider);

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.listTodo, size: 22),
              SizedBox(width: 10),
              Text('Gestión de Características'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: () =>
                  ref.read(adminAcademyFeaturesProvider.notifier).refresh(),
            ),
          ],
        ),
        body: SafeArea(
          child: adminFeaturesAsync.when(
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
                      'Error al cargar las características: $err',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: glassTheme.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref
                          .read(adminAcademyFeaturesProvider.notifier)
                          .refresh(),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
            data: (features) => ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return _AdminFeatureCard(feature: feature);
              },
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showCreateDialog(context, ref),
          child: const Icon(LucideIcons.plus),
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => const _CreateFeatureDialog(),
    );
  }
}

class _AdminFeatureCard extends ConsumerWidget {
  const _AdminFeatureCard({required this.feature});

  final AcademyFeatureAdmin feature;

  void _showEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _EditFeatureDialog(feature: feature),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Característica'),
        content: Text(
          '¿Estás seguro de que querés eliminar la característica "${feature.slug}"? Esta acción borrará todas sus traducciones y la desvinculará de los planes que la contengan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.negative,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(adminAcademyFeaturesProvider.notifier)
                    .deleteFeature(feature.id);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final esTranslation = feature.translations.firstWhere(
      (t) => t.locale == 'es',
      orElse: () => feature.translations.isNotEmpty
          ? feature.translations.first
          : const AcademyFeatureTranslation(locale: 'es', label: ''),
    );
    final enTranslation = feature.translations.firstWhere(
      (t) => t.locale == 'en',
      orElse: () => const AcademyFeatureTranslation(locale: 'en', label: ''),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    esTranslation.label.isNotEmpty
                        ? esTranslation.label
                        : feature.slug.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: glassTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EN: ${enTranslation.label.isNotEmpty ? enTranslation.label : "(sin traducir)"}',
                    style: TextStyle(
                      fontSize: 13,
                      color: glassTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Slug: ${feature.slug}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: glassTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Orden: ${feature.sortOrder}',
                        style: TextStyle(
                          fontSize: 12,
                          color: glassTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.edit3, color: AppColors.accent),
                  onPressed: () => _showEditDialog(context),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    color: AppColors.negative,
                  ),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateFeatureDialog extends ConsumerStatefulWidget {
  const _CreateFeatureDialog();

  @override
  ConsumerState<_CreateFeatureDialog> createState() =>
      _CreateFeatureDialogState();
}

class _CreateFeatureDialogState extends ConsumerState<_CreateFeatureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _slugCtrl = TextEditingController();
  final _labelEsCtrl = TextEditingController();
  final _labelEnCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController(text: '0');
  bool _isSaving = false;

  @override
  void dispose() {
    _slugCtrl.dispose();
    _labelEsCtrl.dispose();
    _labelEnCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;

    final featurePayload = <String, dynamic>{
      'slug': _slugCtrl.text.trim().toLowerCase(),
      'sortOrder': sortOrder,
      'translations': [
        {'locale': 'es', 'label': _labelEsCtrl.text.trim()},
        if (_labelEnCtrl.text.trim().isNotEmpty)
          {'locale': 'en', 'label': _labelEnCtrl.text.trim()},
      ],
    };

    try {
      await ref
          .read(adminAcademyFeaturesProvider.notifier)
          .createFeature(featurePayload);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Característica'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _slugCtrl,
                decoration: const InputDecoration(
                  labelText: 'Slug',
                  hintText: 'e.g. live_sessions',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(v)) {
                    return 'Inválido (a-z, 0-9, _, -)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelEsCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (ES)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelEnCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre (EN) - Opcional',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sortOrderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Orden de Clasificación',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null
                    ? 'Número inválido'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}

class _EditFeatureDialog extends ConsumerStatefulWidget {
  const _EditFeatureDialog({required this.feature});

  final AcademyFeatureAdmin feature;

  @override
  ConsumerState<_EditFeatureDialog> createState() => _EditFeatureDialogState();
}

class _EditFeatureDialogState extends ConsumerState<_EditFeatureDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _labelEsCtrl;
  late TextEditingController _labelEnCtrl;
  late TextEditingController _sortOrderCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final esTrans = widget.feature.translations.firstWhere(
      (t) => t.locale == 'es',
      orElse: () => const AcademyFeatureTranslation(locale: 'es', label: ''),
    );
    final enTrans = widget.feature.translations.firstWhere(
      (t) => t.locale == 'en',
      orElse: () => const AcademyFeatureTranslation(locale: 'en', label: ''),
    );
    _labelEsCtrl = TextEditingController(text: esTrans.label);
    _labelEnCtrl = TextEditingController(text: enTrans.label);
    _sortOrderCtrl = TextEditingController(text: '${widget.feature.sortOrder}');
  }

  @override
  void dispose() {
    _labelEsCtrl.dispose();
    _labelEnCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final sortOrder = int.tryParse(_sortOrderCtrl.text.trim()) ?? 0;

    final featurePayload = <String, dynamic>{
      'sortOrder': sortOrder,
      'translations': [
        {'locale': 'es', 'label': _labelEsCtrl.text.trim()},
        if (_labelEnCtrl.text.trim().isNotEmpty)
          {'locale': 'en', 'label': _labelEnCtrl.text.trim()},
      ],
    };

    try {
      await ref
          .read(adminAcademyFeaturesProvider.notifier)
          .updateFeature(widget.feature.id, featurePayload);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Feature: ${widget.feature.slug}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _labelEsCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (ES)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _labelEnCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre (EN) - Opcional',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sortOrderCtrl,
                decoration: const InputDecoration(
                  labelText: 'Orden de Clasificación',
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || int.tryParse(v) == null
                    ? 'Número inválido'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}
