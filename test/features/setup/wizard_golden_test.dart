import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investep_app/features/setup/presentation/setup_mode.dart';
import 'package:investep_app/features/setup/presentation/slides/capital_slide.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

/// Envuelve un slide con las delegates de localización (es) y un fondo oscuro,
/// para golden tests deterministas.
Widget _wrap(Widget child) => Localizations(
  locale: const Locale('es'),
  delegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  child: Material(
    color: const Color(0xFF0B1020),
    child: Padding(padding: const EdgeInsets.all(24), child: child),
  ),
);

void main() {
  goldenTest(
    'CapitalSlide',
    fileName: 'capital_slide',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'initial_setup',
          constraints: const BoxConstraints(maxWidth: 360),
          child: ProviderScope(
            child: _wrap(const CapitalSlide(mode: SetupMode.initialSetup)),
          ),
        ),
      ],
    ),
  );
}
