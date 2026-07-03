# fsprinter

Servicio de impresión ESC/POS (y en el futuro Zebra/ZPL) para los plugins
**Tickets** y **Etiquetas** de FacturaScripts. Sustituye a mc20printer con
soporte multiplataforma (Windows, macOS, Linux, Android, iOS/iPadOS) y
múltiples vínculos instalación↔impresora en un mismo dispositivo.

## Cómo funciona

1. En FacturaScripts (plugin Tickets) se crea una impresora, que genera su
   propia API key.
2. En fsprinter se crea un **vínculo** con la URL de la instalación, esa API
   key y una impresora del dispositivo. Puede haber tantos vínculos como se
   quiera, cada uno con su impresora.
3. Al imprimir desde FacturaScripts, el plugin guarda el ticket (ESC/POS en
   base64) y avisa a través del relay (`ai.factura.city`). fsprinter recibe
   el aviso (WebSocket en escritorio; WebSocket + push FCM en móvil),
   descarga los tickets pendientes por la API REST, los imprime en RAW y los
   marca como impresos. Hay polling de respaldo configurable por vínculo.

## Transportes de impresora

| Transporte | Win | macOS | Linux | Android | iOS |
|---|---|---|---|---|---|
| Red TCP 9100 (RAW/JetDirect) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Spooler del sistema (impresoras instaladas) | ✅ (winspool) | ✅ (`lp`) | ✅ (`lp`, requiere CUPS) | — | — |
| Bluetooth | vía spooler | vía spooler | vía spooler | ✅ clásico | ✅ BLE |
| USB directo | vía spooler | vía spooler | vía spooler | ✅ | — |

## Segundo plano

- **Escritorio**: cerrar la ventana deja la app en la bandeja del sistema;
  hay ajustes de autoarranque y arrancar oculto.
- **Android**: un foreground service (tipo `connectedDevice`) mantiene la
  conexión con la pantalla apagada, más push FCM como despertador.
- **iOS**: el sistema congela las apps en segundo plano. El push FCM
  (`content-available`) despierta la app para imprimir, pero Apple no lo
  garantiza con la app forzada a cerrar. Para uso desatendido: modo kiosco
  (pantalla siempre encendida) o la app de escritorio.

## Desarrollo

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d macos        # o windows, linux, <dispositivo android/ios>
```

Sin impresora física, apunta un vínculo de red a `127.0.0.1:9100` con
`nc -l 9100` escuchando para inspeccionar los bytes.

### Notas por plataforma

- **macOS**: App Sandbox desactivado (necesario para `lp`); distribución
  fuera de App Store.
- **Linux**: requiere CUPS (`lp`/`lpstat`).
- **Android**: el plugin `usb_serial` está vendorizado en
  `packages/usb_serial` (el publicado no compila con Gradle moderno).
- **iOS**: deployment target 15.0 (lo exige Firebase). Firma en Xcode:
  abrir `ios/Runner.xcworkspace` → Signing & Capabilities.

### Push FCM (opcional, para móvil)

Sin configurar Firebase todo funciona por WebSocket + polling. Para
activar el push:

1. Crear un proyecto Firebase con apps Android e iOS con el bundle id
   `com.facturascripts.fsprinter`.
2. Android: `google-services.json` en `android/app/` + plugin
   `com.google.gms.google-services` en Gradle.
3. iOS: `GoogleService-Info.plist` en `ios/Runner/` + subir la clave APNs
   a Firebase.
4. Relay: copiar la cuenta de servicio a
   `ai-server/firebase/service-account.json`, definir
   `FIREBASE_SERVICE_ACCOUNT_FILE` en el `.env` y redesplegar.

## Protocolo (compatibilidad con mc20printer)

- API REST de FacturaScripts con cabecera `Token`:
  `GET/PUT /api/3/ticketprinteres` y `GET/PUT /api/3/ticketes`.
- Canal del relay: `md5(url_normalizada)`; en hosts locales,
  `md5(url + ':' + apikey)`. Implementado en
  `lib/services/channel_calculator.dart` con tests que fijan los md5
  calculados con PHP (la misma función del plugin).
- El cuerpo de los tickets son bytes opacos: la app no interpreta ESC/POS,
  solo antepone `ESC @` si el vínculo lo tiene activado (desactivable para
  ZPL).
