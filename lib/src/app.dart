import 'dart:async';

import 'package:avio_system/avio_system.dart';
import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart'
    show Brightness, Material, MaterialApp, MaterialType, ThemeMode;
import 'package:flutter/widgets.dart';

import 'home_screen.dart';

/// Root of the app — rename to `Avio<YourApp>App` after instantiating the
/// template.
///
/// This is the sanctioned Avio wrapper, in order:
///
/// 1. [AvioTokens] — every widget below reads colors, spacing, radius, motion
///    and typography from `context.tokens`. Nothing hard-codes a value.
/// 2. [AvioToastProvider] — above the app so toasts float over routes and
///    dialogs rather than being covered by them.
/// 3. [MaterialApp] with [AvioTheme.light] / [AvioTheme.dark] — carries the
///    avio skin into the Material widgets the framework builds for you
///    (text selection, scrollbars, dialogs) and loads the SDK's fonts.
/// 4. A transparent [Material] — without a `Material` ancestor, `Text` renders
///    with the framework's debug yellow underlines.
///
/// [AvioAppearanceMonitor] follows the desktop portal's dark/light and
/// accent-color settings live. When no portal is reachable (plain `flutter run`
/// on a bare session) it stays on the light default, so this is safe to keep.
class AvioTemplateApp extends StatefulWidget {
  /// Creates the root widget.
  const AvioTemplateApp({super.key});

  @override
  State<AvioTemplateApp> createState() => _AvioTemplateAppState();
}

class _AvioTemplateAppState extends State<AvioTemplateApp> {
  final AvioAppearanceMonitor _appearance = AvioAppearanceMonitor();

  @override
  void initState() {
    super.initState();
    unawaited(_appearance.start());
  }

  @override
  void dispose() {
    unawaited(_appearance.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AvioSystemAppearance>(
      valueListenable: _appearance.notifier,
      builder: (context, appearance, _) {
        final isDark = appearance.brightness == Brightness.dark;
        return AvioTokens(
          brightness: appearance.brightness,
          // Null accent means 'follow ink', which is the avio-skin default.
          accentColor: appearance.accentColor,
          // Above the MaterialApp, so toasts float over routes and dialogs
          // instead of being covered by whatever the app pushes next.
          child: AvioToastProvider(
            child: MaterialApp(
              title: 'Avio App Template',
              debugShowCheckedModeBanner: false,
              theme: AvioTheme.light,
              darkTheme: AvioTheme.dark,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              home: const Material(
                type: MaterialType.transparency,
                child: HomeScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}
