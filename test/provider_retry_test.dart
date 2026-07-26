/// Defends the composition root's retry policy.
///
/// Riverpod 3 retries a failed provider by default, so an error the UI is
/// designed to show would stay behind ~10 backoff attempts and the error
/// surface would never be reached. `lib/main.dart` and [pumpAvio] both pass
/// `retry: (_, _) => null`; this test fails if either loses it.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_avio.dart';

/// Throws an [Exception] rather than an [Error] on purpose: Riverpod's default
/// retry skips `Error`s, so an `Error` here would prove nothing.
final _failingProvider = FutureProvider<String>(
  (ref) async => throw const FormatException('boom'),
);

void main() {
  testWidgets('a failing provider settles on its error instead of retrying', (
    tester,
  ) async {
    await pumpAvio(tester, const _ErrorProbe());
    await tester.pump();

    // Settled on the error: with retry enabled the provider would still be
    // loading here, and a retry timer would outlive the test.
    expect(find.text('failed'), findsOneWidget);
  });
}

class _ErrorProbe extends ConsumerWidget {
  const _ErrorProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(_failingProvider);
    final label = switch (value) {
      AsyncValue(hasError: true, isLoading: false) => 'failed',
      AsyncValue(isLoading: true) => 'loading',
      _ => 'data',
    };
    return Text(label);
  }
}
