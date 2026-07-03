import 'dart:io';
import 'dart:ui' show Size;

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Comportamiento de escritorio: cerrar la ventana la oculta a la bandeja
/// del sistema (la app sigue imprimiendo en segundo plano) y el icono de
/// bandeja permite mostrarla de nuevo o salir del todo.
class TrayService with TrayListener, WindowListener {
  static bool get isSupported =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  bool _initialized = false;

  Future<void> init({bool startHidden = false}) async {
    if (!isSupported || _initialized) {
      return;
    }
    _initialized = true;

    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    trayManager.addListener(this);

    await trayManager.setIcon(
      Platform.isWindows
          ? 'assets/tray/tray_icon.ico'
          : 'assets/tray/tray_icon.png',
      isTemplate: Platform.isMacOS,
    );
    if (!Platform.isLinux) {
      await trayManager.setToolTip('FS Printer');
    }
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: 'Mostrar FS Printer'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Salir'),
    ]));

    const options = WindowOptions(
      title: 'FS Printer',
      size: Size(560, 720),
      minimumSize: Size(420, 520),
      center: true,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      // Cerrar no destruye la ventana: se intercepta en onWindowClose.
      await windowManager.setPreventClose(true);
      if (!startHidden) {
        await windowManager.show();
        await windowManager.focus();
      }
    });
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    await windowManager.setPreventClose(false);
    await trayManager.destroy();
    await windowManager.destroy();
  }

  @override
  void onWindowClose() async {
    if (await windowManager.isPreventClose()) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() async {
    if (Platform.isMacOS) {
      // En macOS el clic en la bandeja despliega el menú.
      await trayManager.popUpContextMenu();
    } else {
      await _showWindow();
    }
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await _showWindow();
      case 'quit':
        await _quit();
    }
  }
}
