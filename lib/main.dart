import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  // por debajo de él. Es el único punto donde se monta el contenedor de estado.
  runApp(const ProviderScope(child: InvestepApp()));
}
