import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient supabase;
  late MockGoTrueClient goTrue;

  setUp(() {
    supabase = MockSupabaseClient();
    goTrue = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(goTrue);
    when(() => goTrue.signOut()).thenAnswer((_) async {});
  });

  group('handleAuthError', () {
    test('401 → signOut (fuerza re-login)', () async {
      await handleAuthError(supabase, 401);
      verify(() => goTrue.signOut()).called(1);
    });

    test('503 → NO signOut (transitorio, no desloguea)', () async {
      await handleAuthError(supabase, 503);
      verifyNever(() => goTrue.signOut());
    });

    test('429 → NO signOut (transitorio, no desloguea)', () async {
      await handleAuthError(supabase, 429);
      verifyNever(() => goTrue.signOut());
    });

    test('404 → NO signOut', () async {
      await handleAuthError(supabase, 404);
      verifyNever(() => goTrue.signOut());
    });

    test('sin status (null) → NO signOut', () async {
      await handleAuthError(supabase, null);
      verifyNever(() => goTrue.signOut());
    });
  });
}
