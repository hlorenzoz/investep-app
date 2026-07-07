import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/app/theme/theme_provider.dart';
import 'package:investep_app/core/l10n/locale_provider.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
import 'package:investep_app/core/config/app_config.dart';
import 'package:investep_app/features/auth/presentation/login_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:investep_app/shared/widgets/language_selector.dart';
import 'package:investep_app/shared/widgets/theme_selector.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    AppConfig.supabaseUrl = 'https://example.supabase.co';
    AppConfig.supabaseAnonKey = 'someanonkey';
  });

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [supabaseClientProvider.overrideWithValue(mockSupabase)],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localeProvider);
          final themeMode = ref.watch(themeModeProvider);
          return MaterialApp(
            locale: locale,
            themeMode: themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoginScreen(),
          );
        },
      ),
    );
  }

  testWidgets(
    'LoginScreen renderiza el selector de tema e idioma en el AppBar en desktop',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSelector), findsOneWidget);
      expect(find.byType(LanguageSelector), findsOneWidget);
    },
  );

  testWidgets(
    'LoginScreen no renderiza el selector de tema e idioma en el AppBar en móvil',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSelector), findsNothing);
      expect(find.byType(LanguageSelector), findsNothing);
    },
  );

  testWidgets(
    'presionar LanguageSelector en LoginScreen cambia el idioma de la UI',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Iniciar Sesión'), findsOneWidget);

      await tester.tap(find.byType(LanguageSelector));
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsWidgets);
    },
  );

  testWidgets(
    'Validador de contraseña para cuenta no-demo requiere min 6 caracteres',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final emailFinder = find.byType(TextFormField).at(0);
      await tester.enterText(emailFinder, 'normal@example.com');
      await tester.pump();

      final passwordFormField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );

      final validator = passwordFormField.validator;
      expect(validator, isNotNull);

      expect(
        validator!('12345'),
        'La contraseña debe tener al menos 6 caracteres',
      );
      expect(validator('123456'), isNull);
      expect(validator(''), 'Por favor ingresá tu contraseña');
    },
  );

  testWidgets(
    'Validador de contraseña para cuenta demo NO requiere min 6 caracteres',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final emailFinder = find.byType(TextFormField).at(0);
      await tester.enterText(emailFinder, 'demo@hlorenzoz.com');
      await tester.pump();

      final passwordFormField = tester.widget<TextFormField>(
        find.byType(TextFormField).at(1),
      );

      final validator = passwordFormField.validator;
      expect(validator, isNotNull);

      expect(validator!('demo'), isNull);
      expect(validator('123'), isNull);
      expect(validator(''), 'Por favor ingresá tu contraseña');
    },
  );
}
