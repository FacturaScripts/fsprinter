// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FS Printer';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String configLoadError(String error) {
    return 'Error loading configuration: $error';
  }

  @override
  String saveError(String error) {
    return 'Could not save: $error';
  }

  @override
  String get emptyTitle => 'No links configured';

  @override
  String get emptyBody =>
      'Add a link between a FacturaScripts\ninstallation and a printer on this device.';

  @override
  String get addLink => 'Add link';

  @override
  String get wsConnected => 'Connected';

  @override
  String get wsConnecting => 'Connecting…';

  @override
  String get wsError => 'Connection error';

  @override
  String get wsDisconnected => 'Disconnected';

  @override
  String get paused => 'Paused';

  @override
  String get noPrinter => 'No printer';

  @override
  String printerLine(String name) {
    return 'Printer: $name';
  }

  @override
  String activityAt(String time) {
    return 'activity $time';
  }

  @override
  String errorLine(String error) {
    return 'error: $error';
  }

  @override
  String get updateRequiredShort => '⚠ Some tickets require updating fsprinter';

  @override
  String get editTooltip => 'Edit';

  @override
  String get deleteTooltip => 'Delete';

  @override
  String get pullNow => 'Check for jobs now';

  @override
  String get testTicket => 'Test ticket';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get recentJobs => 'Recent jobs';

  @override
  String get noJobsYet => 'No jobs have been printed yet.';

  @override
  String get linkHasNoPrinter => 'This link has no printer';

  @override
  String get testTicketSent => 'Test ticket sent';

  @override
  String get deleteLinkTitle => 'Delete link';

  @override
  String deleteLinkBody(String name) {
    return 'Delete \"$name\"? The printer will remain registered in FacturaScripts.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get infoUrl => 'URL';

  @override
  String get infoPrinter => 'Printer';

  @override
  String get infoState => 'State';

  @override
  String get infoPrinterId => 'Printer ID in FS';

  @override
  String get infoLastActivity => 'Last activity';

  @override
  String get infoLineLen => 'Characters per line';

  @override
  String get infoLastError => 'Last error';

  @override
  String get infoNotice => 'Notice';

  @override
  String get updateRequiredLong => 'Some tickets require updating fsprinter';

  @override
  String ticketN(int id) {
    return 'Ticket $id';
  }

  @override
  String attemptsN(int count) {
    return '$count attempts';
  }

  @override
  String get newLink => 'New link';

  @override
  String get editLink => 'Edit link';

  @override
  String get stepConnection => 'FacturaScripts installation';

  @override
  String get stepPrinter => 'Printer';

  @override
  String get stepOptions => 'Options and test';

  @override
  String get save => 'Save';

  @override
  String get continueLabel => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get linkName => 'Link name';

  @override
  String get linkNameHint => 'Downtown store — till 1';

  @override
  String get installUrl => 'Installation URL';

  @override
  String get apiKeyLabel => 'Printer API key';

  @override
  String get apiKeyHelp =>
      'You will find it in FacturaScripts, on the printer page of the Tickets plugin';

  @override
  String get testConnection => 'Test connection';

  @override
  String connectionOk(int id) {
    return 'Connection OK (printer #$id)';
  }

  @override
  String get fillUrlAndKey => 'Fill in the URL and the API key';

  @override
  String get transportNetwork => 'Network';

  @override
  String get transportSpooler => 'System';

  @override
  String get transportBluetooth => 'Bluetooth';

  @override
  String get transportUsb => 'USB';

  @override
  String get helpNetwork => 'Network printer (RAW/JetDirect, port 9100).';

  @override
  String get helpSpooler =>
      'Any printer installed on this computer (USB, network or Bluetooth already configured).';

  @override
  String get helpBluetooth =>
      'Thermal Bluetooth printers paired with this device.';

  @override
  String get helpUsb => 'Printers connected to this device via USB cable.';

  @override
  String get printerHost => 'Printer IP address or host';

  @override
  String get printerPort => 'Port';

  @override
  String get printerField => 'Printer';

  @override
  String get refreshList => 'Refresh list';

  @override
  String get noPrintersFound => 'No printers found.';

  @override
  String get check => 'Check';

  @override
  String get printerResponds => 'The printer responds';

  @override
  String get printerNotResponding => 'The printer is not responding';

  @override
  String get selectPrinter => 'Select a printer';

  @override
  String get enterPrinterAddress => 'Enter the printer address';

  @override
  String get lineLenLabel => 'Characters per line';

  @override
  String get lineLenHelp => '48 for 80 mm paper, 32 for 58 mm paper';

  @override
  String get pollingLabel => 'Backup polling';

  @override
  String get pollingWsOnly => 'Instant notification only (WebSocket)';

  @override
  String get pollingEvery30s => 'Every 30 seconds';

  @override
  String get pollingEvery1m => 'Every minute';

  @override
  String get pollingEvery2m => 'Every 2 minutes';

  @override
  String get pollingEvery5m => 'Every 5 minutes';

  @override
  String get pollingEvery10m => 'Every 10 minutes';

  @override
  String get pollingEvery30m => 'Every 30 minutes';

  @override
  String get sendInitTitle => 'Initialize printer before each job';

  @override
  String get sendInitHelp => 'Prepends ESC @ (recommended for tickets)';

  @override
  String get printTestTicket => 'Print test ticket';

  @override
  String get ticketSent => 'Ticket sent';

  @override
  String get configurePrinterFirst => 'Configure the printer first (step 2)';

  @override
  String get launchAtStartupTitle => 'Launch at login';

  @override
  String get launchAtStartupHelp =>
      'fsprinter will open automatically when the computer starts';

  @override
  String get startHiddenTitle => 'Start hidden';

  @override
  String get startHiddenHelp => 'Tray icon only, without opening the window';

  @override
  String get trayNoticeTitle => 'Closing the window does not stop printing';

  @override
  String get trayNoticeBody =>
      'The app stays in the system tray. To quit completely use \"Quit\" in the tray menu.';

  @override
  String get kioskTitle => 'Kiosk mode';

  @override
  String get kioskHelp =>
      'Keeps the screen on so the system does not freeze the app. Recommended for tablets dedicated to printing.';

  @override
  String get iosBackgroundTitle => 'Background printing on iOS';

  @override
  String get iosBackgroundBody =>
      'iOS freezes apps in the background: with the app closed, printing depends on the push notification and is not guaranteed by the system. For unattended use, enable kiosk mode or use the desktop app.';

  @override
  String get androidBackgroundTitle => 'Background printing';

  @override
  String get androidBackgroundBody =>
      'The \"FS Printer active\" service keeps the connection alive with the screen off. Disable battery optimization for fsprinter if your vendor kills the app.';

  @override
  String get exportConfigTitle => 'Export configuration';

  @override
  String get exportConfigHelp =>
      'Copy all links (including API keys) to move them to another device';

  @override
  String get exportWarning =>
      'This text includes your printers\' API keys: treat it like a password.';

  @override
  String get copyToClipboard => 'Copy';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get importConfigTitle => 'Import configuration';

  @override
  String get importConfigHelp =>
      'Paste here a configuration exported from another device';

  @override
  String get importField => 'Exported configuration';

  @override
  String get importAction => 'Import';

  @override
  String importedLinks(int count) {
    return '$count links imported';
  }

  @override
  String get importInvalid => 'The text is not a valid configuration';

  @override
  String get close => 'Close';
}
