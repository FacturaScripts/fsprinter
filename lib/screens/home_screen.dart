import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../providers/providers.dart';
import 'link_wizard/wizard_screen.dart';
import 'settings_screen.dart';
import 'widgets/link_card.dart';

/// Pantalla principal: lista de vínculos con su estado en vivo.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Arranca una sola vez los servicios de móvil (push + foreground).
    ref.watch(mobileBootstrapProvider);
    final links = ref.watch(linksProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.settingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ));
            },
          ),
        ],
      ),
      body: links.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.configLoadError('$error')),
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.print_disabled, size: 64),
                  const SizedBox(height: 16),
                  Text(l10n.emptyTitle),
                  const SizedBox(height: 8),
                  Text(l10n.emptyBody, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openWizard(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addLink),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) => LinkCard(link: items[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openWizard(context),
        tooltip: l10n.addLink,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openWizard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const WizardScreen()),
    );
  }
}
