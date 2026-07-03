import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/link_config.dart';
import '../../models/printer_ref.dart';
import '../../printing/driver_factory.dart';
import '../../printing/test_ticket.dart';
import '../../providers/providers.dart';
import '../../services/fs_api_client.dart';

/// Asistente de 3 pasos para crear o editar un vínculo:
/// ① conexión con FacturaScripts, ② impresora, ③ opciones y prueba.
class WizardScreen extends ConsumerStatefulWidget {
  /// Si se pasa un vínculo existente, el asistente lo edita.
  final LinkConfig? initial;

  const WizardScreen({super.key, this.initial});

  @override
  ConsumerState<WizardScreen> createState() => _WizardScreenState();
}

class _WizardScreenState extends ConsumerState<WizardScreen> {
  int _step = 0;

  // Paso 1: conexión
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _apiKey;
  bool _testingConnection = false;
  String _connectionResult = '';
  bool _connectionOk = false;

  // Paso 2: impresora
  late final List<PrinterType> _transports;
  PrinterType _transport = PrinterType.network;
  late final TextEditingController _host;
  late final TextEditingController _port;
  final Map<PrinterType, List<PrinterRef>> _devices = {};
  final Map<PrinterType, String?> _selectedDevice = {};
  bool _loadingDevices = false;
  bool _checkingPrinter = false;
  String _printerResult = '';

  // Paso 3: opciones
  late final TextEditingController _lineLen;
  late int _pollingSeconds;
  late bool _sendInit;
  bool _printingTest = false;
  String _testResult = '';

  bool get _needsDeviceList => _transport != PrinterType.network;

  @override
  void initState() {
    super.initState();
    _transports = availableTransports();

    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _url = TextEditingController(text: initial?.apiUrl ?? '');
    _apiKey = TextEditingController(text: initial?.apiKey ?? '');
    _host = TextEditingController(
        text: initial?.printer?.type == PrinterType.network
            ? initial!.printer!.address
            : '');
    _port =
        TextEditingController(text: '${initial?.printer?.port ?? 9100}');
    _lineLen = TextEditingController(text: '${initial?.lineLen ?? 48}');
    _pollingSeconds = initial?.pollingSeconds ?? 0;
    _sendInit = initial?.sendInit ?? true;
    _connectionOk = initial != null;

    final initialPrinter = initial?.printer;
    if (initialPrinter != null &&
        initialPrinter.type != PrinterType.network &&
        _transports.contains(initialPrinter.type)) {
      _transport = initialPrinter.type;
      _selectedDevice[initialPrinter.type] = initialPrinter.address;
    }

    if (_needsDeviceList) {
      _loadDevices();
    }
  }

  Future<void> _loadDevices() async {
    final transport = _transport;
    setState(() => _loadingDevices = true);
    final devices = await discoverPrinters(transport);
    if (!mounted) {
      return;
    }
    setState(() {
      _devices[transport] = devices;
      _loadingDevices = false;
      final selected = _selectedDevice[transport];
      if (selected != null &&
          !devices.any((device) => device.address == selected)) {
        _selectedDevice[transport] = null;
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _apiKey.dispose();
    _host.dispose();
    _port.dispose();
    _lineLen.dispose();
    super.dispose();
  }

  String _transportLabel(AppLocalizations l10n, PrinterType type) {
    return switch (type) {
      PrinterType.network => l10n.transportNetwork,
      PrinterType.spooler => l10n.transportSpooler,
      PrinterType.bluetooth => l10n.transportBluetooth,
      PrinterType.usb => l10n.transportUsb,
    };
  }

  IconData _transportIcon(PrinterType type) {
    return switch (type) {
      PrinterType.network => Icons.lan_outlined,
      PrinterType.spooler => Icons.print_outlined,
      PrinterType.bluetooth => Icons.bluetooth,
      PrinterType.usb => Icons.usb,
    };
  }

  String _transportHelp(AppLocalizations l10n, PrinterType type) {
    return switch (type) {
      PrinterType.network => l10n.helpNetwork,
      PrinterType.spooler => l10n.helpSpooler,
      PrinterType.bluetooth => l10n.helpBluetooth,
      PrinterType.usb => l10n.helpUsb,
    };
  }

  Map<int, String> _pollingOptions(AppLocalizations l10n) {
    return {
      0: l10n.pollingWsOnly,
      30: l10n.pollingEvery30s,
      60: l10n.pollingEvery1m,
      120: l10n.pollingEvery2m,
      300: l10n.pollingEvery5m,
      600: l10n.pollingEvery10m,
      1800: l10n.pollingEvery30m,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? l10n.newLink : l10n.editLink),
      ),
      body: Stepper(
        currentStep: _step,
        onStepContinue: _next,
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child:
                      Text(_step == 2 ? l10n.save : l10n.continueLabel),
                ),
                const SizedBox(width: 8),
                if (details.onStepCancel != null)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(l10n.back),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: Text(l10n.stepConnection),
            isActive: _step >= 0,
            content: _buildConnectionStep(l10n),
          ),
          Step(
            title: Text(l10n.stepPrinter),
            isActive: _step >= 1,
            content: _buildPrinterStep(l10n),
          ),
          Step(
            title: Text(l10n.stepOptions),
            isActive: _step >= 2,
            content: _buildOptionsStep(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: l10n.linkName,
            hintText: l10n.linkNameHint,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          decoration: InputDecoration(
            labelText: l10n.installUrl,
            hintText: 'https://miempresa.facturascripts.net',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKey,
          decoration: InputDecoration(
            labelText: l10n.apiKeyLabel,
            helperText: l10n.apiKeyHelp,
          ),
          obscureText: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _testingConnection ? null : _testConnection,
              icon: _testingConnection
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_done_outlined),
              label: Text(l10n.testConnection),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _connectionResult,
                style: TextStyle(
                  color: _connectionOk ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrinterStep(AppLocalizations l10n) {
    final devices = _devices[_transport] ?? const <PrinterRef>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_transports.length > 1) ...[
          SegmentedButton<PrinterType>(
            segments: [
              for (final transport in _transports)
                ButtonSegment(
                  value: transport,
                  label: Text(_transportLabel(l10n, transport)),
                  icon: Icon(_transportIcon(transport)),
                ),
            ],
            selected: {_transport},
            onSelectionChanged: (selection) {
              setState(() {
                _transport = selection.first;
                _printerResult = '';
              });
              if (_needsDeviceList && _devices[_transport] == null) {
                _loadDevices();
              }
            },
          ),
          const SizedBox(height: 16),
        ],
        Text(_transportHelp(l10n, _transport)),
        const SizedBox(height: 12),
        if (_transport == PrinterType.network) ...[
          TextField(
            controller: _host,
            decoration: InputDecoration(
              labelText: l10n.printerHost,
              hintText: '192.168.1.50',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            decoration: InputDecoration(labelText: l10n.printerPort),
            keyboardType: TextInputType.number,
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey('$_transport-${devices.length}'),
                  initialValue: _selectedDevice[_transport],
                  decoration:
                      InputDecoration(labelText: l10n.printerField),
                  items: [
                    for (final device in devices)
                      DropdownMenuItem(
                        value: device.address,
                        child: Text(device.label.isEmpty
                            ? device.address
                            : device.label),
                      ),
                  ],
                  onChanged: (value) => setState(
                      () => _selectedDevice[_transport] = value),
                ),
              ),
              IconButton(
                tooltip: l10n.refreshList,
                onPressed: _loadingDevices ? null : _loadDevices,
                icon: _loadingDevices
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
            ],
          ),
          if (!_loadingDevices && devices.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(l10n.noPrintersFound),
            ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _checkingPrinter ? null : _checkPrinter,
              icon: _checkingPrinter
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(l10n.check),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_printerResult)),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionsStep(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _lineLen,
          decoration: InputDecoration(
            labelText: l10n.lineLenLabel,
            helperText: l10n.lineLenHelp,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _pollingSeconds,
          decoration: InputDecoration(labelText: l10n.pollingLabel),
          items: [
            for (final entry in _pollingOptions(l10n).entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (value) =>
              setState(() => _pollingSeconds = value ?? 0),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.sendInitTitle),
          subtitle: Text(l10n.sendInitHelp),
          value: _sendInit,
          onChanged: (value) => setState(() => _sendInit = value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _printingTest ? null : _printTest,
              icon: _printingTest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              label: Text(l10n.printTestTicket),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(_testResult)),
          ],
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    final l10n = context.l10n;
    setState(() {
      _testingConnection = true;
      _connectionResult = '';
      _connectionOk = false;
    });

    final client = FsApiClient(
      apiUrl: _url.text.trim(),
      apiKey: _apiKey.text.trim(),
    );
    try {
      final printerId = await client.testConnection();
      setState(() {
        _connectionOk = true;
        _connectionResult = l10n.connectionOk(printerId);
      });
    } on FsApiException catch (e) {
      setState(() => _connectionResult = e.message);
    } catch (e) {
      setState(() => _connectionResult = '$e');
    } finally {
      client.close();
      setState(() => _testingConnection = false);
    }
  }

  PrinterRef? _buildPrinterRef() {
    if (_transport == PrinterType.network) {
      final host = _host.text.trim();
      final port = int.tryParse(_port.text.trim()) ?? 9100;
      if (host.isEmpty) {
        return null;
      }
      return PrinterRef(
        type: PrinterType.network,
        address: host,
        port: port,
        label: '$host:$port',
      );
    }

    final address = _selectedDevice[_transport];
    if (address == null || address.isEmpty) {
      return null;
    }
    final devices = _devices[_transport] ?? const <PrinterRef>[];
    final match = devices.where((device) => device.address == address);
    return PrinterRef(
      type: _transport,
      address: address,
      label: match.isNotEmpty ? match.first.label : address,
    );
  }

  String _missingPrinterMessage(AppLocalizations l10n) =>
      _transport == PrinterType.network
          ? l10n.enterPrinterAddress
          : l10n.selectPrinter;

  Future<void> _checkPrinter() async {
    final l10n = context.l10n;
    final printer = _buildPrinterRef();
    if (printer == null) {
      setState(() => _printerResult = _missingPrinterMessage(l10n));
      return;
    }

    setState(() {
      _checkingPrinter = true;
      _printerResult = '';
    });
    try {
      final available = await driverFor(printer).isAvailable();
      setState(() => _printerResult =
          available ? l10n.printerResponds : l10n.printerNotResponding);
    } catch (e) {
      setState(() => _printerResult = '$e');
    } finally {
      setState(() => _checkingPrinter = false);
    }
  }

  Future<void> _printTest() async {
    final l10n = context.l10n;
    final printer = _buildPrinterRef();
    if (printer == null) {
      setState(() => _testResult = l10n.configurePrinterFirst);
      return;
    }

    setState(() {
      _printingTest = true;
      _testResult = '';
    });
    try {
      final ticket = buildTestTicket(
        lineLen: int.tryParse(_lineLen.text.trim()) ?? 48,
        linkName: _name.text.trim(),
      );
      await driverFor(printer).sendRaw(ticket);
      setState(() => _testResult = l10n.ticketSent);
    } catch (e) {
      setState(() => _testResult = '$e');
    } finally {
      setState(() => _printingTest = false);
    }
  }

  Future<void> _next() async {
    final l10n = context.l10n;
    if (_step == 0) {
      if (_url.text.trim().isEmpty || _apiKey.text.trim().isEmpty) {
        setState(() {
          _connectionResult = l10n.fillUrlAndKey;
          _connectionOk = false;
        });
        return;
      }
      setState(() => _step = 1);
      return;
    }

    if (_step == 1) {
      if (_buildPrinterRef() == null) {
        setState(() => _printerResult = _missingPrinterMessage(l10n));
        return;
      }
      setState(() => _step = 2);
      return;
    }

    await _save();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final id = widget.initial?.id ??
        DateTime.now().microsecondsSinceEpoch.toRadixString(36);

    final link = LinkConfig(
      id: id,
      name: _name.text.trim(),
      apiUrl: _url.text.trim(),
      apiKey: _apiKey.text.trim(),
      printer: _buildPrinterRef(),
      lineLen: int.tryParse(_lineLen.text.trim()) ?? 48,
      pollingSeconds: _pollingSeconds,
      sendInit: _sendInit,
      enabled: widget.initial?.enabled ?? true,
    );

    try {
      await ref.read(linksProvider.notifier).save(link);
    } catch (e) {
      // Si el guardado falla (p. ej. sin acceso al llavero), avisar en vez
      // de quedarse en la misma pantalla sin dar ninguna señal.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveError('$e'))),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
