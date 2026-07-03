import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n.dart';
import '../models/link_config.dart';
import '../models/link_status.dart';
import '../printing/driver_factory.dart';
import '../printing/test_ticket.dart';
import '../providers/providers.dart';
import 'link_wizard/wizard_screen.dart';
import 'widgets/link_card.dart' show wsStateLabel;

/// Detalle de un vínculo: estado en vivo, log de trabajos y acciones.
class LinkDetailScreen extends ConsumerWidget {
  final String linkId;

  const LinkDetailScreen({super.key, required this.linkId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(linksProvider).value ?? [];
    final index = links.indexWhere((l) => l.id == linkId);
    if (index < 0) {
      // El vínculo se ha eliminado: volver.
      return const Scaffold(body: SizedBox.shrink());
    }
    final link = links[index];
    final status =
        ref.watch(linkStatusProvider(linkId)).value ?? const LinkStatus();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(link.name.isEmpty ? link.apiUrl : link.name),
        actions: [
          IconButton(
            tooltip: l10n.editTooltip,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => WizardScreen(initial: link),
              ));
            },
          ),
          IconButton(
            tooltip: l10n.deleteTooltip,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, link),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(link: link, status: status),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(registryProvider).managerFor(linkId)?.pullNow(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.pullNow),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _printTest(context, link),
                icon: const Icon(Icons.receipt_long_outlined),
                label: Text(l10n.testTicket),
              ),
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(linksProvider.notifier)
                    .setEnabled(linkId, !link.enabled),
                icon: Icon(link.enabled ? Icons.pause : Icons.play_arrow),
                label: Text(link.enabled ? l10n.pause : l10n.resume),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.recentJobs,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (status.recentJobs.isEmpty)
            Text(l10n.noJobsYet)
          else
            for (final job in status.recentJobs) _JobTile(job: job),
        ],
      ),
    );
  }

  Future<void> _printTest(BuildContext context, LinkConfig link) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final printer = link.printer;
    if (printer == null) {
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.linkHasNoPrinter)));
      return;
    }

    try {
      await driverFor(printer).sendRaw(
        buildTestTicket(lineLen: link.lineLen, linkName: link.name),
      );
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.testTicketSent)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, LinkConfig link) async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteLinkTitle),
        content: Text(l10n
            .deleteLinkBody(link.name.isEmpty ? link.apiUrl : link.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(linksProvider.notifier).remove(link.id);
      navigator.pop();
    }
  }
}

class _InfoCard extends StatelessWidget {
  final LinkConfig link;
  final LinkStatus status;

  const _InfoCard({required this.link, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String, String)>[
      (l10n.infoUrl, link.apiUrl),
      (l10n.infoPrinter, link.printer?.toString() ?? l10n.noPrinter),
      (
        l10n.infoState,
        link.enabled ? wsStateLabel(l10n, status.wsState) : l10n.paused
      ),
      if (status.printerId != null)
        (l10n.infoPrinterId, '${status.printerId}'),
      if (status.lastActivity != null)
        (
          l10n.infoLastActivity,
          DateFormat('dd/MM/yyyy HH:mm:ss').format(status.lastActivity!)
        ),
      (l10n.infoLineLen, '${link.lineLen}'),
      if (status.lastError.isNotEmpty) (l10n.infoLastError, status.lastError),
      if (status.updateRequired) (l10n.infoNotice, l10n.updateRequiredLong),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(row.$1,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Text(row.$2)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  final JobLogEntry job;

  const _JobTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        job.success ? Icons.check_circle : Icons.error,
        color: job.success ? Colors.green : Colors.red,
      ),
      title: Text(l10n.ticketN(job.ticketId)),
      subtitle: Text([
        DateFormat('HH:mm:ss').format(job.time),
        if (job.attempts > 1) l10n.attemptsN(job.attempts),
        if (job.message.isNotEmpty) job.message,
      ].join(' · ')),
    );
  }
}
