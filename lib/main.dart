import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app.dart';
import 'platform/tray_service.dart';
import 'services/app_settings_repository.dart';
import 'services/stores.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (TrayService.isSupported) {
    final packageInfo = await PackageInfo.fromPlatform();
    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
    );

    final settings =
        await AppSettingsRepository(store: PrefsStore()).load();
    await TrayService().init(startHidden: settings.startHidden);
  }

  runApp(const ProviderScope(child: FsPrinterApp()));
}
