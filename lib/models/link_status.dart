/// Estado de la conexión WebSocket con el relay.
enum WsState { disconnected, connecting, connected, error }

/// Resultado de un trabajo procesado, para el log visible en la UI.
class JobLogEntry {
  final int ticketId;
  final DateTime time;
  final bool success;
  final int attempts;
  final String message;

  const JobLogEntry({
    required this.ticketId,
    required this.time,
    required this.success,
    this.attempts = 1,
    this.message = '',
  });
}

/// Estado en vivo de un vínculo, publicado por su ConnectionManager.
class LinkStatus {
  final WsState wsState;
  final int? printerId;
  final DateTime? lastActivity;
  final String lastError;
  final List<JobLogEntry> recentJobs;

  /// Ha llegado un ticket que requiere una versión más reciente de la app.
  final bool updateRequired;

  const LinkStatus({
    this.wsState = WsState.disconnected,
    this.printerId,
    this.lastActivity,
    this.lastError = '',
    this.recentJobs = const [],
    this.updateRequired = false,
  });

  LinkStatus copyWith({
    WsState? wsState,
    int? printerId,
    DateTime? lastActivity,
    String? lastError,
    List<JobLogEntry>? recentJobs,
    bool? updateRequired,
  }) {
    return LinkStatus(
      wsState: wsState ?? this.wsState,
      printerId: printerId ?? this.printerId,
      lastActivity: lastActivity ?? this.lastActivity,
      lastError: lastError ?? this.lastError,
      recentJobs: recentJobs ?? this.recentJobs,
      updateRequired: updateRequired ?? this.updateRequired,
    );
  }
}
