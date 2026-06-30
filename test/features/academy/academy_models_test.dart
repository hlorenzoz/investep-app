import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/academy/domain/academy_models.dart';

void main() {
  group('AcademyPlan model tests', () {
    test('debe deserializar un JSON de cliente correctamente', () {
      final json = {
        'id': 1,
        'slug': 'gold',
        'name': 'Paquete Oro',
        'subtitle': '3 semanas con soporte',
        'priceRegular': 10799.0,
        'priceOffer': 4199.0,
        'currency': 'USD',
        'features': [
          {'id': 10, 'slug': 'live_classes', 'label': 'Clases en Vivo'},
        ],
      };

      final plan = AcademyPlan.fromJson(json);

      expect(plan.id, 1);
      expect(plan.slug, 'gold');
      expect(plan.name, 'Paquete Oro');
      expect(plan.priceRegular, 10799.0);
      expect(plan.priceOffer, 4199.0);
      expect(plan.features.length, 1);
      expect(plan.features.first.label, 'Clases en Vivo');
    });

    test('debe deserializar un JSON de administración correctamente', () {
      final json = {
        'id': 2,
        'slug': 'silver',
        'priceRegular': 8299.0,
        'priceOffer': 3699.0,
        'currency': 'USD',
        'sortOrder': 2,
        'isActive': true,
        'translations': [
          {'locale': 'es', 'name': 'Paquete Silver', 'subtitle': '2 semanas'},
        ],
        'featureIds': [1, 2, 3],
      };

      final adminPlan = AcademyPlanAdmin.fromJson(json);

      expect(adminPlan.id, 2);
      expect(adminPlan.slug, 'silver');
      expect(adminPlan.isActive, isTrue);
      expect(adminPlan.translations.first.name, 'Paquete Silver');
      expect(adminPlan.featureIds, equals([1, 2, 3]));
    });
  });

  group('AcademyFeatureAdmin model tests', () {
    test(
      'debe deserializar un JSON de característica administrativa correctamente',
      () {
        final json = {
          'id': 5,
          'slug': 'live_sessions',
          'sortOrder': 3,
          'translations': [
            {'locale': 'es', 'label': 'Sesiones en vivo'},
            {'locale': 'en', 'label': 'Live sessions'},
          ],
        };

        final feature = AcademyFeatureAdmin.fromJson(json);

        expect(feature.id, 5);
        expect(feature.slug, 'live_sessions');
        expect(feature.sortOrder, 3);
        expect(feature.translations.length, 2);
        expect(feature.translations.first.locale, 'es');
        expect(feature.translations.first.label, 'Sesiones en vivo');
        expect(feature.translations.last.locale, 'en');
        expect(feature.translations.last.label, 'Live sessions');
      },
    );
  });
}
