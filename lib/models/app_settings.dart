/// Ajustes globales de la aplicación.
class AppSettings {
  /// Arrancar fsprinter al iniciar sesión en el sistema (escritorio).
  final bool launchAtStartup;

  /// Arrancar con la ventana oculta (solo icono de bandeja, escritorio).
  final bool startHidden;

  /// Modo kiosco (móvil): mantiene la pantalla siempre encendida para que
  /// el sistema no congele la app. Pensado para iPads/tablets dedicados.
  final bool kioskMode;

  const AppSettings({
    this.launchAtStartup = false,
    this.startHidden = false,
    this.kioskMode = false,
  });

  AppSettings copyWith(
      {bool? launchAtStartup, bool? startHidden, bool? kioskMode}) {
    return AppSettings(
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      startHidden: startHidden ?? this.startHidden,
      kioskMode: kioskMode ?? this.kioskMode,
    );
  }

  Map<String, dynamic> toJson() => {
        'launchAtStartup': launchAtStartup,
        'startHidden': startHidden,
        'kioskMode': kioskMode,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      launchAtStartup: json['launchAtStartup'] as bool? ?? false,
      startHidden: json['startHidden'] as bool? ?? false,
      kioskMode: json['kioskMode'] as bool? ?? false,
    );
  }
}
