// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Investep';

  @override
  String get splashChecking => 'Checking your session...';

  @override
  String get serviceUnavailableTitle => 'Service unavailable';

  @override
  String get retry => 'Retry';

  @override
  String get passwordChangedRelogin => 'Password updated, please sign in again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonContinue => 'Continue';
}
