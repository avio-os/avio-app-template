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
  runApp(const ProviderScope(child: AvioTemplateApp()));
}
