/// Shared widget-test harness.
library;

import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 keeps `Override` out of its main library; naming the type in a
// signature needs this second import.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Pumps [child] inside the app's sanctioned ancestors — the same stack
/// `lib/src/app.dart` builds, minus the live appearance monitor — so widget
/// tests exercise the context production renders with.
///
/// Pump this rather than a bare [MaterialApp]: every Avio component resolves
/// its colors and spacing from an [AvioTokens] ancestor and throws without
/// one. Pass [overrides] to inject fakes for whatever `main()` injects for
/// real, and [brightness] to assert a screen in dark mode.
Future<void> pumpAvio(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  Brightness brightness = Brightness.light,
  Size surfaceSize = const Size(1040, 700),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      // Mirrors `lib/main.dart`: no automatic provider retry, so a failing
      // provider surfaces its error here exactly as it would in the app.
      retry: (_, _) => null,
      child: AvioTokens(
        brightness: brightness,
        child: AvioToastProvider(
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AvioTheme.light,
            darkTheme: AvioTheme.dark,
            themeMode: brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: Material(type: MaterialType.transparency, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
