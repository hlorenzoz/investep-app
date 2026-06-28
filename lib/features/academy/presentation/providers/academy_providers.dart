import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/locale_provider.dart';
import '../../data/academy_repository.dart';
import '../../domain/academy_models.dart';

/// Provider para la lista de paquetes de la Academia (vista usuario).
final academyPlansProvider = FutureProvider.autoDispose<List<AcademyPlan>>((
  ref,
) {
  final locale = ref.watch(localeCodeProvider);
  return ref.watch(academyRepositoryProvider).getAcademyPlans(locale: locale);
});

/// Notifier para la gestión administrativa de los paquetes de la Academia.
class AdminAcademyPlansNotifier extends AsyncNotifier<List<AcademyPlanAdmin>> {
  @override
  Future<List<AcademyPlanAdmin>> build() {
    return ref.watch(academyRepositoryProvider).getAdminAcademyPlans();
  }

  Future<void> updatePlan(int id, Map<String, dynamic> delta) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academyRepositoryProvider).updateAcademyPlan(id, delta);
      // Invalida también la vista cliente para que se refresque
      ref.invalidate(academyPlansProvider);
      return ref.read(academyRepositoryProvider).getAdminAcademyPlans();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(academyRepositoryProvider).getAdminAcademyPlans();
    });
  }
}

final adminAcademyPlansProvider =
    AsyncNotifierProvider<AdminAcademyPlansNotifier, List<AcademyPlanAdmin>>(
      AdminAcademyPlansNotifier.new,
    );
