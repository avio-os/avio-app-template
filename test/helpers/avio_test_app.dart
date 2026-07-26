import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart';

/// Wraps [child] in the same chrome `lib/src/app.dart` builds at runtime:
/// [AvioTokens] → [MaterialApp] with the Avio theme → a transparent [Material]
/// → the toast host.
///
/// Widget tests should pump this rather than a bare [MaterialApp]: every Avio
/// component resolves its colors and spacing from an [AvioTokens] ancestor and
/// throws without one. Pass [brightness] to assert a screen in dark mode.
Widget avioTestApp(Widget child, {Brightness brightness = Brightness.light}) {
  return AvioTokens(
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
  );
}
