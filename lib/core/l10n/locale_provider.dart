import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/theme_provider.dart';

/// Clave de almacenamiento para persistir el idioma preferido.
const String _localeKey = 'locale_preference';

/// Notifier para gestionar y persistir el [Locale] activo de la aplicación.
class LocaleNotifier extends Notifier<Locale> {
  SharedPreferences? _prefs;

  @override
  Locale build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final prefs = _prefs;
    if (prefs == null) return const Locale('es');

    final saved = prefs.getString(_localeKey);
    if (saved == null) return const Locale('es');
    return Locale(saved);
  }

  /// Cambia el idioma actual y lo persiste si SharedPreferences está disponible.
  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = _prefs;
    if (prefs != null) {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}

/// Provider global que expone el [Locale] activo y su notifier.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

/// Código de locale activo para las llamadas a la API (p. ej. `GET /plans`).
/// Se refresca automáticamente cuando el usuario cambia el idioma.
final localeCodeProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});
