import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/responsive/breakpoints.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../capital/presentation/capital_controller.dart';
import 'setup_deferred_provider.dart';
import 'setup_mode.dart';
import 'slides/account_type_slide.dart';
import 'slides/broker_slide.dart';
import 'slides/capital_slide.dart';
import 'slides/deposit_slide.dart';
import 'slides/plan_slide.dart';
import 'slides/summary_slide.dart';
import 'wizard_controller.dart';

/// Wizard reutilizable de configuración de cuentas de broker.
///
/// Mismo widget en ambos modos ([SetupMode]); `initialSetup` incluye el slide de
/// capital, `addBroker` lo omite. Móvil: pantalla completa. Tablet/desktop: card
/// centrado (máx 520px). Transiciones horizontales + swipe + "Configurar más
/// tarde" persistente.
class BrokerSetupFlow extends ConsumerWidget {
  const BrokerSetupFlow({super.key, required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shell = _WizardShell(mode: mode);

    return Container(
      decoration: BoxDecoration(gradient: context.glass.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: context.isMobile
              ? shell
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: Breakpoints.maxContentWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GlassCard(child: shell),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _WizardShell extends ConsumerWidget {
  const _WizardShell({required this.mode});

  final SetupMode mode;

  int get _minSlide =>
      mode == SetupMode.initialSetup ? WizardSlide.capital : WizardSlide.broker;

  bool _canAdvance(WizardState state, num available) {
    final d = state.data;
    return switch (state.slideIndex) {
      WizardSlide.capital => (d.totalCapital ?? 0) > 0,
      WizardSlide.broker => d.brokerId != null,
      WizardSlide.accountType => d.accountType != null,
      WizardSlide.plan => d.investmentPlanId != null,
      WizardSlide.deposit => d.depositIsValid(available),
      WizardSlide.summary => true,
      _ => false,
    };
  }

  void _onNext(WizardController controller, int slideIndex) {
    switch (slideIndex) {
      case WizardSlide.capital:
        controller.submitCapital();
      case WizardSlide.summary:
        controller.submitAllocation();
      default:
        controller.next();
    }
  }

  Widget _slideFor(int i) => switch (i) {
    WizardSlide.capital => CapitalSlide(mode: mode),
    WizardSlide.broker => BrokerSlide(mode: mode),
    WizardSlide.accountType => AccountTypeSlide(mode: mode),
    WizardSlide.plan => PlanSlide(mode: mode),
    WizardSlide.deposit => DepositSlide(mode: mode),
    _ => SummarySlide(mode: mode),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Al completarse la allocation, cerramos el wizard y volvemos al dashboard.
    ref.listen(wizardControllerProvider(mode), (prev, next) {
      if (next is WizardCompleted) context.go('/');
    });

    final state = ref.watch(wizardControllerProvider(mode));
    final controller = ref.read(wizardControllerProvider(mode).notifier);
    final available =
        ref.watch(capitalControllerProvider).value?.available ??
        state.data.totalCapital ??
        0;

    final isSubmitting = state is WizardSubmitting;
    final canAdvance = !isSubmitting && _canAdvance(state, available);

    void swipe(DragEndDetails d) {
      final v = d.primaryVelocity ?? 0;
      if (v < 0 && canAdvance) {
        _onNext(controller, state.slideIndex);
      } else if (v > 0 && state.slideIndex > _minSlide) {
        controller.back();
      }
    }

    void setupLater() {
      // En initialSetup, posponer deja un banner en el dashboard.
      if (mode == SetupMode.initialSetup) {
        ref.read(setupDeferredProvider.notifier).markDeferred();
      }
      context.go('/');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Progress(
            current: state.slideIndex - _minSlide,
            total: WizardSlide.summary - _minSlide + 1,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onHorizontalDragEnd: swipe,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.12, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: KeyedSubtree(
                key: ValueKey(state.slideIndex),
                child: _slideFor(state.slideIndex),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _Footer(
            state: state,
            controller: controller,
            minSlide: _minSlide,
            canAdvance: canAdvance,
            isSubmitting: isSubmitting,
            onNext: () => _onNext(controller, state.slideIndex),
            onSetupLater: setupLater,
          ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == current ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= current ? AppColors.accent : AppColors.glassBorder,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.state,
    required this.controller,
    required this.minSlide,
    required this.canAdvance,
    required this.isSubmitting,
    required this.onNext,
    required this.onSetupLater,
  });

  final WizardState state;
  final WizardController controller;
  final int minSlide;
  final bool canAdvance;
  final bool isSubmitting;
  final VoidCallback onNext;
  final VoidCallback onSetupLater;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final showBack = state.slideIndex > minSlide;
    final isSummary = state.slideIndex == WizardSlide.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (showBack) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : controller.back,
                  child: Text(l10n.back),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ElevatedButton(
                onPressed: canAdvance ? onNext : null,
                child: isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isSummary ? l10n.confirm : l10n.next),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: isSubmitting ? null : onSetupLater,
          child: Text(l10n.setupLater),
        ),
      ],
    );
  }
}
