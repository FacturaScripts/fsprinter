// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'FS Printer';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String configLoadError(String error) {
    return 'Error cargando la configuración: $error';
  }

  @override
  String saveError(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String get emptyTitle => 'Sin vínculos configurados';

  @override
  String get emptyBody =>
      'Añade un vínculo entre una instalación de\nFacturaScripts y una impresora de este dispositivo.';

  @override
  String get addLink => 'Añadir vínculo';

  @override
  String get wsConnected => 'Conectado';

  @override
  String get wsConnecting => 'Conectando…';

  @override
  String get wsError => 'Error de conexión';

  @override
  String get wsDisconnected => 'Desconectado';

  @override
  String get paused => 'En pausa';

  @override
  String get noPrinter => 'Sin impresora';

  @override
  String printerLine(String name) {
    return 'Impresora: $name';
  }

  @override
  String activityAt(String time) {
    return 'actividad $time';
  }

  @override
  String errorLine(String error) {
    return 'error: $error';
  }

  @override
  String get updateRequiredShort =>
      '⚠ Hay tickets que requieren actualizar fsprinter';

  @override
  String get editTooltip => 'Editar';

  @override
  String get deleteTooltip => 'Eliminar';

  @override
  String get pullNow => 'Buscar trabajos ahora';

  @override
  String get testTicket => 'Ticket de prueba';

  @override
  String get pause => 'Pausar';

  @override
  String get resume => 'Reanudar';

  @override
  String get recentJobs => 'Últimos trabajos';

  @override
  String get noJobsYet => 'Todavía no se ha impreso ningún trabajo.';

  @override
  String get linkHasNoPrinter => 'El vínculo no tiene impresora';

  @override
  String get testTicketSent => 'Ticket de prueba enviado';

  @override
  String get deleteLinkTitle => 'Eliminar vínculo';

  @override
  String deleteLinkBody(String name) {
    return '¿Eliminar \"$name\"? La impresora seguirá registrada en FacturaScripts.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get infoUrl => 'URL';

  @override
  String get infoPrinter => 'Impresora';

  @override
  String get infoState => 'Estado';

  @override
  String get infoPrinterId => 'Nº impresora en FS';

  @override
  String get infoLastActivity => 'Última actividad';

  @override
  String get infoLineLen => 'Caracteres por línea';

  @override
  String get infoLastError => 'Último error';

  @override
  String get infoNotice => 'Aviso';

  @override
  String get updateRequiredLong =>
      'Hay tickets que requieren actualizar fsprinter';

  @override
  String ticketN(int id) {
    return 'Ticket $id';
  }

  @override
  String attemptsN(int count) {
    return '$count intentos';
  }

  @override
  String get newLink => 'Nuevo vínculo';

  @override
  String get editLink => 'Editar vínculo';

  @override
  String get stepConnection => 'Instalación de FacturaScripts';

  @override
  String get stepPrinter => 'Impresora';

  @override
  String get stepOptions => 'Opciones y prueba';

  @override
  String get save => 'Guardar';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get back => 'Atrás';

  @override
  String get linkName => 'Nombre del vínculo';

  @override
  String get linkNameHint => 'Tienda centro — caja 1';

  @override
  String get installUrl => 'URL de la instalación';

  @override
  String get apiKeyLabel => 'API key de la impresora';

  @override
  String get apiKeyHelp =>
      'La encontrarás en FacturaScripts, en la ficha de la impresora del plugin Tickets';

  @override
  String get testConnection => 'Probar conexión';

  @override
  String connectionOk(int id) {
    return 'Conexión correcta (impresora nº $id)';
  }

  @override
  String get fillUrlAndKey => 'Rellena la URL y la API key';

  @override
  String get transportNetwork => 'Red';

  @override
  String get transportSpooler => 'Sistema';

  @override
  String get transportBluetooth => 'Bluetooth';

  @override
  String get transportUsb => 'USB';

  @override
  String get helpNetwork => 'Impresora de red (RAW/JetDirect, puerto 9100).';

  @override
  String get helpSpooler =>
      'Cualquier impresora instalada en este equipo (USB, red o Bluetooth ya configuradas).';

  @override
  String get helpBluetooth =>
      'Impresoras térmicas Bluetooth emparejadas con este dispositivo.';

  @override
  String get helpUsb =>
      'Impresoras conectadas por cable USB a este dispositivo.';

  @override
  String get printerHost => 'Dirección IP o host de la impresora';

  @override
  String get printerPort => 'Puerto';

  @override
  String get printerField => 'Impresora';

  @override
  String get refreshList => 'Actualizar lista';

  @override
  String get noPrintersFound => 'No se han encontrado impresoras.';

  @override
  String get check => 'Comprobar';

  @override
  String get printerResponds => 'La impresora responde';

  @override
  String get printerNotResponding => 'La impresora no responde';

  @override
  String get selectPrinter => 'Selecciona una impresora';

  @override
  String get enterPrinterAddress => 'Indica la dirección de la impresora';

  @override
  String get lineLenLabel => 'Caracteres por línea';

  @override
  String get lineLenHelp => '48 para papel de 80 mm, 32 para papel de 58 mm';

  @override
  String get pollingLabel => 'Comprobación de respaldo';

  @override
  String get pollingWsOnly => 'Solo aviso instantáneo (WebSocket)';

  @override
  String get pollingEvery30s => 'Cada 30 segundos';

  @override
  String get pollingEvery1m => 'Cada minuto';

  @override
  String get pollingEvery2m => 'Cada 2 minutos';

  @override
  String get pollingEvery5m => 'Cada 5 minutos';

  @override
  String get pollingEvery10m => 'Cada 10 minutos';

  @override
  String get pollingEvery30m => 'Cada 30 minutos';

  @override
  String get sendInitTitle => 'Inicializar impresora antes de cada trabajo';

  @override
  String get sendInitHelp => 'Antepone ESC @ (recomendado para tickets)';

  @override
  String get printTestTicket => 'Imprimir ticket de prueba';

  @override
  String get ticketSent => 'Ticket enviado';

  @override
  String get configurePrinterFirst => 'Configura antes la impresora (paso 2)';

  @override
  String get launchAtStartupTitle => 'Arrancar al iniciar sesión';

  @override
  String get launchAtStartupHelp =>
      'fsprinter se abrirá automáticamente al encender el equipo';

  @override
  String get startHiddenTitle => 'Arrancar oculto';

  @override
  String get startHiddenHelp =>
      'Solo el icono de bandeja, sin abrir la ventana';

  @override
  String get trayNoticeTitle => 'Cerrar la ventana no detiene la impresión';

  @override
  String get trayNoticeBody =>
      'La app queda en la bandeja del sistema. Para salir del todo usa \"Salir\" en el menú de la bandeja.';

  @override
  String get kioskTitle => 'Modo kiosco';

  @override
  String get kioskHelp =>
      'Mantiene la pantalla encendida para que el sistema no congele la app. Recomendado en tablets dedicadas a imprimir.';

  @override
  String get iosBackgroundTitle => 'Impresión en segundo plano en iOS';

  @override
  String get iosBackgroundBody =>
      'iOS congela las apps en segundo plano: con la app cerrada, la impresión depende del aviso push y no está garantizada por el sistema. Para uso desatendido, activa el modo kiosco o usa la app de escritorio.';

  @override
  String get androidBackgroundTitle => 'Impresión en segundo plano';

  @override
  String get androidBackgroundBody =>
      'El servicio \"FS Printer activo\" mantiene la conexión con la pantalla apagada. Desactiva la optimización de batería para fsprinter si tu fabricante mata la app.';

  @override
  String get exportConfigTitle => 'Exportar configuración';

  @override
  String get exportConfigHelp =>
      'Copia todos los vínculos (incluidas las API keys) para llevarlos a otro dispositivo';

  @override
  String get exportWarning =>
      'Este texto incluye las API keys de tus impresoras: trátalo como una contraseña.';

  @override
  String get copyToClipboard => 'Copiar';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get importConfigTitle => 'Importar configuración';

  @override
  String get importConfigHelp =>
      'Pega aquí una configuración exportada desde otro dispositivo';

  @override
  String get importField => 'Configuración exportada';

  @override
  String get importAction => 'Importar';

  @override
  String importedLinks(int count) {
    return '$count vínculos importados';
  }

  @override
  String get importInvalid => 'El texto no es una configuración válida';

  @override
  String get close => 'Cerrar';
}
