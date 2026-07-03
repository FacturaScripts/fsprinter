import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import '../models/printer_ref.dart';
import 'printer_driver.dart';

/// Impresión por USB directo en Android (usb_serial).
///
/// [PrinterRef.address] guarda `vid:pid` en decimal, estable aunque el
/// dispositivo cambie de puerto o de deviceId al reconectarse.
class UsbAndroidDriver implements PrinterDriver {
  @override
  final PrinterRef printer;

  const UsbAndroidDriver(this.printer);

  Future<UsbDevice?> _findDevice() async {
    final devices = await UsbSerial.listDevices();
    for (final device in devices) {
      if ('${device.vid}:${device.pid}' == printer.address) {
        return device;
      }
    }
    return null;
  }

  @override
  Future<void> sendRaw(Uint8List bytes) async {
    final device = await _findDevice();
    if (device == null) {
      throw PrinterException(
          'Impresora USB ${printer.address} no conectada');
    }

    final port = await device.create();
    if (port == null || !await port.open()) {
      throw PrinterException(
          'No se pudo abrir el puerto USB de ${printer.address} '
          '(¿permiso USB concedido?)');
    }

    try {
      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );
      await port.write(bytes);
      // Margen para que el buffer USB se vacíe antes de cerrar.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      throw PrinterException('Error escribiendo por USB: $e');
    } finally {
      await port.close();
    }
  }

  @override
  Future<bool> isAvailable() async => await _findDevice() != null;
}

/// Dispositivos USB serie conectados (Android pedirá permiso al usarlos).
class UsbDiscovery implements PrinterDiscovery {
  const UsbDiscovery();

  @override
  Future<List<PrinterRef>> discover() async {
    final devices = await UsbSerial.listDevices();
    return devices
        .map((device) => PrinterRef(
              type: PrinterType.usb,
              address: '${device.vid}:${device.pid}',
              label: device.productName?.isNotEmpty == true
                  ? device.productName!
                  : 'USB ${device.vid}:${device.pid}',
            ))
        .toList();
  }
}
