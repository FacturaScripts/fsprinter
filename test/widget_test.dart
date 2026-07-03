import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsprinter/app.dart';
import 'package:fsprinter/providers/providers.dart';
import 'package:fsprinter/services/stores.dart';

// El entorno de test usa la locale en_US, así que se comprueban los
// textos en inglés.
void main() {
  Widget buildApp() {
    return ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(MemoryStore()),
        secretStoreProvider.overrideWithValue(MemorySecretStore()),
      ],
      child: const FsPrinterApp(),
    );
  }

  testWidgets('la app arranca y muestra el estado vacío', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('No links configured'), findsOneWidget);
    expect(find.text('Add link'), findsOneWidget);
  });

  testWidgets('el botón añadir abre el asistente', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add link'));
    await tester.pumpAndSettle();

    expect(find.text('New link'), findsOneWidget);
    expect(find.text('FacturaScripts installation'), findsOneWidget);
  });
}
