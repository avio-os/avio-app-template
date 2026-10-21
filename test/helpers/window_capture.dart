/// Draws the app's window as the Avio compositor presents it, for tests that
/// check real pixels and geometry.
///
/// The window is the app's own [AppRoot], with the real fonts, over a sky
/// backdrop. The compositor's half of the window's glass — the blur and the
/// filter chain under the window — is stood in for by the same filter the
/// SDK hands in-window glass ([avioGlassBackdropFilter]); the window paints
/// its own fill, as it does without a compositor. Everything composites
/// SourceOver in encoded sRGB, which is how Avio composites. The
/// compositor's window controls are drawn where it floats them, and their
/// corner is published to the window the way the runner forwards it.
///
/// With `AVIO_UI_CAPTURE_DIR` set, [captureWindow] also writes the picture
/// there as a PNG for review; without it the capture only renders.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:avio_app_template/app.dart';
import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// The window's size, logical pixels.
const Size captureWindowSize = Size(1040, 700);

/// The frame row and controls corner the Avio compositor publishes over a
/// seamless window at any scale: a 44 row, three 14 px controls 7 apart and
/// 16 in from the right, plus their 8 px hover pad.
const AvioWindowControlsInsetData captureControls = AvioWindowControlsInsetData(
  rowHeight: 44,
  corner: Size(80, 37),
);

/// The sky around the window.
const double _margin = 32;

/// The window frame's corner radius (chrome tier).
const double _frameRadius = 20;

/// Loads Figtree and the Avio Symbols faces from the SDK's bundled assets.
///
/// flutter_test draws every family as its test font until the real one is
/// loaded.
Future<void> loadAvioFonts() async {
  final faces = {
    AvioFontFamilies.primary: [
      'packages/avio_ui/fonts/Figtree.ttf',
      'packages/avio_ui/fonts/Figtree-Italic.ttf',
    ],
    // Every Avio Symbols font, one per ratio bucket and size; the SDK owns
    // their names.
    for (final MapEntry(key: family, value: asset)
        in avioSymbolFontAssets().entries)
      family: [asset],
  };
  for (final MapEntry(key: family, value: files) in faces.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load(file));
    }
    await loader.load();
  }
}

/// Pumps [home] as the window's content, light or [dark], at
/// [devicePixelRatio], with the compositor's controls corner published.
Future<void> pumpWindow(
  WidgetTester tester,
  Widget home, {
  required bool dark,
  required double devicePixelRatio,
}) async {
  final canvas = captureWindowSize + const Offset(_margin * 2, _margin * 2);
  tester.view
    ..devicePixelRatio = devicePixelRatio
    ..physicalSize = canvas * devicePixelRatio;
  addTearDown(tester.view.reset);

  // The runner's side of the two window channels: where the controls sit,
  // and the window's blank-space move regions (accepted).
  const controls = MethodChannel('avio/window_controls');
  const interaction = MethodChannel('dev.avio.system/window');
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(
      controls,
      (call) async => <String, Object>{
        'viewId': tester.view.viewId,
        'rowHeight': captureControls.rowHeight,
        'width': captureControls.corner.width,
        'height': captureControls.corner.height,
      },
    )
    ..setMockMethodCallHandler(interaction, (call) async => true);
  addTearDown(() {
    messenger
      ..setMockMethodCallHandler(controls, null)
      ..setMockMethodCallHandler(interaction, null);
  });

  final appearance = AvioAppearance(
    brightness: dark ? Brightness.dark : Brightness.light,
    // The glass strength the live session runs at.
    glassStrength: 0.2,
  );
  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundary,
      child: _Desktop(
        appearance: appearance,
        child: ProviderScope(
          retry: (_, _) => null,
          child: AppRoot(appearance: appearance, home: home),
        ),
      ),
    ),
  );
  // The published corner lands a frame later.
  await settle(tester);
}

/// Pumps until the window's motion has settled: a travelling plate seats
/// itself a frame after layout, then runs its spring.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

/// The window's rectangle in the capture, logical pixels.
Rect get captureWindowRect =>
    const Offset(_margin, _margin) & captureWindowSize;

/// Captures what [pumpWindow] drew and, with `AVIO_UI_CAPTURE_DIR` set,
/// writes it there as `<name>.png`.
Future<void> captureWindow(
  WidgetTester tester,
  String name, {
  required double devicePixelRatio,
}) async {
  final boundary =
      _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: devicePixelRatio),
  ))!;
  addTearDown(image.dispose);
  expect(
    image.width,
    ((captureWindowSize.width + _margin * 2) * devicePixelRatio).round(),
  );
  final output = Platform.environment['AVIO_UI_CAPTURE_DIR'];
  if (output == null) return;
  final png = await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.png),
  );
  File('$output/$name.png')
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

final GlobalKey _boundary = GlobalKey();

/// The sky, and the window on it as the compositor frames it.
class _Desktop extends StatelessWidget {
  const _Desktop({required this.appearance, required this.child});

  final AvioAppearance appearance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = appearance.brightness == Brightness.dark;
    final glass = AvioGlassTokens(
      materialStrength: appearance.glassStrength,
    ).resolve(AvioGlassTier.chrome, appearance.brightness);
    final ink = appearance.colors.ink;
    const radius = BorderRadius.all(Radius.circular(_frameRadius));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Positioned.fill(child: _Sky(dark: dark)),
          Positioned.fromRect(
            rect: captureWindowRect,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  BackdropFilter(
                    filter: avioGlassBackdropFilter(glass),
                    child: const SizedBox.expand(),
                  ),
                  child,
                  _WindowControls(color: ink.edge),
                  IgnorePointer(
                    child: AvioHairlineBox(
                      color: ink.edge,
                      borderRadius: radius,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The compositor's three window controls in the frame row.
class _WindowControls extends StatelessWidget {
  const _WindowControls({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: (captureControls.rowHeight - 14) / 2,
      right: 16,
      child: IgnorePointer(
        child: Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 7),
              DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// avio.computer's pale-blue sky over paper in light; night with a faint sky
/// glow in dark.
class _Sky extends StatelessWidget {
  const _Sky({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF13203A), Color(0xFF0B1324), Color(0xFF07090E)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.6, -0.8),
              radius: 0.9,
              colors: [Color(0x338DB9E8), Color(0x008DB9E8)],
            ),
          ),
          child: SizedBox.expand(),
        ),
      );
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DB9E8), Color(0xFFC6DCF4), Color(0xFFF3F7FC)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.55, 0.15),
            radius: 0.6,
            colors: [Color(0xE6FFFFFF), Color(0x00FFFFFF)],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}
