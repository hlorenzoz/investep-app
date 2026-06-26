// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:investep_app/app/theme/theme_provider.dart';
import 'package:investep_app/core/l10n/locale_provider.dart';

void main() {
  group('LocaleNotifier & localeProvider Tests', () {
    late SharedPreferences sharedPreferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sharedPreferences = await SharedPreferences.getInstance();
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('debe inicializar en Locale("es") si no hay preferencia guardada', () {
      final container = createContainer();

      final currentLocale = container.read(localeProvider);
      expect(currentLocale, const Locale('es'));
      
      final currentCode = container.read(localeCodeProvider);
      expect(currentCode, 'es');
    });

    test('debe inicializar en el idioma guardado en SharedPreferences si existe', () async {
      await sharedPreferences.setString('locale_preference', 'en');
      
      final container = createContainer();

      final currentLocale = container.read(localeProvider);
      expect(currentLocale, const Locale('en'));
      
      final currentCode = container.read(localeCodeProvider);
      expect(currentCode, 'en');
    });

    test('debe actualizar el idioma y persistir el valor en SharedPreferences al llamar a setLocale', () async {
      final container = createContainer();

      expect(container.read(localeProvider), const Locale('es'));

      // Cambiar a inglés
      await container.read(localeProvider.notifier).setLocale(const Locale('en'));

      // Verificar que el estado cambie en memoria
      expect(container.read(localeProvider), const Locale('en'));
      expect(container.read(localeCodeProvider), 'en');

      // Verificar que se persistió en SharedPreferences
      expect(sharedPreferences.getString('locale_preference'), 'en');
    });
  });
}
