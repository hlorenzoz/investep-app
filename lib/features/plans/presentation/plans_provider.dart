import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/locale_provider.dart';
import '../../capital/domain/account_type.dart';
import '../data/plan_repository.dart';
import '../domain/investment_plan.dart';

/// Planes para el tipo de cuenta elegido en el wizard. `AsyncValue` →
/// loading / error / data sin boilerplate. El locale sale de [localeCodeProvider].
final plansProvider = FutureProvider.autoDispose
    .family<List<InvestmentPlan>, AccountType>((ref, accountType) {
      final locale = ref.watch(localeCodeProvider);
      return ref
          .watch(planRepositoryProvider)
          .getPlans(locale: locale, accountType: accountType);
    });
