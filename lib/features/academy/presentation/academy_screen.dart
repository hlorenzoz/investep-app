import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../domain/academy_models.dart';
import 'providers/academy_providers.dart';

class AcademyScreen extends ConsumerWidget {
  const AcademyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final plansAsync = ref.watch(academyPlansProvider);

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.graduationCap, size: 22),
              const SizedBox(width: 10),
              Text(l10n.navAcademy),
            ],
          ),
        ),
        body: SafeArea(
          child: plansAsync.when(
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
                      'No se pudieron cargar los paquetes de la Academia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: glassTheme.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => ref.invalidate(academyPlansProvider),
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
            data: (plans) => _AcademyContent(plans: plans),
          ),
        ),
      ),
    );
  }
}

class _AcademyContent extends StatelessWidget {
  const _AcademyContent({required this.plans});

  final List<AcademyPlan> plans;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner Promocional Superior
          const _PromotionalHeader(),
          const SizedBox(height: 32),

          // Matriz de Paquetes
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 900) {
                return _DesktopPlanGrid(plans: plans);
              } else {
                return _MobilePlanList(plans: plans);
              }
            },
          ),
          const SizedBox(height: 40),

          // Footer informativo / Garantía
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.shieldCheck,
                  size: 36,
                  color: AppColors.positive,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Acceso de Por Vida y Soporte Exclusivo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: glassTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Todos los paquetes de Investep Academy incluyen acceso ilimitado a nuestra plataforma de estudio y comunidad.',
                        style: TextStyle(
                          fontSize: 13,
                          color: glassTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromotionalHeader extends StatelessWidget {
  const _PromotionalHeader();

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.negative.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.negative.withOpacity(0.5),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      LucideIcons.flame,
                      size: 16,
                      color: AppColors.negative,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'OFERTA ESPECIAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.negative,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'SEMINARIO INTENSIVO APRENDIENDO A INVERTIR',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: glassTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Elegí el paquete que mejor se adapte a tus metas de inversión',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: glassTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DesktopPlanGrid extends StatelessWidget {
  const _DesktopPlanGrid({required this.plans});

  final List<AcademyPlan> plans;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: plans.map((plan) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _PlanCard(plan: plan),
          ),
        );
      }).toList(),
    );
  }
}

class _MobilePlanList extends StatelessWidget {
  const _MobilePlanList({required this.plans});

  final List<AcademyPlan> plans;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: plans.map((plan) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _PlanCard(plan: plan),
        );
      }).toList(),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final AcademyPlan plan;

  Color _getBadgeColor() {
    switch (plan.slug.toLowerCase()) {
      case 'bronze':
      case 'bronce':
        return const Color(0xFFCD7F32);
      case 'silver':
      case 'plata':
        return const Color(0xFFC0C0C0);
      case 'gold':
      case 'oro':
        return const Color(0xFFFFD700);
      case 'platinum':
      case 'platino':
        return const Color(0xFFE5E4E2);
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    final badgeColor = _getBadgeColor();
    final isPopular =
        plan.slug.toLowerCase() == 'gold' || plan.slug.toLowerCase() == 'oro';

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPopular)
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.positive.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.positive.withOpacity(0.5),
                  ),
                ),
                child: const Text(
                  'MÁS POPULAR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.positive,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),

          // Medal / Icon & Title
          Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: badgeColor.withOpacity(0.15),
                border: Border.all(color: badgeColor, width: 2),
              ),
              child: Icon(LucideIcons.award, size: 28, color: badgeColor),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            plan.name ?? plan.slug.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: glassTheme.textPrimary,
            ),
          ),
          if (plan.subtitle != null && plan.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              plan.subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Pricing Block
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'Precio regular: \$${plan.priceRegular.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 12,
                    decoration: TextDecoration.lineThrough,
                    color: glassTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '\$${(plan.priceOffer ?? plan.priceRegular).toStringAsFixed(0)} ${plan.currency}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.positive,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Divider(height: 1),
          const SizedBox(height: 16),

          // Features List
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.checkCircle2,
                      size: 16,
                      color: AppColors.positive,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature.label ?? feature.slug,
                      style: TextStyle(
                        fontSize: 13,
                        color: glassTheme.textPrimary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          _SubscribeButton(plan: plan, isPopular: isPopular),
        ],
      ),
    );
  }
}

class _SubscribeButton extends StatefulWidget {
  const _SubscribeButton({required this.plan, required this.isPopular});

  final AcademyPlan plan;
  final bool isPopular;

  @override
  State<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<_SubscribeButton> {
  bool _isLoading = false;

  Future<void> _handleSubscription() async {
    final urlStr = widget.plan.url;

    if (urlStr == null || urlStr.trim().isEmpty) {
      await _showFallbackDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uri = Uri.parse(urlStr.trim());
      if (await canLaunchUrl(uri)) {
        final success = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!success && mounted) {
          _showErrorSnackBar('No se pudo abrir el enlace de suscripción.');
        }
      } else if (mounted) {
        _showErrorSnackBar(
          'El enlace de suscripción no es válido o no se puede abrir.',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ocurrió un error al intentar abrir el enlace.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.negative),
    );
  }

  Future<void> _showFallbackDialog() async {
    final glassTheme = context.glass;
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: glassTheme.glassFill.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: glassTheme.glassBorder.withValues(alpha: 0.2),
            ),
          ),
          title: Text(
            'Inscripción de forma directa',
            style: TextStyle(
              color: glassTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Este paquete requiere inscripción directa con nuestro soporte. Por favor, comunícate con nosotros para brindarte asistencia inmediata.',
            style: TextStyle(color: glassTheme.textSecondary),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSubscription,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: widget.isPopular ? AppColors.accent : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text('Inscribirme Ahora'),
    );
  }
}
