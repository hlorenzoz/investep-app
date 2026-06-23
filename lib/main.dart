import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ProviderScope es la raíz del árbol de Riverpod: todos los providers viven
  // por debajo de él. Es el único punto donde se monta el contenedor de estado.
  runApp(const ProviderScope(child: InvestepApp()));
}
