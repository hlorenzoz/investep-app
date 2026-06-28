import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/app/theme/theme_provider.dart';
import 'package:investep_app/core/l10n/locale_provider.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
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
    'LoginScreen renderiza el selector de tema e idioma en el AppBar',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSelector), findsOneWidget);
      expect(find.byType(LanguageSelector), findsOneWidget);
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
}
