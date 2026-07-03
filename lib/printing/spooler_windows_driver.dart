import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../models/printer_ref.dart';
import 'printer_driver.dart';

// Binding FFI mínimo contra winspool.drv para envío RAW al spooler de
// Windows (equivalente al RawPrint.exe que usaba mc20printer):
// OpenPrinterW → StartDocPrinterW (datatype RAW) → StartPagePrinter →
// WritePrinter → EndPagePrinter → EndDocPrinter → ClosePrinter.

final class _DocInfo1 extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

final class _PrinterInfo4 extends Struct {
  external Pointer<Utf16> pPrinterName;
  external Pointer<Utf16> pServerName;
  @Uint32()
  external int attributes;
}

class _Winspool {
  static _Winspool? _instance;

  final DynamicLibrary _lib;

  _Winspool._() : _lib = DynamicLibrary.open('winspool.drv');

  factory _Winspool() => _instance ??= _Winspool._();

  late final openPrinter = _lib.lookupFunction<
      Int32 Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>),
      int Function(
          Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>)>('OpenPrinterW');

  late final closePrinter = _lib.lookupFunction<Int32 Function(IntPtr),
      int Function(int)>('ClosePrinter');

  late final startDocPrinter = _lib.lookupFunction<
      Uint32 Function(IntPtr, Uint32, Pointer<_DocInfo1>),
      int Function(int, int, Pointer<_DocInfo1>)>('StartDocPrinterW');

  late final endDocPrinter = _lib.lookupFunction<Int32 Function(IntPtr),
      int Function(int)>('EndDocPrinter');

  late final startPagePrinter = _lib.lookupFunction<Int32 Function(IntPtr),
      int Function(int)>('StartPagePrinter');

  late final endPagePrinter = _lib.lookupFunction<Int32 Function(IntPtr),
      int Function(int)>('EndPagePrinter');

  late final writePrinter = _lib.lookupFunction<
      Int32 Function(IntPtr, Pointer<Void>, Uint32, Pointer<Uint32>),
      int Function(int, Pointer<Void>, int, Pointer<Uint32>)>('WritePrinter');

  late final enumPrinters = _lib.lookupFunction<
      Int32 Function(Uint32, Pointer<Utf16>, Uint32, Pointer<Uint8>, Uint32,
          Pointer<Uint32>, Pointer<Uint32>),
      int Function(int, Pointer<Utf16>, int, Pointer<Uint8>, int,
          Pointer<Uint32>, Pointer<Uint32>)>('EnumPrintersW');
}

/// Impresión RAW vía spooler de Windows.
class SpoolerWindowsDriver implements PrinterDriver {
  @override
  final PrinterRef printer;

  const SpoolerWindowsDriver(this.printer);

  @override
  Future<void> sendRaw(Uint8List bytes) async {
    final winspool = _Winspool();
    final namePtr = printer.address.toNativeUtf16();
    final handlePtr = calloc<IntPtr>();

    try {
      if (winspool.openPrinter(namePtr, handlePtr, nullptr) == 0) {
        throw PrinterException(
            'No se pudo abrir la impresora "${printer.address}"');
      }
      final handle = handlePtr.value;

      final docInfo = calloc<_DocInfo1>();
      final docName = 'fsprinter'.toNativeUtf16();
      final datatype = 'RAW'.toNativeUtf16();
      docInfo.ref.pDocName = docName;
      docInfo.ref.pOutputFile = nullptr;
      docInfo.ref.pDatatype = datatype;

      final buffer = calloc<Uint8>(bytes.length);
      final written = calloc<Uint32>();

      try {
        if (winspool.startDocPrinter(handle, 1, docInfo) == 0) {
          throw PrinterException(
              'No se pudo iniciar el documento en "${printer.address}"');
        }
        try {
          winspool.startPagePrinter(handle);
          buffer.asTypedList(bytes.length).setAll(0, bytes);
          final ok = winspool.writePrinter(
              handle, buffer.cast(), bytes.length, written);
          winspool.endPagePrinter(handle);

          if (ok == 0 || written.value != bytes.length) {
            throw PrinterException(
                'Escritura incompleta en "${printer.address}" '
                '(${written.value}/${bytes.length} bytes)');
          }
        } finally {
          winspool.endDocPrinter(handle);
        }
      } finally {
        winspool.closePrinter(handle);
        calloc.free(buffer);
        calloc.free(written);
        calloc.free(docInfo);
        calloc.free(docName);
        calloc.free(datatype);
      }
    } finally {
      calloc.free(namePtr);
      calloc.free(handlePtr);
    }
  }

  @override
  Future<bool> isAvailable() async {
    final printers = await const SpoolerWindowsDiscovery().discover();
    return printers.any((p) => p.address == printer.address);
  }
}

/// Descubrimiento de impresoras instaladas en Windows (EnumPrintersW,
/// nivel 4: locales + conexiones de red del usuario).
class SpoolerWindowsDiscovery implements PrinterDiscovery {
  static const _printerEnumLocal = 0x00000002;
  static const _printerEnumConnections = 0x00000004;

  const SpoolerWindowsDiscovery();

  @override
  Future<List<PrinterRef>> discover() async {
    final winspool = _Winspool();
    const flags = _printerEnumLocal | _printerEnumConnections;

    final needed = calloc<Uint32>();
    final returned = calloc<Uint32>();
    try {
      // Primera llamada: obtener el tamaño de buffer necesario.
      winspool.enumPrinters(flags, nullptr, 4, nullptr, 0, needed, returned);
      final size = needed.value;
      if (size == 0) {
        return [];
      }

      final buffer = calloc<Uint8>(size);
      try {
        final ok = winspool.enumPrinters(
            flags, nullptr, 4, buffer, size, needed, returned);
        if (ok == 0) {
          return [];
        }

        final infos = buffer.cast<_PrinterInfo4>();
        final result = <PrinterRef>[];
        for (var i = 0; i < returned.value; i++) {
          final info = (infos + i).ref;
          if (info.pPrinterName == nullptr) {
            continue;
          }
          final name = info.pPrinterName.toDartString();
          result.add(PrinterRef(
            type: PrinterType.spooler,
            address: name,
            label: name,
          ));
        }
        return result;
      } finally {
        calloc.free(buffer);
      }
    } finally {
      calloc.free(needed);
      calloc.free(returned);
    }
  }
}
