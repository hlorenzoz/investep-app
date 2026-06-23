import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/portfolio/presentation/portfolio_screen.dart';

/// Router de la app expuesto como provider para poder leer estado de Riverpod
/// (p. ej. sesión) en redirecciones a futuro.
///
/// Por ahora una sola ruta. Cuando entre auth, se agrega `redirect` que observe
/// el provider de sesión y empuje a /login si no hay sesión válida.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'portfolio',
        builder: (context, state) => const PortfolioScreen(),
      ),
    ],
  );
});
