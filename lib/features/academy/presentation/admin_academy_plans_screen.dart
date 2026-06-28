import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../domain/academy_models.dart';
import 'providers/academy_providers.dart';

class AdminAcademyPlansScreen extends ConsumerWidget {
  const AdminAcademyPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final adminPlansAsync = ref.watch(adminAcademyPlansProvider);

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.settings, size: 22),
              SizedBox(width: 10),
              Text('Gestión de Paquetes Academia'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: () =>
                  ref.read(adminAcademyPlansProvider.notifier).refresh(),
            ),
          ],
        ),
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
      ),
    );
  }
}

class _AdminPlanCard extends ConsumerWidget {
  const _AdminPlanCard({required this.plan});

  final AcademyPlanAdmin plan;

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _EditPlanDialog(plan: plan),
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
                        esTranslation.name.isNotEmpty
                            ? esTranslation.name
                            : plan.slug.toUpperCase(),
                        style: TextStyle(
                          fontSize: 18,
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
                          color: plan.isActive
                              ? AppColors.positive.withOpacity(0.2)
                              : AppColors.negative.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plan.isActive ? 'ACTIVO' : 'INACTIVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: plan.isActive
                                ? AppColors.positive
                                : AppColors.negative,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (esTranslation.subtitle != null) ...[
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
            IconButton(
              icon: const Icon(LucideIcons.edit3, color: AppColors.accent),
              onPressed: () => _showEditDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return AlertDialog(
      title: Text('Editar ${widget.plan.slug.toUpperCase()}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              SwitchListTile(
                title: const Text('Activo'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
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
