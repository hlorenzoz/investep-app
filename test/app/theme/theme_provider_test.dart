import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:investep_app/app/theme/theme_provider.dart';

void main() {
  group('ThemeNotifier & themeModeProvider Tests', () {
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

    test(
      'debe inicializar en ThemeMode.system si no hay preferencia guardada',
      () {
        final container = createContainer();

        final currentMode = container.read(themeModeProvider);
        expect(currentMode, ThemeMode.system);
      },
    );

    test(
      'debe inicializar en el tema guardado en SharedPreferences si existe',
      () async {
        await sharedPreferences.setString(
          'theme_mode_preference',
          ThemeMode.dark.name,
        );

        final container = createContainer();

        final currentMode = container.read(themeModeProvider);
        expect(currentMode, ThemeMode.dark);
      },
    );

    test(
      'debe actualizar el tema y persistir el valor en SharedPreferences al llamar a setThemeMode',
      () async {
        final container = createContainer();

        expect(container.read(themeModeProvider), ThemeMode.system);

        // Cambiar a claro
        await container
            .read(themeModeProvider.notifier)
            .setThemeMode(ThemeMode.light);

        // Verificar que el estado cambie en memoria
        expect(container.read(themeModeProvider), ThemeMode.light);

        // Verificar que se persistió en SharedPreferences
        expect(
          sharedPreferences.getString('theme_mode_preference'),
          ThemeMode.light.name,
        );
      },
    );
  });
}
