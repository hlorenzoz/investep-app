import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/theme/theme_provider.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de preferencias locales antes de montar el árbol.
  final sharedPrefs = await SharedPreferences.getInstance();

  if (AppConfig.isValidSupabaseConfig) {
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        publishableKey: AppConfig.supabaseAnonKey,
      );
    } catch (e) {
      debugPrint('Error al inicializar Supabase: $e');
    }
  }

  // ProviderScope es la raíz del árbol de Riverpod: todos los providers viven
  // por debajo de él. Sobreescribimos el provider de SharedPreferences para
  // permitir que se lea de forma síncrona e inmediata en toda la app.
  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPrefs)],
      child: const InvestepApp(),
    ),
  );
}
