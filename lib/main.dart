import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';

/// Composition root. Keep it tiny: initialise bindings, build the real
/// services your app needs, override the providers that stand in for them,
/// then `runApp`. Everything else belongs in `lib/src/`.
///
/// Services that must exist before the first frame get a provider that throws
/// until overridden — `Provider<X>((_) => throw UnimplementedError())` — so
/// this function and the widget tests are the only two places that supply
/// them.
void main() {
  runApp(
    ProviderScope(
      // Riverpod 3 retries a failed provider on its own — up to 10 times,
      // 200ms doubling to a 6.4s cap. A provider whose failure the UI is
      // designed to show then sits in its loading state for most of a minute
      // and the error surface never appears, so failing fast is the better
      // default. Retry is worth having back for genuinely flaky IO; give it to
      // that provider alone (each takes its own `retry:`) rather than here.
      retry: (_, _) => null,
      child: const AvioTemplateApp(),
    ),
  );
}
