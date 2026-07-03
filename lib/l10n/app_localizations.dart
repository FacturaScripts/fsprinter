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
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  /// **'FS Printer'**
  String get appTitle;

  /// No description provided for @settingsTooltip.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTooltip;

  /// No description provided for @configLoadError.
  ///
  /// In es, this message translates to:
  /// **'Error cargando la configuración: {error}'**
  String configLoadError(String error);

  /// No description provided for @saveError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo guardar: {error}'**
  String saveError(String error);

  /// No description provided for @emptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin vínculos configurados'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In es, this message translates to:
  /// **'Añade un vínculo entre una instalación de\nFacturaScripts y una impresora de este dispositivo.'**
  String get emptyBody;

  /// No description provided for @addLink.
  ///
  /// In es, this message translates to:
  /// **'Añadir vínculo'**
  String get addLink;

  /// No description provided for @wsConnected.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get wsConnected;

  /// No description provided for @wsConnecting.
  ///
  /// In es, this message translates to:
  /// **'Conectando…'**
  String get wsConnecting;

  /// No description provided for @wsError.
  ///
  /// In es, this message translates to:
  /// **'Error de conexión'**
  String get wsError;

  /// No description provided for @wsDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Desconectado'**
  String get wsDisconnected;

  /// No description provided for @paused.
  ///
  /// In es, this message translates to:
  /// **'En pausa'**
  String get paused;

  /// No description provided for @noPrinter.
  ///
  /// In es, this message translates to:
  /// **'Sin impresora'**
  String get noPrinter;

  /// No description provided for @printerLine.
  ///
  /// In es, this message translates to:
  /// **'Impresora: {name}'**
  String printerLine(String name);

  /// No description provided for @activityAt.
  ///
  /// In es, this message translates to:
  /// **'actividad {time}'**
  String activityAt(String time);

  /// No description provided for @errorLine.
  ///
  /// In es, this message translates to:
  /// **'error: {error}'**
  String errorLine(String error);

  /// No description provided for @updateRequiredShort.
  ///
  /// In es, this message translates to:
  /// **'⚠ Hay tickets que requieren actualizar fsprinter'**
  String get updateRequiredShort;

  /// No description provided for @editTooltip.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get editTooltip;

  /// No description provided for @deleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get deleteTooltip;

  /// No description provided for @pullNow.
  ///
  /// In es, this message translates to:
  /// **'Buscar trabajos ahora'**
  String get pullNow;

  /// No description provided for @testTicket.
  ///
  /// In es, this message translates to:
  /// **'Ticket de prueba'**
  String get testTicket;

  /// No description provided for @pause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get resume;

  /// No description provided for @recentJobs.
  ///
  /// In es, this message translates to:
  /// **'Últimos trabajos'**
  String get recentJobs;

  /// No description provided for @noJobsYet.
  ///
  /// In es, this message translates to:
  /// **'Todavía no se ha impreso ningún trabajo.'**
  String get noJobsYet;

  /// No description provided for @linkHasNoPrinter.
  ///
  /// In es, this message translates to:
  /// **'El vínculo no tiene impresora'**
  String get linkHasNoPrinter;

  /// No description provided for @testTicketSent.
  ///
  /// In es, this message translates to:
  /// **'Ticket de prueba enviado'**
  String get testTicketSent;

  /// No description provided for @deleteLinkTitle.
  ///
  /// In es, this message translates to:
  /// **'Eliminar vínculo'**
  String get deleteLinkTitle;

  /// No description provided for @deleteLinkBody.
  ///
  /// In es, this message translates to:
  /// **'¿Eliminar \"{name}\"? La impresora seguirá registrada en FacturaScripts.'**
  String deleteLinkBody(String name);

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get delete;

  /// No description provided for @infoUrl.
  ///
  /// In es, this message translates to:
  /// **'URL'**
  String get infoUrl;

  /// No description provided for @infoPrinter.
  ///
  /// In es, this message translates to:
  /// **'Impresora'**
  String get infoPrinter;

  /// No description provided for @infoState.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get infoState;

  /// No description provided for @infoPrinterId.
  ///
  /// In es, this message translates to:
  /// **'Nº impresora en FS'**
  String get infoPrinterId;

  /// No description provided for @infoLastActivity.
  ///
  /// In es, this message translates to:
  /// **'Última actividad'**
  String get infoLastActivity;

  /// No description provided for @infoLineLen.
  ///
  /// In es, this message translates to:
  /// **'Caracteres por línea'**
  String get infoLineLen;

  /// No description provided for @infoLastError.
  ///
  /// In es, this message translates to:
  /// **'Último error'**
  String get infoLastError;

  /// No description provided for @infoNotice.
  ///
  /// In es, this message translates to:
  /// **'Aviso'**
  String get infoNotice;

  /// No description provided for @updateRequiredLong.
  ///
  /// In es, this message translates to:
  /// **'Hay tickets que requieren actualizar fsprinter'**
  String get updateRequiredLong;

  /// No description provided for @ticketN.
  ///
  /// In es, this message translates to:
  /// **'Ticket {id}'**
  String ticketN(int id);

  /// No description provided for @attemptsN.
  ///
  /// In es, this message translates to:
  /// **'{count} intentos'**
  String attemptsN(int count);

  /// No description provided for @newLink.
  ///
  /// In es, this message translates to:
  /// **'Nuevo vínculo'**
  String get newLink;

  /// No description provided for @editLink.
  ///
  /// In es, this message translates to:
  /// **'Editar vínculo'**
  String get editLink;

  /// No description provided for @stepConnection.
  ///
  /// In es, this message translates to:
  /// **'Instalación de FacturaScripts'**
  String get stepConnection;

  /// No description provided for @stepPrinter.
  ///
  /// In es, this message translates to:
  /// **'Impresora'**
  String get stepPrinter;

  /// No description provided for @stepOptions.
  ///
  /// In es, this message translates to:
  /// **'Opciones y prueba'**
  String get stepOptions;

  /// No description provided for @save.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get save;

  /// No description provided for @continueLabel.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @linkName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del vínculo'**
  String get linkName;

  /// No description provided for @linkNameHint.
  ///
  /// In es, this message translates to:
  /// **'Tienda centro — caja 1'**
  String get linkNameHint;

  /// No description provided for @installUrl.
  ///
  /// In es, this message translates to:
  /// **'URL de la instalación'**
  String get installUrl;

  /// No description provided for @apiKeyLabel.
  ///
  /// In es, this message translates to:
  /// **'API key de la impresora'**
  String get apiKeyLabel;

  /// No description provided for @apiKeyHelp.
  ///
  /// In es, this message translates to:
  /// **'La encontrarás en FacturaScripts, en la ficha de la impresora del plugin Tickets'**
  String get apiKeyHelp;

  /// No description provided for @testConnection.
  ///
  /// In es, this message translates to:
  /// **'Probar conexión'**
  String get testConnection;

  /// No description provided for @connectionOk.
  ///
  /// In es, this message translates to:
  /// **'Conexión correcta (impresora nº {id})'**
  String connectionOk(int id);

  /// No description provided for @fillUrlAndKey.
  ///
  /// In es, this message translates to:
  /// **'Rellena la URL y la API key'**
  String get fillUrlAndKey;

  /// No description provided for @transportNetwork.
  ///
  /// In es, this message translates to:
  /// **'Red'**
  String get transportNetwork;

  /// No description provided for @transportSpooler.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get transportSpooler;

  /// No description provided for @transportBluetooth.
  ///
  /// In es, this message translates to:
  /// **'Bluetooth'**
  String get transportBluetooth;

  /// No description provided for @transportUsb.
  ///
  /// In es, this message translates to:
  /// **'USB'**
  String get transportUsb;

  /// No description provided for @helpNetwork.
  ///
  /// In es, this message translates to:
  /// **'Impresora de red (RAW/JetDirect, puerto 9100).'**
  String get helpNetwork;

  /// No description provided for @helpSpooler.
  ///
  /// In es, this message translates to:
  /// **'Cualquier impresora instalada en este equipo (USB, red o Bluetooth ya configuradas).'**
  String get helpSpooler;

  /// No description provided for @helpBluetooth.
  ///
  /// In es, this message translates to:
  /// **'Impresoras térmicas Bluetooth emparejadas con este dispositivo.'**
  String get helpBluetooth;

  /// No description provided for @helpUsb.
  ///
  /// In es, this message translates to:
  /// **'Impresoras conectadas por cable USB a este dispositivo.'**
  String get helpUsb;

  /// No description provided for @printerHost.
  ///
  /// In es, this message translates to:
  /// **'Dirección IP o host de la impresora'**
  String get printerHost;

  /// No description provided for @printerPort.
  ///
  /// In es, this message translates to:
  /// **'Puerto'**
  String get printerPort;

  /// No description provided for @printerField.
  ///
  /// In es, this message translates to:
  /// **'Impresora'**
  String get printerField;

  /// No description provided for @refreshList.
  ///
  /// In es, this message translates to:
  /// **'Actualizar lista'**
  String get refreshList;

  /// No description provided for @noPrintersFound.
  ///
  /// In es, this message translates to:
  /// **'No se han encontrado impresoras.'**
  String get noPrintersFound;

  /// No description provided for @check.
  ///
  /// In es, this message translates to:
  /// **'Comprobar'**
  String get check;

  /// No description provided for @printerResponds.
  ///
  /// In es, this message translates to:
  /// **'La impresora responde'**
  String get printerResponds;

  /// No description provided for @printerNotResponding.
  ///
  /// In es, this message translates to:
  /// **'La impresora no responde'**
  String get printerNotResponding;

  /// No description provided for @selectPrinter.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una impresora'**
  String get selectPrinter;

  /// No description provided for @enterPrinterAddress.
  ///
  /// In es, this message translates to:
  /// **'Indica la dirección de la impresora'**
  String get enterPrinterAddress;

  /// No description provided for @lineLenLabel.
  ///
  /// In es, this message translates to:
  /// **'Caracteres por línea'**
  String get lineLenLabel;

  /// No description provided for @lineLenHelp.
  ///
  /// In es, this message translates to:
  /// **'48 para papel de 80 mm, 32 para papel de 58 mm'**
  String get lineLenHelp;

  /// No description provided for @pollingLabel.
  ///
  /// In es, this message translates to:
  /// **'Comprobación de respaldo'**
  String get pollingLabel;

  /// No description provided for @pollingWsOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo aviso instantáneo (WebSocket)'**
  String get pollingWsOnly;

  /// No description provided for @pollingEvery30s.
  ///
  /// In es, this message translates to:
  /// **'Cada 30 segundos'**
  String get pollingEvery30s;

  /// No description provided for @pollingEvery1m.
  ///
  /// In es, this message translates to:
  /// **'Cada minuto'**
  String get pollingEvery1m;

  /// No description provided for @pollingEvery2m.
  ///
  /// In es, this message translates to:
  /// **'Cada 2 minutos'**
  String get pollingEvery2m;

  /// No description provided for @pollingEvery5m.
  ///
  /// In es, this message translates to:
  /// **'Cada 5 minutos'**
  String get pollingEvery5m;

  /// No description provided for @pollingEvery10m.
  ///
  /// In es, this message translates to:
  /// **'Cada 10 minutos'**
  String get pollingEvery10m;

  /// No description provided for @pollingEvery30m.
  ///
  /// In es, this message translates to:
  /// **'Cada 30 minutos'**
  String get pollingEvery30m;

  /// No description provided for @sendInitTitle.
  ///
  /// In es, this message translates to:
  /// **'Inicializar impresora antes de cada trabajo'**
  String get sendInitTitle;

  /// No description provided for @sendInitHelp.
  ///
  /// In es, this message translates to:
  /// **'Antepone ESC @ (recomendado para tickets)'**
  String get sendInitHelp;

  /// No description provided for @printTestTicket.
  ///
  /// In es, this message translates to:
  /// **'Imprimir ticket de prueba'**
  String get printTestTicket;

  /// No description provided for @ticketSent.
  ///
  /// In es, this message translates to:
  /// **'Ticket enviado'**
  String get ticketSent;

  /// No description provided for @configurePrinterFirst.
  ///
  /// In es, this message translates to:
  /// **'Configura antes la impresora (paso 2)'**
  String get configurePrinterFirst;

  /// No description provided for @launchAtStartupTitle.
  ///
  /// In es, this message translates to:
  /// **'Arrancar al iniciar sesión'**
  String get launchAtStartupTitle;

  /// No description provided for @launchAtStartupHelp.
  ///
  /// In es, this message translates to:
  /// **'fsprinter se abrirá automáticamente al encender el equipo'**
  String get launchAtStartupHelp;

  /// No description provided for @startHiddenTitle.
  ///
  /// In es, this message translates to:
  /// **'Arrancar oculto'**
  String get startHiddenTitle;

  /// No description provided for @startHiddenHelp.
  ///
  /// In es, this message translates to:
  /// **'Solo el icono de bandeja, sin abrir la ventana'**
  String get startHiddenHelp;

  /// No description provided for @trayNoticeTitle.
  ///
  /// In es, this message translates to:
  /// **'Cerrar la ventana no detiene la impresión'**
  String get trayNoticeTitle;

  /// No description provided for @trayNoticeBody.
  ///
  /// In es, this message translates to:
  /// **'La app queda en la bandeja del sistema. Para salir del todo usa \"Salir\" en el menú de la bandeja.'**
  String get trayNoticeBody;

  /// No description provided for @kioskTitle.
  ///
  /// In es, this message translates to:
  /// **'Modo kiosco'**
  String get kioskTitle;

  /// No description provided for @kioskHelp.
  ///
  /// In es, this message translates to:
  /// **'Mantiene la pantalla encendida para que el sistema no congele la app. Recomendado en tablets dedicadas a imprimir.'**
  String get kioskHelp;

  /// No description provided for @iosBackgroundTitle.
  ///
  /// In es, this message translates to:
  /// **'Impresión en segundo plano en iOS'**
  String get iosBackgroundTitle;

  /// No description provided for @iosBackgroundBody.
  ///
  /// In es, this message translates to:
  /// **'iOS congela las apps en segundo plano: con la app cerrada, la impresión depende del aviso push y no está garantizada por el sistema. Para uso desatendido, activa el modo kiosco o usa la app de escritorio.'**
  String get iosBackgroundBody;

  /// No description provided for @androidBackgroundTitle.
  ///
  /// In es, this message translates to:
  /// **'Impresión en segundo plano'**
  String get androidBackgroundTitle;

  /// No description provided for @androidBackgroundBody.
  ///
  /// In es, this message translates to:
  /// **'El servicio \"FS Printer activo\" mantiene la conexión con la pantalla apagada. Desactiva la optimización de batería para fsprinter si tu fabricante mata la app.'**
  String get androidBackgroundBody;

  /// No description provided for @exportConfigTitle.
  ///
  /// In es, this message translates to:
  /// **'Exportar configuración'**
  String get exportConfigTitle;

  /// No description provided for @exportConfigHelp.
  ///
  /// In es, this message translates to:
  /// **'Copia todos los vínculos (incluidas las API keys) para llevarlos a otro dispositivo'**
  String get exportConfigHelp;

  /// No description provided for @exportWarning.
  ///
  /// In es, this message translates to:
  /// **'Este texto incluye las API keys de tus impresoras: trátalo como una contraseña.'**
  String get exportWarning;

  /// No description provided for @copyToClipboard.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get copyToClipboard;

  /// No description provided for @copiedToClipboard.
  ///
  /// In es, this message translates to:
  /// **'Copiado al portapapeles'**
  String get copiedToClipboard;

  /// No description provided for @importConfigTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar configuración'**
  String get importConfigTitle;

  /// No description provided for @importConfigHelp.
  ///
  /// In es, this message translates to:
  /// **'Pega aquí una configuración exportada desde otro dispositivo'**
  String get importConfigHelp;

  /// No description provided for @importField.
  ///
  /// In es, this message translates to:
  /// **'Configuración exportada'**
  String get importField;

  /// No description provided for @importAction.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get importAction;

  /// No description provided for @importedLinks.
  ///
  /// In es, this message translates to:
  /// **'{count} vínculos importados'**
  String importedLinks(int count);

  /// No description provided for @importInvalid.
  ///
  /// In es, this message translates to:
  /// **'El texto no es una configuración válida'**
  String get importInvalid;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;
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
