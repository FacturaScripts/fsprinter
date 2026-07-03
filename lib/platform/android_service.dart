import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../services/headless_pull.dart';

/// Punto de entrada del servicio en primer plano (isolate propio).
@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(_KeepAliveHandler());
}

/// El servicio existe sobre todo para mantener vivo el proceso (y con él
/// los WebSockets del isolate principal). Como respaldo anti-Doze, cada
/// repetición hace además un pull headless por si el isolate principal
/// estuviera congelado.
class _KeepAliveHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    await runHeadlessPull();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}

/// Servicio en primer plano de Android: mantiene la app imprimiendo con
/// la pantalla apagada. Usa el tipo `connectedDevice` (sin el límite
/// horario que Android 15 impone a `dataSync`).
class AndroidService {
  static bool get isSupported => Platform.isAndroid;

  Future<void> init() async {
    if (!isSupported) {
      return;
    }

    FlutterForegroundTask.initCommunicationPort();

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'fsprinter_service',
        channelName: 'Servicio de impresión',
        channelDescription:
            'Mantiene la conexión con FacturaScripts para imprimir al momento',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Pull de respaldo cada 15 minutos desde el isolate del servicio.
        eventAction: ForegroundTaskEventAction.repeat(15 * 60 * 1000),
        allowWakeLock: true,
      ),
    );
  }

  Future<void> start() async {
    if (!isSupported) {
      return;
    }

    await FlutterForegroundTask.requestNotificationPermission();

    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      serviceTypes: const [ForegroundServiceTypes.connectedDevice],
      serviceId: 257,
      notificationTitle: 'FS Printer activo',
      notificationText: 'Esperando trabajos de impresión',
      callback: startForegroundCallback,
    );
  }

  Future<void> stop() async {
    if (!isSupported) {
      return;
    }
    await FlutterForegroundTask.stopService();
  }
}
