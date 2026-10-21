/// Holds [AppRoot]'s one decision about the window's glass: the compositor
/// renders it, in the app's own frame, only when it offers Avio's materials
/// (`lib/main.dart` asks once); otherwise the window paints its own.
library;

import 'package:avio_app_template/app.dart';
import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_avio.dart';

void main() {
  for (final (offered, transport) in [
    (true, AvioMaterialTransport.retainedSceneV3),
    (false, AvioMaterialTransport.unavailable),
  ]) {
    avioWidgetTest(
      'materials ${offered ? 'offered' : 'absent'}: the window content sees '
      '$transport',
      (tester) async {
        AvioMaterialTransport? seen;
        await tester.pumpWidget(
          AppRoot(
            appearance: const AvioAppearance(),
            compositorMaterials: offered,
            home: Builder(
              builder: (context) {
                seen = AvioCompositorMaterialHost.transportOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        );
        await tester.pump();

        expect(seen, transport);
      },
    );
  }
}
