import 'dart:ui' show Brightness;

import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart' show MaterialApp, ThemeData;
import 'package:flutter/widgets.dart';

import 'src/app.dart';

void main() {
  runApp(const _AvioApp());
}

class _AvioApp extends StatefulWidget {
  const _AvioApp();

  @override
  State<_AvioApp> createState() => _AvioAppState();
}

class _AvioAppState extends State<_AvioApp> {
  Brightness _brightness = Brightness.light;
  AvioDensity _density = AvioDensity.comfort;

  @override
  Widget build(BuildContext context) {
    // AvioTokens is the root design-system wrapper. Everything below it
    // can call AvioTokens.of(context) for colors, motion, spacing, etc.
    //
    // Color scheme and density should follow the user's system preference
    // once the avio_system package exposes a Settings1 client. For now
    // we default to light / comfort and toggle via Ctrl+Shift+D in
    // development; production apps subscribe to system settings.
    return AvioTokens(
      brightness: _brightness,
      density: AvioDensityTokens(density: _density),
      child: AvioToastProvider(
        position: AvioToastPosition.bottomRight,
        child: MaterialApp(
          title: 'Avio App Template',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: _brightness, fontFamily: 'packages/avio_ui/Inter'),
          home: AppHome(
            onBrightnessChanged: (b) => setState(() => _brightness = b),
            onDensityChanged: (d) => setState(() => _density = d),
          ),
        ),
      ),
    );
  }
}
