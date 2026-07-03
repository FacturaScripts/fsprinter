import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../providers/providers.dart';

/// Ajustes globales de la aplicación.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  static bool get _isMobile => Platform.isAndroid || Platform.isIOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(appSettingsProvider).value ?? const AppSettings();
    final notifier = ref.read(appSettingsProvider.notifier);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTooltip)),
      body: ListView(
        children: [
          if (_isDesktop) ...[
            SwitchListTile(
              title: Text(l10n.launchAtStartupTitle),
              subtitle: Text(l10n.launchAtStartupHelp),
              value: settings.launchAtStartup,
              onChanged: (value) => notifier.setLaunchAtStartup(value),
            ),
            SwitchListTile(
              title: Text(l10n.startHiddenTitle),
              subtitle: Text(l10n.startHiddenHelp),
              value: settings.startHidden,
              onChanged: (value) => notifier.setStartHidden(value),
            ),
            const Divider(),
            ListTile(
              title: Text(l10n.trayNoticeTitle),
              subtitle: Text(l10n.trayNoticeBody),
              leading: const Icon(Icons.info_outline),
            ),
            const Divider(),
          ],
          if (_isMobile) ...[
            SwitchListTile(
              title: Text(l10n.kioskTitle),
              subtitle: Text(l10n.kioskHelp),
              value: settings.kioskMode,
              onChanged: (value) => notifier.setKioskMode(value),
            ),
            const Divider(),
            if (Platform.isIOS)
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.iosBackgroundTitle),
                subtitle: Text(l10n.iosBackgroundBody),
              )
            else
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.androidBackgroundTitle),
                subtitle: Text(l10n.androidBackgroundBody),
              ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: Text(l10n.exportConfigTitle),
            subtitle: Text(l10n.exportConfigHelp),
            onTap: () => _exportConfig(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: Text(l10n.importConfigTitle),
            subtitle: Text(l10n.importConfigHelp),
            onTap: () => _importConfig(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportConfig(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final json = await ref.read(linksProvider.notifier).exportConfig();
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exportConfigTitle),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.exportWarning,
                  style: const TextStyle(color: Colors.orange)),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    json,
                    style: const TextStyle(
                        fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: Text(l10n.copyToClipboard),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: json));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.copiedToClipboard)));
              }
            },
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _importConfig(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final controller = TextEditingController();

    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importConfigTitle),
        content: SizedBox(
          width: 480,
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: l10n.importField,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(controller.text.trim()),
            child: Text(l10n.importAction),
          ),
        ],
      ),
    );

    if (raw == null || raw.isEmpty || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final count =
          await ref.read(linksProvider.notifier).importConfig(raw);
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.importedLinks(count))));
    } on FormatException {
      messenger.showSnackBar(SnackBar(content: Text(l10n.importInvalid)));
    }
  }
}
