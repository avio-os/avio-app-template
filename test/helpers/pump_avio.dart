/// Shared widget-test harness: the desktop-pinned test declaration and the
/// widget pump that mirrors the app's real ancestors.
library;

import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 keeps `Override` out of its main library; naming the type in a
// signature needs this second import.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

/// Declares a widget test that runs as [TargetPlatform.linux]. Use this
/// instead of [testWidgets] for anything that renders UI.
///
/// Widget tests otherwise run as Android, and the two platforms disagree about
/// scrolling: on mobile a vertical scroll view adopts the enclosing
/// [PrimaryScrollController] automatically, on desktop it does not. A
/// [Scrollbar] pointed at the primary controller therefore finds no attached
/// position and throws on desktop, while a full suite of Android-shaped tests
/// stays green. Apps seeded from this template are desktop-only, so the tests
/// should say so.
///
/// This goes through [TargetPlatformVariant] rather than assigning
/// `debugDefaultTargetPlatformOverride` in the harness, because flutter_test
/// asserts every foundation debug variable is back to null by the end of the
/// test *body* — earlier than `addTearDown` runs. A hand-rolled override has
/// to be undone at the end of each test, which is easy to forget and is
/// skipped entirely when an expectation throws first. The variant is reset by
/// the framework inside the same `runTest` call, so it cannot leak.
void avioWidgetTest(String description, WidgetTesterCallback callback) {
  testWidgets(
    description,
    callback,
    variant: TargetPlatformVariant.only(TargetPlatform.linux),
  );
}

/// Pumps [child] inside the app's sanctioned ancestors — the same stack
/// `lib/src/app.dart` builds, minus the live appearance monitor — so widget
/// tests exercise the context production renders with.
///
/// Pump this rather than a bare [MaterialApp]: every Avio component resolves
/// its colors and spacing from an [AvioTokens] ancestor and throws without
/// one. Pass [overrides] to inject fakes for whatever `main()` injects for
/// real, and [brightness] to assert a screen in dark mode.
///
/// Declare the test with [avioWidgetTest] so it runs as a desktop platform.
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
