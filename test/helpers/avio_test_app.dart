import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 keeps `Override` out of its main library; naming the type in a
// signature needs this second import.
import 'package:flutter_riverpod/misc.dart' show Override;

/// Wraps [child] in the same chrome the app builds at runtime: a
/// [ProviderScope] (see `lib/main.dart`) → [AvioTokens] → [MaterialApp] with
/// the Avio theme → a transparent [Material] → the toast host.
///
/// Widget tests should pump this rather than a bare [MaterialApp]: every Avio
/// component resolves its colors and spacing from an [AvioTokens] ancestor and
/// throws without one. Pass [brightness] to assert a screen in dark mode, and
/// [overrides] to inject fakes for whatever `main()` injects for real.
Widget avioTestApp(
  Widget child, {
  Brightness brightness = Brightness.light,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    // Mirrors `lib/main.dart`: no automatic provider retry, so a failing
    // provider surfaces its error here exactly as it would in the app.
    retry: (_, _) => null,
    child: AvioTokens(
      brightness: brightness,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AvioTheme.light,
        darkTheme: AvioTheme.dark,
        themeMode: brightness == Brightness.dark
            ? ThemeMode.dark
            : ThemeMode.light,
        home: Material(
          type: MaterialType.transparency,
          child: AvioToastProvider(child: child),
        ),
      ),
    ),
  );
}
