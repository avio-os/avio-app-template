import 'package:avio_materials/avio_materials.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Composition root. Keep it tiny: initialise bindings, build the real
/// services your app needs, override the providers that stand in for them,
/// then `runApp`. Everything else belongs under `lib/features/` and
/// `lib/shared/`.
///
/// Services that must exist before the first frame get a provider that throws
/// until overridden — `Provider<X>((_) => throw UnimplementedError())` — so
/// this function and the widget tests are the only two places that supply
/// them.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final compositorMaterials = await _compositorOffersMaterials();
  runApp(
    ProviderScope(
      // Riverpod 3 retries a failed provider on its own — up to 10 times,
      // 200ms doubling to a 6.4s cap. A provider whose failure the UI is
      // designed to show then sits in its loading state for most of a minute
      // and the error surface never appears, so failing fast is the better
      // default. Retry is worth having back for genuinely flaky IO; give it to
      // that provider alone (each takes its own `retry:`) rather than here.
      retry: (_, _) => null,
      child: AvioTemplateApp(compositorMaterials: compositorMaterials),
    ),
  );
}

/// Whether the compositor renders Avio window materials (the Avio
/// compositor does; others do not). Asked once, before the first frame: the
/// answer decides who paints the window's glass for the window's lifetime.
/// The question is one Wayland round trip.
Future<bool> _compositorOffersMaterials() async {
  try {
    await AvioMaterials.ensureReady();
    return true;
  } on Object {
    // Another compositor, X11, or a runner without the plugin: the window
    // paints its own material.
    return false;
  }
}
