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

  @override
  String get loadingGeneric => 'Loading...';

  @override
  String get setupLater => 'Set up later';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get confirm => 'Confirm';

  @override
  String get stepLabel => 'Step';

  @override
  String get stepOf => 'of';

  @override
  String get capitalTitle => 'Your initial capital';

  @override
  String get capitalSubtitle => 'How much will you start investing with?';

  @override
  String get amountLabel => 'Amount';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get brokerTitle => 'Choose your broker';

  @override
  String get brokerSearchHint => 'Search broker';

  @override
  String get alreadyConfigured => 'Already configured';

  @override
  String get brokersLoadError => 'We couldn\'t load the brokers';

  @override
  String get accountTypeTitle => 'Account type';

  @override
  String get accountTypeEquity => 'Equity';

  @override
  String get accountTypeOptions => 'Options';

  @override
  String get planTitle => 'Choose a plan';

  @override
  String get planTargetMonthly => 'Monthly';

  @override
  String get planTargetDaily => 'Daily';

  @override
  String get plansEmpty => 'No plans available for this account type';

  @override
  String get depositTitle => 'Amount';

  @override
  String get depositModePercent => '% of capital';

  @override
  String get depositModeAmount => 'Amount';

  @override
  String get depositAvailable => 'Available';

  @override
  String get depositInvalid => 'Deposit must be greater than 0';

  @override
  String get summaryTitle => 'Review and confirm';

  @override
  String get summaryEditHint => 'Tap a field to edit it';

  @override
  String get summaryBroker => 'Broker';

  @override
  String get summaryAccountType => 'Account type';

  @override
  String get summaryPlan => 'Plan';

  @override
  String get summaryDeposit => 'Deposit';

  @override
  String get summaryCurrency => 'Currency';

  @override
  String get summaryRemaining => 'Remaining available';

  @override
  String get dashboardTitle => 'Brokers';

  @override
  String get dashboardEmptyTitle => 'Set up your capital';

  @override
  String get dashboardEmptySubtitle =>
      'Define your initial capital and add your broker accounts.';

  @override
  String get configureCapitalCta => 'Set up my capital';

  @override
  String get addBrokerAccount => 'Add broker account';

  @override
  String get completeSetupBanner => 'Complete your setup';

  @override
  String get dashboardLoadError => 'We couldn\'t load your capital';

  @override
  String get capitalTotalLabel => 'Total capital';

  @override
  String get allocatedLabel => 'Allocated';

  @override
  String get availableLabel => 'Available';

  @override
  String get ofCapital => 'of capital';

  @override
  String get accountDetailComingSoon => 'Coming soon';

  @override
  String get editAccount => 'Edit account';

  @override
  String get accountNotFound => 'Account not found';

  @override
  String get save => 'Save';

  @override
  String get navPortfolio => 'Brokers';

  @override
  String get navAcademy => 'Academy';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navSettings => 'Settings';

  @override
  String get navRelations => 'Relations';

  @override
  String get relationsTitle => 'Asset relationships';

  @override
  String get relationsAssetsSection => 'Assets';

  @override
  String get relationsSectorsSection => 'Sectors';

  @override
  String get relationsColPrincipal => 'Primary Asset';

  @override
  String get relationsColEtfs => 'ETFs (x2, x3)';

  @override
  String get relationsColInverse => 'Inverse Asset';

  @override
  String get relationsColSector => 'Sector';

  @override
  String get relationsFavorites => 'Favorites';

  @override
  String get favoriteError => 'Could not update favorite. Please try again.';

  @override
  String get relationsSearchHint => 'Search asset by symbol or name…';

  @override
  String get relationsNoResults => 'No assets match your search.';

  @override
  String get relationsAssetsEmpty => 'No assets with relationships loaded.';

  @override
  String get relationsSectorsEmpty => 'No sectors loaded.';

  @override
  String get relationsError => 'Could not load asset relationships.';

  @override
  String get relationsRetry => 'Retry';

  @override
  String get settingsInterface => 'Interface';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEs => 'Spanish';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsChangePassword => 'Change Password';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get academyComingSoon =>
      'Investep Academy educational content will be available soon.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete account?';

  @override
  String get deleteAccountConfirmMessage =>
      'Are you sure you want to delete this broker account? The allocated balance will return to your available capital.';

  @override
  String get cancel => 'Cancel';

  @override
  String get settingsCapitalTitle => 'Capital';

  @override
  String get settingsCapitalTotal => 'Initial capital';

  @override
  String get settingsEditCapital => 'Modify initial capital';

  @override
  String get settingsEditCapitalHint =>
      'Enter the new amount for your initial capital.';

  @override
  String get loginTitle => 'Sign In';

  @override
  String get loginSubtitle => 'Enter your credentials to access.';

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSubmitButton => 'Sign In';

  @override
  String get loginAuthenticating => 'Authenticating and validating...';

  @override
  String get loginAuthError => 'Authentication Error';

  @override
  String get operationNewTitle => 'New Operation';

  @override
  String get operationEditTitle => 'Edit Operation';

  @override
  String get operationTicker => 'Ticker / Symbol';

  @override
  String get operationOpenedAt => 'Purchase Date';

  @override
  String get operationQty => 'Quantity';

  @override
  String get operationBuyPrice => 'Buy Price';

  @override
  String get operationLimitPrice => 'Limit Price (Optional)';

  @override
  String get operationStrategy => 'Strategy (Optional)';

  @override
  String get operationNotes => 'Notes';

  @override
  String get operationUrl => 'Reference URL';

  @override
  String get operationStrike => 'Strike Price';

  @override
  String get operationExpirationDate => 'Expiration Date';

  @override
  String get operationContractType => 'Contract Type';

  @override
  String get operationSave => 'Save';

  @override
  String get operationDelete => 'Delete';

  @override
  String get operationDeleted => 'Operation deleted successfully';

  @override
  String get operationSaved => 'Operation saved successfully';

  @override
  String get operationSuggestUrl => 'Suggest Yahoo Finance URL';

  @override
  String get loginRegisterButton => 'Register';

  @override
  String get loginRegisterHint => 'To register, please contact the sales team';
}
