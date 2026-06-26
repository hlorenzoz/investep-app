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

  @override
  String get loadingGeneric => 'Cargando...';

  @override
  String get setupLater => 'Configurar más tarde';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get confirm => 'Confirmar';

  @override
  String get stepLabel => 'Paso';

  @override
  String get stepOf => 'de';

  @override
  String get capitalTitle => 'Tu capital inicial';

  @override
  String get capitalSubtitle => '¿Con cuánto vas a empezar a invertir?';

  @override
  String get amountLabel => 'Monto';

  @override
  String get currencyLabel => 'Moneda';

  @override
  String get brokerTitle => 'Elegí tu broker';

  @override
  String get brokerSearchHint => 'Buscar broker';

  @override
  String get alreadyConfigured => 'Ya configurado';

  @override
  String get brokersLoadError => 'No pudimos cargar los brokers';

  @override
  String get accountTypeTitle => 'Tipo de cuenta';

  @override
  String get accountTypeEquity => 'Acciones';

  @override
  String get accountTypeOptions => 'Opciones';

  @override
  String get planTitle => 'Elegí un plan';

  @override
  String get planTargetMonthly => 'Ganancia mensual objetivo';

  @override
  String get plansEmpty => 'No hay planes para este tipo de cuenta';

  @override
  String get depositTitle => 'Depósito inicial';

  @override
  String get depositModePercent => '% del capital';

  @override
  String get depositModeAmount => 'Monto';

  @override
  String get depositAvailable => 'Disponible';

  @override
  String get depositInvalid =>
      'El depósito debe ser mayor a 0 y no superar el disponible';

  @override
  String get summaryTitle => 'Revisá y confirmá';

  @override
  String get summaryEditHint => 'Tocá un campo para editarlo';

  @override
  String get summaryBroker => 'Broker';

  @override
  String get summaryAccountType => 'Tipo de cuenta';

  @override
  String get summaryPlan => 'Plan';

  @override
  String get summaryDeposit => 'Depósito';

  @override
  String get summaryCurrency => 'Moneda';

  @override
  String get summaryRemaining => 'Disponible restante';

  @override
  String get dashboardTitle => 'Mi capital';

  @override
  String get dashboardEmptyTitle => 'Configurá tu capital';

  @override
  String get dashboardEmptySubtitle =>
      'Definí tu capital inicial y agregá tus cuentas de broker.';

  @override
  String get configureCapitalCta => 'Configurar mi capital';

  @override
  String get addBrokerAccount => 'Agregar cuenta de broker';

  @override
  String get completeSetupBanner => 'Completá tu configuración';

  @override
  String get dashboardLoadError => 'No pudimos cargar tu capital';

  @override
  String get capitalTotalLabel => 'Capital total';

  @override
  String get allocatedLabel => 'Asignado';

  @override
  String get availableLabel => 'Disponible';

  @override
  String get ofCapital => 'del capital';
}
