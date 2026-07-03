import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';
import '../../models/link_config.dart';
import '../../models/link_status.dart';
import '../../providers/providers.dart';
import '../link_detail_screen.dart';

/// Tarjeta de un vínculo en la pantalla principal: nombre, destino,
/// impresora y estado de conexión en vivo.
class LinkCard extends ConsumerWidget {
  final LinkConfig link;

  const LinkCard({super.key, required this.link});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(linkStatusProvider(link.id)).value ??
        const LinkStatus();
    final l10n = context.l10n;

    return Card(
      child: ListTile(
        leading: _StatusDot(enabled: link.enabled, wsState: status.wsState),
        title: Text(link.name.isEmpty ? link.apiUrl : link.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(link.apiUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(link.printer == null
                ? l10n.noPrinter
                : l10n.printerLine('${link.printer}')),
            Text(_statusLine(l10n, status)),
            if (status.updateRequired)
              Text(
                l10n.updateRequiredShort,
                style: const TextStyle(color: Colors.orange),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => LinkDetailScreen(linkId: link.id),
          ));
        },
      ),
    );
  }

  String _statusLine(AppLocalizations l10n, LinkStatus status) {
    if (!link.enabled) {
      return l10n.paused;
    }
    final parts = <String>[wsStateLabel(l10n, status.wsState)];
    if (status.lastActivity != null) {
      parts.add(l10n
          .activityAt(DateFormat('HH:mm:ss').format(status.lastActivity!)));
    }
    if (status.lastError.isNotEmpty) {
      parts.add(l10n.errorLine(status.lastError));
    }
    return parts.join(' · ');
  }
}

String wsStateLabel(AppLocalizations l10n, WsState state) {
  switch (state) {
    case WsState.connected:
      return l10n.wsConnected;
    case WsState.connecting:
      return l10n.wsConnecting;
    case WsState.error:
      return l10n.wsError;
    case WsState.disconnected:
      return l10n.wsDisconnected;
  }
}

class _StatusDot extends StatelessWidget {
  final bool enabled;
  final WsState wsState;

  const _StatusDot({required this.enabled, required this.wsState});

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? Colors.grey
        : switch (wsState) {
            WsState.connected => Colors.green,
            WsState.connecting => Colors.orange,
            WsState.error => Colors.red,
            WsState.disconnected => Colors.grey,
          };

    return Icon(Icons.circle, color: color, size: 16);
  }
}
