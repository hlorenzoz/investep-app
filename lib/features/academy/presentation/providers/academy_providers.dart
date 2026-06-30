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

  Future<void> createPlan(Map<String, dynamic> plan) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academyRepositoryProvider).createAcademyPlan(plan);
      ref.invalidate(academyPlansProvider);
      return ref.read(academyRepositoryProvider).getAdminAcademyPlans();
    });
  }

  Future<void> deletePlan(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academyRepositoryProvider).deleteAcademyPlan(id);
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

/// Notifier para la gestión administrativa de las características globales de la Academia.
class AdminAcademyFeaturesNotifier
    extends AsyncNotifier<List<AcademyFeatureAdmin>> {
  @override
  Future<List<AcademyFeatureAdmin>> build() {
    return ref.watch(academyRepositoryProvider).getAdminAcademyFeatures();
  }

  Future<void> createFeature(Map<String, dynamic> feature) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academyRepositoryProvider).createAcademyFeature(feature);
      ref.invalidate(academyPlansProvider); // Por si algún plan las usa
      return ref.read(academyRepositoryProvider).getAdminAcademyFeatures();
    });
  }

  Future<void> updateFeature(int id, Map<String, dynamic> delta) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academyRepositoryProvider).updateAcademyFeature(id, delta);
      ref.invalidate(academyPlansProvider);
      return ref.read(academyRepositoryProvider).getAdminAcademyFeatures();
    });
  }

  Future<void> deleteFeature(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(academyRepositoryProvider).deleteAcademyFeature(id);
      ref.invalidate(academyPlansProvider);
      return ref.read(academyRepositoryProvider).getAdminAcademyFeatures();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() {
      return ref.read(academyRepositoryProvider).getAdminAcademyFeatures();
    });
  }
}

final adminAcademyFeaturesProvider =
    AsyncNotifierProvider<
      AdminAcademyFeaturesNotifier,
      List<AcademyFeatureAdmin>
    >(AdminAcademyFeaturesNotifier.new);
