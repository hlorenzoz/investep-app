import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider que expone la instancia de [SharedPreferences].
///
/// Debe ser sobreescrito en el [ProviderScope] en el punto de entrada de la app
/// ([main]) tras inicializarse de forma asíncrona. Esto permite acceso síncrono
/// inmediato en el resto de los providers.
/// Provider que expone la instancia de [SharedPreferences] de forma opcional.
///
/// Se sobreescribe en el [ProviderScope] en producción. Si es nulo (por ejemplo,
/// en entornos de pruebas de widget simples que no lo configuren), el sistema
/// hace un fallback seguro a memoria temporal y no lanza excepciones.
final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) {
  return null;
});

/// Clave de almacenamiento para persistir el tema seleccionado.
const String _themeModeKey = 'theme_mode_preference';

/// Notifier encargado de gestionar y persistir el estado del [ThemeMode].
class ThemeNotifier extends Notifier<ThemeMode> {
  SharedPreferences? _prefs;

  @override
  ThemeMode build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final prefs = _prefs;
    if (prefs == null) return ThemeMode.system;

    final savedMode = prefs.getString(_themeModeKey);
    if (savedMode == null) return ThemeMode.system;

    return ThemeMode.values.firstWhere(
      (e) => e.name == savedMode,
      orElse: () => ThemeMode.system,
    );
  }

  /// Cambia el modo de tema actual y lo persiste si SharedPreferences está disponible.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(_themeModeKey, mode.name);
    }
  }
}

/// Provider global que expone el estado de [ThemeMode] y su notifier.
final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
