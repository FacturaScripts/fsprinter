import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../models/link_config.dart';
import 'channel_calculator.dart';
import 'headless_pull.dart';

/// Manejador de push en background: corre en su propio isolate, sin UI,
/// así que hace un pull headless completo (descarga, imprime y confirma).
@pragma('vm:entry-point')
Future<void> fsprinterBackgroundMessageHandler(RemoteMessage message) async {
  await runHeadlessPull();
}

/// Despertador push (FCM) para Android/iOS.
///
/// Registra el token del dispositivo en el relay para cada canal de los
/// vínculos configurados (`POST /mc20printer/<canal>/register`) y dispara
/// [onNudge] cuando llega un aviso con la app en primer plano. En segundo
/// plano actúa [fsprinterBackgroundMessageHandler].
///
/// Si Firebase no está configurado en la app (falta google-services.json /
/// GoogleService-Info.plist) queda deshabilitado sin romper nada: el
/// WebSocket y el polling siguen funcionando.
class PushListener {
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  final void Function() onNudge;
  final http.Client _client;

  bool _enabled = false;
  String? _token;
  List<LinkConfig> _links = const [];

  PushListener({required this.onNudge, http.Client? client})
      : _client = client ?? http.Client();

  bool get enabled => _enabled;

  Future<void> init() async {
    if (!isSupported) {
      return;
    }

    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Firebase sin configurar: push deshabilitado.
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      FirebaseMessaging.onBackgroundMessage(
          fsprinterBackgroundMessageHandler);
      FirebaseMessaging.onMessage.listen((_) => onNudge());

      _token = await messaging.getToken();
      messaging.onTokenRefresh.listen((token) {
        _token = token;
        _registerAll();
      });

      _enabled = _token != null;
      await _registerAll();
    } catch (_) {
      _enabled = false;
    }
  }

  /// Sincroniza los canales registrados con la lista de vínculos activa.
  Future<void> syncLinks(List<LinkConfig> links) async {
    _links = links;
    await _registerAll();
  }

  Future<void> _registerAll() async {
    final token = _token;
    if (!_enabled || token == null) {
      return;
    }

    final channels = {
      for (final link in _links)
        if (link.enabled && link.apiUrl.isNotEmpty)
          ChannelCalculator.channel(link.apiUrl, link.apiKey),
    };

    for (final channel in channels) {
      try {
        await _client.post(
          Uri.parse('${ChannelCalculator.relayBaseUrl}$channel/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'fcm_token': token,
            'platform': Platform.isAndroid ? 'android' : 'ios',
          }),
        );
      } catch (_) {
        // Reintento implícito: se volverá a registrar en el próximo
        // cambio de vínculos o refresco de token.
      }
    }
  }
}
