import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_gate.dart';
import '../core/auth/gate_refresh_listenable.dart';
import '../features/academy/presentation/academy_screen.dart';
import '../features/academy/presentation/admin_academy_screen.dart';
import '../features/admin/presentation/admin_menu_screen.dart';
import '../features/admin/presentation/admin_brokers_screen.dart';
import '../features/admin/presentation/admin_tickers_screen.dart';
import '../features/admin/presentation/user_list_view.dart';
import '../features/account/presentation/account_detail_screen.dart';
import '../features/account/presentation/edit_allocation_screen.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/portfolio/presentation/portfolio_screen.dart';
import '../features/relations/presentation/relations_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/setup/presentation/broker_setup_flow.dart';
import '../features/setup/presentation/setup_mode.dart';
import '../features/operations/presentation/operation_detail_screen.dart';
import '../features/operations/presentation/operation_form_screen.dart';
import '../features/store/domain/product.dart';
import '../features/store/presentation/store_catalog_screen.dart';
import '../features/store/presentation/admin_store_screen.dart';
import '../features/store/presentation/admin_store_form_screen.dart';
import '../features/store/presentation/product_detail_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/books/presentation/books_screen.dart';
import '../features/books/presentation/book_detail_screen.dart';
import '../features/books/domain/recommended_book.dart';
import '../features/books/presentation/admin_books_screen.dart';
import '../features/books/presentation/admin_book_form_screen.dart';
import 'main_shell.dart';

/// Decisión de redirección a partir del estado del gate y la ubicación actual.
///
/// Función pura (sin contexto ni navegación) para poder testear el gating de
/// forma exhaustiva. Devuelve la ruta destino o `null` para permitir quedarse.
///
/// Clave de seguridad: `GateNeedsPasswordReset` fuerza `/change-password` desde
/// CUALQUIER otra ubicación. Como `redirect` corre en cada navegación (back y
/// deep-link incluidos), el gate de cambio de contraseña es INSALVABLE: la única
/// salida es el `signOut` del flujo exitoso → `GateNoSession` → `/login`.
String? gateRedirect(AuthGateState gate, String location) {
  return switch (gate) {
    GateChecking() ||
    GateRetrying503() => location == '/splash' ? null : '/splash',
    GateNoSession() => location == '/login' ? null : '/login',
    GateNeedsPasswordReset() =>
      location == '/change-password' ? null : '/change-password',
    GateAuthenticated() =>
      (location == '/login' || location == '/splash') ? '/' : null,
  };
}

/// Router de la app. El `redirect` consume [authGateProvider] y se re-evalúa
/// vía `refreshListenable` cada vez que el gating cambia.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(gateRefreshProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        gateRedirect(ref.read(authGateProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change_password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) {
          final extra = state.extra;
          final mode = extra is SetupMode ? extra : SetupMode.initialSetup;
          return BrokerSetupFlow(mode: mode);
        },
      ),
      // Sub-rutas de detalle fuera del shell para que se abran a pantalla completa
      GoRoute(
        path: '/account/:id',
        name: 'account',
        builder: (context, state) =>
            AccountDetailScreen(allocationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/account/:id/edit',
        name: 'account_edit',
        builder: (context, state) =>
            EditAllocationScreen(allocationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/account/:id/operations/new',
        name: 'operation_new',
        builder: (context, state) =>
            OperationFormScreen(allocationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/account/:id/operations/:operationId',
        name: 'operation_detail',
        builder: (context, state) => OperationDetailScreen(
          allocationId: state.pathParameters['id']!,
          operationId: state.pathParameters['operationId']!,
        ),
      ),
      GoRoute(
        path: '/account/:id/operations/:operationId/edit',
        name: 'operation_edit',
        builder: (context, state) => OperationFormScreen(
          allocationId: state.pathParameters['id']!,
          operationId: state.pathParameters['operationId']!,
        ),
      ),
      // Menú de navegación global responsivo con persistencia de estado por rama
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/brokers',
                name: 'portfolio',
                builder: (context, state) => const PortfolioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/academy',
                name: 'academy',
                builder: (context, state) => const AcademyScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/relations',
                name: 'relations',
                builder: (context, state) => const RelationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/store',
                name: 'store',
                builder: (context, state) => const StoreCatalogScreen(),
                routes: [
                  GoRoute(
                    path: ':idOrSlug',
                    name: 'product_detail',
                    builder: (context, state) {
                      final idOrSlug = state.pathParameters['idOrSlug']!;
                      final extra = state.extra;
                      final product = extra is Product
                          ? extra
                          : (extra is Map
                                ? Product.fromJson(
                                    Map<String, dynamic>.from(extra),
                                  )
                                : null);
                      return ProductDetailScreen(
                        idOrSlug: idOrSlug,
                        product: product,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/books',
                name: 'books',
                builder: (context, state) => const BooksScreen(),
                routes: [
                  GoRoute(
                    path: ':idOrSlug',
                    name: 'book_detail',
                    builder: (context, state) {
                      final idOrSlug = state.pathParameters['idOrSlug']!;
                      final extra = state.extra;
                      final book = extra is RecommendedBook
                          ? extra
                          : (extra is Map
                                ? RecommendedBook.fromJson(
                                    Map<String, dynamic>.from(extra),
                                  )
                                : null);
                      return BookDetailScreen(idOrSlug: idOrSlug, book: book);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                name: 'admin_menu',
                builder: (context, state) => const AdminMenuScreen(),
                redirect: (context, state) {
                  final gate = ref.read(authGateProvider);
                  if (gate is GateAuthenticated) {
                    final role = gate.user.role;
                    if (role == 'admin' || role == 'manager') {
                      return null;
                    }
                  }
                  return '/';
                },
                routes: [
                  GoRoute(
                    path: 'academy',
                    name: 'admin_academy',
                    builder: (context, state) => const AdminAcademyScreen(),
                  ),
                  GoRoute(
                    path: 'users',
                    name: 'admin_users',
                    builder: (context, state) => const UserListView(),
                    redirect: (context, state) {
                      final gate = ref.read(authGateProvider);
                      if (gate is GateAuthenticated) {
                        final role = gate.user.role;
                        if (role == 'admin') {
                          return null;
                        }
                        if (role == 'manager') {
                          return '/admin';
                        }
                      }
                      return '/';
                    },
                  ),
                  GoRoute(
                    path: 'brokers',
                    name: 'admin_brokers',
                    builder: (context, state) => const AdminBrokersScreen(),
                    redirect: (context, state) {
                      final gate = ref.read(authGateProvider);
                      if (gate is GateAuthenticated) {
                        final role = gate.user.role;
                        if (role == 'admin') {
                          return null;
                        }
                      }
                      return '/admin';
                    },
                  ),
                  GoRoute(
                    path: 'tickers',
                    name: 'admin_tickers',
                    builder: (context, state) => const AdminTickersScreen(),
                    redirect: (context, state) {
                      final gate = ref.read(authGateProvider);
                      if (gate is GateAuthenticated) {
                        final role = gate.user.role;
                        if (role == 'admin') {
                          return null;
                        }
                      }
                      return '/admin';
                    },
                  ),
                  GoRoute(
                    path: 'store',
                    name: 'admin_store',
                    builder: (context, state) => const AdminStoreScreen(),
                    redirect: (context, state) {
                      final gate = ref.read(authGateProvider);
                      if (gate is GateAuthenticated) {
                        final role = gate.user.role;
                        if (role == 'admin') {
                          return null;
                        }
                      }
                      return '/admin';
                    },
                    routes: [
                      GoRoute(
                        path: 'new',
                        name: 'admin_store_new',
                        builder: (context, state) =>
                            const AdminStoreFormScreen(),
                      ),
                      GoRoute(
                        path: 'edit/:id',
                        name: 'admin_store_edit',
                        builder: (context, state) {
                          final productId = int.parse(
                            state.pathParameters['id']!,
                          );
                          final extra = state.extra;
                          final product = extra is Product
                              ? extra
                              : (extra is Map
                                    ? Product.fromJson(
                                        Map<String, dynamic>.from(extra),
                                      )
                                    : null);
                          return AdminStoreFormScreen(
                            productId: productId,
                            product: product,
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'books',
                    name: 'admin_books',
                    builder: (context, state) => const AdminBooksScreen(),
                    redirect: (context, state) {
                      final gate = ref.read(authGateProvider);
                      if (gate is GateAuthenticated) {
                        final role = gate.user.role;
                        if (role == 'admin') {
                          return null;
                        }
                      }
                      return '/admin';
                    },
                    routes: [
                      GoRoute(
                        path: 'new',
                        name: 'admin_books_new',
                        builder: (context, state) =>
                            const AdminBookFormScreen(),
                      ),
                      GoRoute(
                        path: 'edit/:id',
                        name: 'admin_books_edit',
                        builder: (context, state) {
                          final bookId = int.parse(state.pathParameters['id']!);
                          final extra = state.extra;
                          final book = extra is RecommendedBook
                              ? extra
                              : (extra is Map
                                    ? RecommendedBook.fromJson(
                                        Map<String, dynamic>.from(extra),
                                      )
                                    : null);
                          return AdminBookFormScreen(
                            bookId: bookId,
                            book: book,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
