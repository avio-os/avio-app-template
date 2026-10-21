import 'dart:async';

import 'package:avio_system/avio_system.dart';
import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/widgets.dart';

import 'features/home/home_screen.dart';

/// The app — rename to `Avio<YourApp>App` after instantiating the template.
///
/// It follows the system appearance (light or dark and the Avio accent) over
/// the desktop portal with `avio_system`'s [AvioAppearanceMonitor] and hands
/// it to [AppRoot]. With no portal reachable the monitor stays on the light
/// default, so this is safe under any compositor.
class AvioTemplateApp extends StatefulWidget {
  /// Creates the app. [compositorMaterials] says whether the compositor
  /// offers Avio's window materials (`lib/main.dart` asks it once, before the
  /// first frame).
  const AvioTemplateApp({super.key, this.compositorMaterials = false});

  /// Whether the compositor renders the window's glass.
  final bool compositorMaterials;

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
      builder: (context, system, _) => AppRoot(
        appearance: AvioAppearance.fromSystem(system),
        compositorMaterials: widget.compositorMaterials,
        home: const HomeScreen(),
      ),
    );
  }
}

/// The sanctioned Avio root. The app and its widget tests both mount it, so
/// tests render with exactly the ancestors production has.
///
/// From the outside in:
///
/// 1. [AvioCompositorMaterialHost.retained], when the compositor offers
///    materials: the window's glass is then rendered by the compositor, in
///    the same frame as the app's pixels. Without it the window paints its
///    own material.
/// 2. [MaterialApp] with the SDK's one theme factory, [AvioTheme.data], so
///    the few Material pieces Flutter builds for you (text selection,
///    scrollbars) wear the Avio skin.
/// 3. [AvioRoot] in `builder`, above every route: it resolves the
///    [AvioAppearance] into the tokens, the theme and the defaults plain
///    widgets inherit (body text in ink-1 on Figtree, 16 px symbols), and
///    applies the text scale and bold text exactly once.
/// 4. [AvioToastProvider], so toasts float over routes and dialogs.
/// 5. [AvioDesktopApplicationSurface] around [home]: the window's one
///    chrome-tier material, where the compositor's window controls sit
///    (`AvioWindowControlsInset`), blank-space window moves, and the host
///    for in-window popups.
class AppRoot extends StatelessWidget {
  /// Creates the root for [appearance] around [home].
  const AppRoot({
    required this.appearance,
    required this.home,
    super.key,
    this.compositorMaterials = false,
  });

  /// The appearance to resolve.
  final AvioAppearance appearance;

  /// The window's content.
  final Widget home;

  /// Whether the compositor renders the window's glass.
  final bool compositorMaterials;

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp(
      title: 'Avio App Template',
      debugShowCheckedModeBanner: false,
      theme: AvioTheme.data(appearance.colors),
      builder: (context, child) => AvioRoot(
        appearance: appearance,
        child: AvioToastProvider(child: child!),
      ),
      home: AvioDesktopApplicationSurface(child: home),
    );
    if (!compositorMaterials) return app;
    return AvioCompositorMaterialHost.retained(child: app);
  }
}
