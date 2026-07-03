import 'dart:io';

import '../models/printer_ref.dart';
import 'bluetooth_driver.dart';
import 'network_printer_driver.dart';
import 'printer_driver.dart';
import 'spooler_unix_driver.dart';
import 'spooler_windows_driver.dart';
import 'usb_android_driver.dart';

/// Devuelve el driver adecuado para una impresora según su transporte y
/// la plataforma actual.
PrinterDriver driverFor(PrinterRef printer) {
  switch (printer.type) {
    case PrinterType.network:
      return NetworkPrinterDriver(printer);
    case PrinterType.spooler:
      if (Platform.isWindows) {
        return SpoolerWindowsDriver(printer);
      }
      if (Platform.isMacOS || Platform.isLinux) {
        return SpoolerUnixDriver(printer);
      }
      throw const PrinterException(
          'El spooler del sistema solo está disponible en escritorio');
    case PrinterType.bluetooth:
      if (Platform.isAndroid || Platform.isIOS) {
        return BluetoothDriver(printer);
      }
      throw const PrinterException(
          'En escritorio, usa la impresora Bluetooth ya instalada en el '
          'sistema (transporte "Sistema")');
    case PrinterType.usb:
      if (Platform.isAndroid) {
        return UsbAndroidDriver(printer);
      }
      throw const PrinterException(
          'En escritorio, usa la impresora USB ya instalada en el '
          'sistema (transporte "Sistema")');
  }
}

/// Transportes disponibles en la plataforma actual, en orden de aparición
/// en el asistente.
List<PrinterType> availableTransports() {
  return [
    PrinterType.network,
    if (supportsSystemSpooler) PrinterType.spooler,
    if (Platform.isAndroid || Platform.isIOS) PrinterType.bluetooth,
    if (Platform.isAndroid) PrinterType.usb,
  ];
}

/// Descubre impresoras para un transporte con selección de dispositivo
/// (spooler, bluetooth o usb). Para red se introduce la IP a mano.
Future<List<PrinterRef>> discoverPrinters(PrinterType type) {
  switch (type) {
    case PrinterType.spooler:
      if (Platform.isWindows) {
        return const SpoolerWindowsDiscovery().discover();
      }
      if (Platform.isMacOS || Platform.isLinux) {
        return const SpoolerUnixDiscovery().discover();
      }
      return Future.value(const []);
    case PrinterType.bluetooth:
      return const BluetoothDiscovery().discover();
    case PrinterType.usb:
      return const UsbDiscovery().discover();
    case PrinterType.network:
      return Future.value(const []);
  }
}

/// ¿La plataforma actual tiene spooler de sistema utilizable?
bool get supportsSystemSpooler =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;
