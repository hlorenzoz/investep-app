import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../domain/academy_models.dart';
import 'providers/academy_providers.dart';

/// Pantalla administrativa unificada de la Academia.
///
/// Presenta dos pestañas: Planes y Características.
/// Aplica una restricción de ancho máximo al 80% en viewports grandes (ancho >= 600).
class AdminAcademyScreen extends ConsumerWidget {
  const AdminAcademyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.graduationCap, size: 22),
                SizedBox(width: 10),
                Text('Administración de Academia'),
              ],
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Planes'),
                Tab(text: 'Características'),
              ],
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isLarge = constraints.maxWidth >= 600;
              const child = TabBarView(
                children: [
                  _AdminAcademyPlansTab(),
                  _AdminAcademyFeaturesTab(),
                ],
              );

              if (isLarge) {
                return Center(
                  child: SizedBox(
                    width: constraints.maxWidth * 0.8,
                    child: child,
                  ),
                );
              }
              return child;
            },
          ),
        ),
      ),
    );
  }
}

/// Pestaña que contiene el listado y el FAB de creación de Planes.
class _AdminAcademyPlansTab extends ConsumerWidget {
  const _AdminAcademyPlansTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final adminPlansAsync = ref.watch(adminAcademyPlansProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: adminPlansAsync.when(
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
                    'Error al cargar el catálogo admin: $err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: glassTheme.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ref
                        .read(adminAcademyPlansProvider.notifier)
                        .refresh(),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
          data: (plans) => ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _AdminPlanCard(plan: plan);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePlanDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showCreatePlanDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _CreatePlanDialog(),
    );
  }
}

/// Pestaña que contiene el listado y el FAB de creación de Características.
class _AdminAcademyFeaturesTab extends ConsumerWidget {
  const _AdminAcademyFeaturesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final adminFeaturesAsync = ref.watch(adminAcademyFeaturesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
        onPressed: () => _showCreateFeatureDialog(context),
        child: const Icon(LucideIcons.plus),
      ),
    );
  }

  void _showCreateFeatureDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _CreateFeatureDialog(),
    );
  }
}

/// Tarjeta del plan para la vista de listado.
class _AdminPlanCard extends ConsumerWidget {
  const _AdminPlanCard({required this.plan});

  final AcademyPlanAdmin plan;

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _EditPlanDialog(plan: plan),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Plan'),
        content: Text(
          '¿Estás seguro de que querés eliminar el plan "${plan.slug.toUpperCase()}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.negative),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref
                    .read(adminAcademyPlansProvider.notifier)
                    .deletePlan(plan.id);
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
    final esTranslation = plan.translations.firstWhere(
      (t) => t.locale == 'es',
      orElse: () => plan.translations.isNotEmpty
          ? plan.translations.first
          : const AcademyPlanTranslation(locale: 'es', name: ''),
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
                  Row(
                    children: [
                      Text(
                        esTranslation.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: glassTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (plan.isActive
                                  ? AppColors.positive
                                  : glassTheme.textSecondary)
                              .withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          plan.isActive ? 'Activo' : 'Inactivo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: plan.isActive
                                ? AppColors.positive
                                : glassTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (esTranslation.subtitle != null &&
                      esTranslation.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      esTranslation.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: glassTheme.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Slug: ${plan.slug}',
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: glassTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Orden: ${plan.sortOrder}',
                        style: TextStyle(
                          fontSize: 12,
                          color: glassTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Regular: \$${plan.priceRegular.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: glassTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Oferta: ${plan.priceOffer != null ? "\$${plan.priceOffer!.toStringAsFixed(0)}" : "N/A"}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.positive,
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
                  onPressed: () => _showEditDialog(context, ref),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppColors.negative),
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

/// Diálogo para editar un plan.
class _EditPlanDialog extends ConsumerStatefulWidget {
  const _EditPlanDialog({required this.plan});

  final AcademyPlanAdmin plan;

  @override
  ConsumerState<_EditPlanDialog> createState() => _EditPlanDialogState();
}

class _EditPlanDialogState extends ConsumerState<_EditPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceRegularCtrl;
  late TextEditingController _priceOfferCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _subtitleCtrl;
  late bool _isActive;
  late int _sortOrder;
  late List<int> _selectedFeatureIds;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceRegularCtrl = TextEditingController(
      text: widget.plan.priceRegular.toStringAsFixed(2),
    );
    _priceOfferCtrl = TextEditingController(
      text: widget.plan.priceOffer?.toStringAsFixed(2) ?? '',
    );

    final esTrans = widget.plan.translations.firstWhere(
      (t) => t.locale == 'es',
      orElse: () => widget.plan.translations.isNotEmpty
          ? widget.plan.translations.first
          : const AcademyPlanTranslation(locale: 'es', name: ''),
    );
    _nameCtrl = TextEditingController(text: esTrans.name);
    _subtitleCtrl = TextEditingController(text: esTrans.subtitle ?? '');
    _isActive = widget.plan.isActive;
    _sortOrder = widget.plan.sortOrder;
    _selectedFeatureIds = List<int>.from(widget.plan.featureIds);
  }

  @override
  void dispose() {
    _priceRegularCtrl.dispose();
    _priceOfferCtrl.dispose();
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final regular = double.parse(_priceRegularCtrl.text.trim());
    final offerText = _priceOfferCtrl.text.trim();
    final offer = offerText.isNotEmpty ? double.parse(offerText) : null;

    final delta = <String, dynamic>{
      'priceRegular': regular,
      'priceOffer': offer,
      'isActive': _isActive,
      'sortOrder': _sortOrder,
      'translations': [
        {
          'locale': 'es',
          'name': _nameCtrl.text.trim(),
          'subtitle': _subtitleCtrl.text.trim().isNotEmpty
              ? _subtitleCtrl.text.trim()
              : null,
        },
      ],
      'featureIds': _selectedFeatureIds,
    };

    try {
      await ref
          .read(adminAcademyPlansProvider.notifier)
          .updatePlan(widget.plan.id, delta);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(adminAcademyFeaturesProvider);

    return AlertDialog(
      title: Text('Editar ${widget.plan.slug.toUpperCase()}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (ES)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleCtrl,
                decoration: const InputDecoration(labelText: 'Subtítulo (ES)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceRegularCtrl,
                decoration: const InputDecoration(labelText: 'Precio Regular'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    v == null || double.tryParse(v) == null ? 'Inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceOfferCtrl,
                decoration: const InputDecoration(
                  labelText: 'Precio Oferta (opcional)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '$_sortOrder',
                      decoration: const InputDecoration(labelText: 'Orden'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null) _sortOrder = parsed;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activo', style: TextStyle(fontSize: 14)),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Características Asociadas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              featuresAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error al cargar características: $e'),
                data: (features) {
                  if (features.isEmpty) {
                    return const Text(
                      'No hay características globales creadas.',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                    );
                  }
                  return Column(
                    children: features.map((feature) {
                      final esTrans = feature.translations.firstWhere(
                        (t) => t.locale == 'es',
                        orElse: () => const AcademyFeatureTranslation(locale: 'es', label: ''),
                      );
                      final name = esTrans.label.isNotEmpty ? esTrans.label : feature.slug;
                      final isSelected = _selectedFeatureIds.contains(feature.id);

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(name, style: const TextStyle(fontSize: 13)),
                        subtitle: Text('Slug: ${feature.slug}', style: const TextStyle(fontSize: 11)),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedFeatureIds.add(feature.id);
                            } else {
                              _selectedFeatureIds.remove(feature.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
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

/// Diálogo para crear un plan.
class _CreatePlanDialog extends ConsumerStatefulWidget {
  const _CreatePlanDialog();

  @override
  ConsumerState<_CreatePlanDialog> createState() => _CreatePlanDialogState();
}

class _CreatePlanDialogState extends ConsumerState<_CreatePlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _slugCtrl = TextEditingController();
  final _priceRegularCtrl = TextEditingController();
  final _priceOfferCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  bool _isActive = true;
  int _sortOrder = 0;
  final List<int> _selectedFeatureIds = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _slugCtrl.dispose();
    _priceRegularCtrl.dispose();
    _priceOfferCtrl.dispose();
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final regular = double.parse(_priceRegularCtrl.text.trim());
    final offerText = _priceOfferCtrl.text.trim();
    final offer = offerText.isNotEmpty ? double.parse(offerText) : null;

    final planPayload = <String, dynamic>{
      'slug': _slugCtrl.text.trim().toLowerCase(),
      'priceRegular': regular,
      'priceOffer': offer,
      'currency': 'USD',
      'sortOrder': _sortOrder,
      'isActive': _isActive,
      'translations': [
        {
          'locale': 'es',
          'name': _nameCtrl.text.trim(),
          'subtitle': _subtitleCtrl.text.trim().isNotEmpty
              ? _subtitleCtrl.text.trim()
              : null,
        },
      ],
      'featureIds': _selectedFeatureIds,
    };

    try {
      await ref
          .read(adminAcademyPlansProvider.notifier)
          .createPlan(planPayload);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear plan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuresAsync = ref.watch(adminAcademyFeaturesProvider);

    return AlertDialog(
      title: const Text('Nuevo Plan de Membresía'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _slugCtrl,
                decoration: const InputDecoration(
                  labelText: 'Slug',
                  hintText: 'e.g. gold',
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
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre (ES)'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subtitleCtrl,
                decoration: const InputDecoration(labelText: 'Subtítulo (ES)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceRegularCtrl,
                decoration: const InputDecoration(labelText: 'Precio Regular'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) =>
                    v == null || double.tryParse(v) == null ? 'Inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceOfferCtrl,
                decoration: const InputDecoration(labelText: 'Precio Oferta (opcional)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: '$_sortOrder',
                      decoration: const InputDecoration(labelText: 'Orden'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null) _sortOrder = parsed;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activo', style: TextStyle(fontSize: 14)),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Características Asociadas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              featuresAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Text('Error al cargar características: $e'),
                data: (features) {
                  if (features.isEmpty) {
                    return const Text(
                      'No hay características globales creadas. Creá algunas primero.',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                    );
                  }
                  return Column(
                    children: features.map((feature) {
                      final esTrans = feature.translations.firstWhere(
                        (t) => t.locale == 'es',
                        orElse: () => const AcademyFeatureTranslation(locale: 'es', label: ''),
                      );
                      final name = esTrans.label.isNotEmpty ? esTrans.label : feature.slug;
                      final isSelected = _selectedFeatureIds.contains(feature.id);

                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(name, style: const TextStyle(fontSize: 13)),
                        subtitle: Text('Slug: ${feature.slug}', style: const TextStyle(fontSize: 11)),
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedFeatureIds.add(feature.id);
                            } else {
                              _selectedFeatureIds.remove(feature.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                },
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

/// Tarjeta de característica para la vista de listado.
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

/// Diálogo para crear una característica.
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

/// Diálogo para editar una característica.
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
