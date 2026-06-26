// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Investep';

  @override
  String get splashChecking => 'Verificando tu sesión...';

  @override
  String get serviceUnavailableTitle => 'Servicio no disponible';

  @override
  String get retry => 'Reintentar';

  @override
  String get passwordChangedRelogin =>
      'Contraseña actualizada, volvé a iniciar sesión';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonContinue => 'Continuar';
}
