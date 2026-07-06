import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Investep'**
  String get appTitle;

  /// No description provided for @splashChecking.
  ///
  /// In es, this message translates to:
  /// **'Verificando tu sesión...'**
  String get splashChecking;

  /// No description provided for @serviceUnavailableTitle.
  ///
  /// In es, this message translates to:
  /// **'Servicio no disponible'**
  String get serviceUnavailableTitle;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @passwordChangedRelogin.
  ///
  /// In es, this message translates to:
  /// **'Contraseña actualizada, volvé a iniciar sesión'**
  String get passwordChangedRelogin;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @loadingGeneric.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get loadingGeneric;

  /// No description provided for @setupLater.
  ///
  /// In es, this message translates to:
  /// **'Configurar más tarde'**
  String get setupLater;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @stepLabel.
  ///
  /// In es, this message translates to:
  /// **'Paso'**
  String get stepLabel;

  /// No description provided for @stepOf.
  ///
  /// In es, this message translates to:
  /// **'de'**
  String get stepOf;

  /// No description provided for @capitalTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu capital inicial'**
  String get capitalTitle;

  /// No description provided for @capitalSubtitle.
  ///
  /// In es, this message translates to:
  /// **'¿Con cuánto vas a empezar a invertir?'**
  String get capitalSubtitle;

  /// No description provided for @amountLabel.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get amountLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get currencyLabel;

  /// No description provided for @brokerTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegí tu broker'**
  String get brokerTitle;

  /// No description provided for @brokerSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar broker'**
  String get brokerSearchHint;

  /// No description provided for @alreadyConfigured.
  ///
  /// In es, this message translates to:
  /// **'Ya configurado'**
  String get alreadyConfigured;

  /// No description provided for @brokersLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar los brokers'**
  String get brokersLoadError;

  /// No description provided for @accountTypeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cuenta'**
  String get accountTypeTitle;

  /// No description provided for @accountTypeEquity.
  ///
  /// In es, this message translates to:
  /// **'Acciones'**
  String get accountTypeEquity;

  /// No description provided for @accountTypeOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones'**
  String get accountTypeOptions;

  /// No description provided for @planTitle.
  ///
  /// In es, this message translates to:
  /// **'Elegí un plan'**
  String get planTitle;

  /// No description provided for @planTargetMonthly.
  ///
  /// In es, this message translates to:
  /// **'Mensual'**
  String get planTargetMonthly;

  /// No description provided for @planTargetDaily.
  ///
  /// In es, this message translates to:
  /// **'Diario'**
  String get planTargetDaily;

  /// No description provided for @plansEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay planes para este tipo de cuenta'**
  String get plansEmpty;

  /// No description provided for @depositTitle.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get depositTitle;

  /// No description provided for @depositModePercent.
  ///
  /// In es, this message translates to:
  /// **'% del capital'**
  String get depositModePercent;

  /// No description provided for @depositModeAmount.
  ///
  /// In es, this message translates to:
  /// **'Monto'**
  String get depositModeAmount;

  /// No description provided for @depositAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get depositAvailable;

  /// No description provided for @depositInvalid.
  ///
  /// In es, this message translates to:
  /// **'El depósito debe ser mayor a 0'**
  String get depositInvalid;

  /// No description provided for @summaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisá y confirmá'**
  String get summaryTitle;

  /// No description provided for @summaryEditHint.
  ///
  /// In es, this message translates to:
  /// **'Tocá un campo para editarlo'**
  String get summaryEditHint;

  /// No description provided for @summaryBroker.
  ///
  /// In es, this message translates to:
  /// **'Broker'**
  String get summaryBroker;

  /// No description provided for @summaryAccountType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de cuenta'**
  String get summaryAccountType;

  /// No description provided for @summaryPlan.
  ///
  /// In es, this message translates to:
  /// **'Plan'**
  String get summaryPlan;

  /// No description provided for @summaryDeposit.
  ///
  /// In es, this message translates to:
  /// **'Depósito'**
  String get summaryDeposit;

  /// No description provided for @summaryCurrency.
  ///
  /// In es, this message translates to:
  /// **'Moneda'**
  String get summaryCurrency;

  /// No description provided for @summaryRemaining.
  ///
  /// In es, this message translates to:
  /// **'Disponible restante'**
  String get summaryRemaining;

  /// No description provided for @dashboardTitle.
  ///
  /// In es, this message translates to:
  /// **'Brókers'**
  String get dashboardTitle;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Configurá tu capital'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Definí tu capital inicial y agregá tus cuentas de broker.'**
  String get dashboardEmptySubtitle;

  /// No description provided for @configureCapitalCta.
  ///
  /// In es, this message translates to:
  /// **'Configurar mi capital'**
  String get configureCapitalCta;

  /// No description provided for @addBrokerAccount.
  ///
  /// In es, this message translates to:
  /// **'Agregar cuenta de broker'**
  String get addBrokerAccount;

  /// No description provided for @completeSetupBanner.
  ///
  /// In es, this message translates to:
  /// **'Completá tu configuración'**
  String get completeSetupBanner;

  /// No description provided for @dashboardLoadError.
  ///
  /// In es, this message translates to:
  /// **'No pudimos cargar tu capital'**
  String get dashboardLoadError;

  /// No description provided for @capitalTotalLabel.
  ///
  /// In es, this message translates to:
  /// **'Capital total'**
  String get capitalTotalLabel;

  /// No description provided for @allocatedLabel.
  ///
  /// In es, this message translates to:
  /// **'Asignado'**
  String get allocatedLabel;

  /// No description provided for @availableLabel.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get availableLabel;

  /// No description provided for @ofCapital.
  ///
  /// In es, this message translates to:
  /// **'del capital'**
  String get ofCapital;

  /// No description provided for @accountDetailComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get accountDetailComingSoon;

  /// No description provided for @editAccount.
  ///
  /// In es, this message translates to:
  /// **'Editar cuenta'**
  String get editAccount;

  /// No description provided for @accountNotFound.
  ///
  /// In es, this message translates to:
  /// **'Cuenta no encontrada'**
  String get accountNotFound;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @navPortfolio.
  ///
  /// In es, this message translates to:
  /// **'Brokers'**
  String get navPortfolio;

  /// No description provided for @navAcademy.
  ///
  /// In es, this message translates to:
  /// **'Academia'**
  String get navAcademy;

  /// No description provided for @navAdmin.
  ///
  /// In es, this message translates to:
  /// **'Admin'**
  String get navAdmin;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @navRelations.
  ///
  /// In es, this message translates to:
  /// **'Relaciones'**
  String get navRelations;

  /// No description provided for @relationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Relaciones entre activos'**
  String get relationsTitle;

  /// No description provided for @relationsAssetsSection.
  ///
  /// In es, this message translates to:
  /// **'Activos'**
  String get relationsAssetsSection;

  /// No description provided for @relationsSectorsSection.
  ///
  /// In es, this message translates to:
  /// **'Sectores'**
  String get relationsSectorsSection;

  /// No description provided for @relationsColPrincipal.
  ///
  /// In es, this message translates to:
  /// **'Activo Principal'**
  String get relationsColPrincipal;

  /// No description provided for @relationsColEtfs.
  ///
  /// In es, this message translates to:
  /// **'ETFs (x2, x3)'**
  String get relationsColEtfs;

  /// No description provided for @relationsColInverse.
  ///
  /// In es, this message translates to:
  /// **'Activo Inverso'**
  String get relationsColInverse;

  /// No description provided for @relationsColSector.
  ///
  /// In es, this message translates to:
  /// **'Sector'**
  String get relationsColSector;

  /// No description provided for @relationsFavorites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get relationsFavorites;

  /// No description provided for @favoriteError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo actualizar el favorito. Intentá de nuevo.'**
  String get favoriteError;

  /// No description provided for @relationsSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar activo por símbolo o nombre…'**
  String get relationsSearchHint;

  /// No description provided for @relationsNoResults.
  ///
  /// In es, this message translates to:
  /// **'No hay activos que coincidan con la búsqueda.'**
  String get relationsNoResults;

  /// No description provided for @relationsAssetsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay activos con relaciones cargadas.'**
  String get relationsAssetsEmpty;

  /// No description provided for @relationsSectorsEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay sectores cargados.'**
  String get relationsSectorsEmpty;

  /// No description provided for @relationsError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las relaciones entre activos.'**
  String get relationsError;

  /// No description provided for @relationsRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get relationsRetry;

  /// No description provided for @settingsInterface.
  ///
  /// In es, this message translates to:
  /// **'Interfaz'**
  String get settingsInterface;

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEs.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get settingsLanguageEs;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In es, this message translates to:
  /// **'Inglés'**
  String get settingsLanguageEn;

  /// No description provided for @settingsAccount.
  ///
  /// In es, this message translates to:
  /// **'Cuenta'**
  String get settingsAccount;

  /// No description provided for @settingsChangePassword.
  ///
  /// In es, this message translates to:
  /// **'Cambiar contraseña'**
  String get settingsChangePassword;

  /// No description provided for @settingsSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get settingsSignOut;

  /// No description provided for @academyComingSoon.
  ///
  /// In es, this message translates to:
  /// **'El contenido educativo de Investep Academy estará disponible próximamente.'**
  String get academyComingSoon;

  /// No description provided for @deleteAccount.
  ///
  /// In es, this message translates to:
  /// **'Eliminar cuenta'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar cuenta?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que querés eliminar esta cuenta de broker? El saldo asignado volverá a estar disponible en tu capital.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @settingsCapitalTitle.
  ///
  /// In es, this message translates to:
  /// **'Capital'**
  String get settingsCapitalTitle;

  /// No description provided for @settingsCapitalTotal.
  ///
  /// In es, this message translates to:
  /// **'Capital inicial'**
  String get settingsCapitalTotal;

  /// No description provided for @settingsEditCapital.
  ///
  /// In es, this message translates to:
  /// **'Modificar capital inicial'**
  String get settingsEditCapital;

  /// No description provided for @settingsEditCapitalHint.
  ///
  /// In es, this message translates to:
  /// **'Ingresá el nuevo monto para tu capital inicial.'**
  String get settingsEditCapitalHint;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresá tus credenciales para validar el acceso.'**
  String get loginSubtitle;

  /// No description provided for @loginEmailLabel.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get loginPasswordLabel;

  /// No description provided for @loginSubmitButton.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get loginSubmitButton;

  /// No description provided for @loginAuthenticating.
  ///
  /// In es, this message translates to:
  /// **'Autenticando y validando...'**
  String get loginAuthenticating;

  /// No description provided for @loginAuthError.
  ///
  /// In es, this message translates to:
  /// **'Error de Autenticación'**
  String get loginAuthError;

  /// No description provided for @operationNewTitle.
  ///
  /// In es, this message translates to:
  /// **'Nueva Operación'**
  String get operationNewTitle;

  /// No description provided for @operationEditTitle.
  ///
  /// In es, this message translates to:
  /// **'Editar Operación'**
  String get operationEditTitle;

  /// No description provided for @operationTicker.
  ///
  /// In es, this message translates to:
  /// **'Ticker / Símbolo'**
  String get operationTicker;

  /// No description provided for @operationOpenedAt.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Compra'**
  String get operationOpenedAt;

  /// No description provided for @operationQty.
  ///
  /// In es, this message translates to:
  /// **'Cantidad'**
  String get operationQty;

  /// No description provided for @operationBuyPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio de Compra'**
  String get operationBuyPrice;

  /// No description provided for @operationLimitPrice.
  ///
  /// In es, this message translates to:
  /// **'Precio Límite (Opcional)'**
  String get operationLimitPrice;

  /// No description provided for @operationStrategy.
  ///
  /// In es, this message translates to:
  /// **'Estrategia (Opcional)'**
  String get operationStrategy;

  /// No description provided for @operationNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get operationNotes;

  /// No description provided for @operationUrl.
  ///
  /// In es, this message translates to:
  /// **'URL de Referencia'**
  String get operationUrl;

  /// No description provided for @operationStrike.
  ///
  /// In es, this message translates to:
  /// **'Strike (Precio Ejercicio)'**
  String get operationStrike;

  /// No description provided for @operationExpirationDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de Expiración'**
  String get operationExpirationDate;

  /// No description provided for @operationContractType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de Contrato'**
  String get operationContractType;

  /// No description provided for @operationSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get operationSave;

  /// No description provided for @operationDelete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get operationDelete;

  /// No description provided for @operationDeleted.
  ///
  /// In es, this message translates to:
  /// **'Operación eliminada con éxito'**
  String get operationDeleted;

  /// No description provided for @operationSaved.
  ///
  /// In es, this message translates to:
  /// **'Operación guardada con éxito'**
  String get operationSaved;

  /// No description provided for @operationSuggestUrl.
  ///
  /// In es, this message translates to:
  /// **'Sugerir URL de Yahoo Finance'**
  String get operationSuggestUrl;

  /// No description provided for @loginRegisterButton.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get loginRegisterButton;

  /// No description provided for @loginRegisterHint.
  ///
  /// In es, this message translates to:
  /// **'Para darse de alta póngase en contacto con el equipo comercial'**
  String get loginRegisterHint;

  /// No description provided for @navStore.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get navStore;

  /// No description provided for @storeTitle.
  ///
  /// In es, this message translates to:
  /// **'Tienda'**
  String get storeTitle;

  /// No description provided for @storeEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay productos disponibles en esta categoría.'**
  String get storeEmpty;

  /// No description provided for @storeCategoryAll.
  ///
  /// In es, this message translates to:
  /// **'Todos'**
  String get storeCategoryAll;

  /// No description provided for @storeCategoryBooks.
  ///
  /// In es, this message translates to:
  /// **'Libros'**
  String get storeCategoryBooks;

  /// No description provided for @storeCategoryTshirts.
  ///
  /// In es, this message translates to:
  /// **'Remeras'**
  String get storeCategoryTshirts;

  /// No description provided for @storeCategoryCaps.
  ///
  /// In es, this message translates to:
  /// **'Gorras'**
  String get storeCategoryCaps;

  /// No description provided for @storeBuyAmazon.
  ///
  /// In es, this message translates to:
  /// **'Ver en Amazon'**
  String get storeBuyAmazon;

  /// No description provided for @storeBuyNow.
  ///
  /// In es, this message translates to:
  /// **'Comprar ahora'**
  String get storeBuyNow;

  /// No description provided for @storeAdminTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestión de Tienda'**
  String get storeAdminTitle;

  /// No description provided for @storeAdminSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Administrá el catálogo de productos y variantes.'**
  String get storeAdminSubtitle;

  /// No description provided for @storeDeleteConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar producto?'**
  String get storeDeleteConfirmTitle;

  /// No description provided for @storeDeleteConfirmMsg.
  ///
  /// In es, this message translates to:
  /// **'¿Estás seguro de que querés eliminar el producto \'{name}\'? Esta acción es irreversible.'**
  String storeDeleteConfirmMsg(Object name);

  /// No description provided for @storeSaveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Producto guardado con éxito'**
  String get storeSaveSuccess;

  /// No description provided for @storeDeleteSuccess.
  ///
  /// In es, this message translates to:
  /// **'Producto eliminado con éxito'**
  String get storeDeleteSuccess;

  /// No description provided for @storeFormValidationPriceOrAmazon.
  ///
  /// In es, this message translates to:
  /// **'Definí un precio o un enlace de Amazon (al menos uno).'**
  String get storeFormValidationPriceOrAmazon;

  /// No description provided for @storeFormValidationTshirtOnly.
  ///
  /// In es, this message translates to:
  /// **'Género y Tema solo aplican para la categoría Remeras.'**
  String get storeFormValidationTshirtOnly;

  /// No description provided for @storeFormValidationSlug.
  ///
  /// In es, this message translates to:
  /// **'El slug solo permite minúsculas, números, guión y guión bajo.'**
  String get storeFormValidationSlug;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
