import 'dart:io';
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../models/printer_ref.dart';
import 'printer_driver.dart';

/// Impresión por Bluetooth con print_bluetooth_thermal: Bluetooth clásico
/// en Android y BLE en iOS. [PrinterRef.address] es la MAC (Android) o el
/// identificador del dispositivo (iOS).
///
/// El plugin mantiene una única conexión Bluetooth global, así que la
/// conexión se establece por trabajo y el mutex por impresora de la cola
/// evita solapamientos.
class BluetoothDriver implements PrinterDriver {
  /// Tamaño de los bloques de escritura: las térmicas Bluetooth suelen
  /// perder datos con escrituras grandes de una sola vez.
  static const _chunkSize = 512;

  @override
  final PrinterRef printer;

  const BluetoothDriver(this.printer);

  @override
  Future<void> sendRaw(Uint8List bytes) async {
    await _ensureConnected();

    try {
      for (var offset = 0; offset < bytes.length; offset += _chunkSize) {
        final end = (offset + _chunkSize < bytes.length)
            ? offset + _chunkSize
            : bytes.length;
        final ok = await PrintBluetoothThermal.writeBytes(
            bytes.sublist(offset, end));
        if (!ok) {
          throw PrinterException(
              'Fallo escribiendo por Bluetooth en ${printer.address}');
        }
      }
    } on PrinterException {
      // Dejar la conexión cerrada para que el siguiente intento reconecte.
      await PrintBluetoothThermal.disconnect;
      rethrow;
    }
  }

  Future<void> _ensureConnected() async {
    if (await PrintBluetoothThermal.connectionStatus) {
      // El plugin solo mantiene una conexión: si es de otra impresora,
      // cerrarla antes de conectar con esta.
      await PrintBluetoothThermal.disconnect;
    }

    final connected = await PrintBluetoothThermal.connect(
        macPrinterAddress: printer.address);
    if (!connected) {
      throw PrinterException(
          'No se pudo conectar por Bluetooth con ${printer.address}');
    }
  }

  @override
  Future<bool> isAvailable() async {
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      return false;
    }
    final paired = await PrintBluetoothThermal.pairedBluetooths;
    return paired.any((device) => device.macAdress == printer.address);
  }
}

/// Impresoras Bluetooth emparejadas con el dispositivo.
class BluetoothDiscovery implements PrinterDiscovery {
  const BluetoothDiscovery();

  @override
  Future<List<PrinterRef>> discover() async {
    if (Platform.isAndroid) {
      // Android 12+ exige permisos runtime para listar/conectar.
      final statuses = await [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();
      if (statuses.values.any((status) => status.isDenied)) {
        return [];
      }
    }

    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      return [];
    }

    final paired = await PrintBluetoothThermal.pairedBluetooths;
    return paired
        .map((device) => PrinterRef(
              type: PrinterType.bluetooth,
              address: device.macAdress,
              label: device.name.isEmpty ? device.macAdress : device.name,
            ))
        .toList();
  }
}
