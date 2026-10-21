/// Draws the starter window as Avio presents it — light and dark, at device
/// pixel ratios 1 and 2, with the real fonts — and holds it to the window
/// anatomy every Avio app shares: the 232 px sidebar, the search field and
/// the toolbar centred in the compositor's controls row, the toolbar ending
/// 8 px short of the controls, the pane title at the 24 px gutter, Figtree
/// on every line of text, and Avio Symbols for every symbol. The single-pane
/// variant (the same window without its sidebar) is held to the same rules.
///
/// `AVIO_UI_CAPTURE_DIR=<dir> flutter test test/features/home` also writes
/// each state as a PNG, to look at before you call a UI change done.
library;

import 'package:avio_app_template/features/home/home_screen.dart';
import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_avio.dart';
import '../../helpers/window_capture.dart';

void main() {
  setUpAll(loadAvioFonts);

  for (final dark in [false, true]) {
    for (final ratio in [1.0, 2.0]) {
      final label = '${dark ? 'dark' : 'light'}-${ratio.toInt()}x';

      avioWidgetTest('the empty overview, $label', (tester) async {
        await pumpWindow(
          tester,
          const HomeScreen(),
          dark: dark,
          devicePixelRatio: ratio,
        );
        _expectAnatomy(tester);
        await captureWindow(
          tester,
          'overview-empty-$label',
          devicePixelRatio: ratio,
        );
      });

      avioWidgetTest('the overview with items, $label', (tester) async {
        await pumpWindow(
          tester,
          const HomeScreen(),
          dark: dark,
          devicePixelRatio: ratio,
        );
        for (var i = 0; i < 3; i++) {
          await tester.tap(_toolbarButton('Add sample item'));
          await tester.pump();
        }
        // Let the confirmations leave, then select a row: one toast shows.
        await tester.pump(const Duration(seconds: 5));
        await tester.tap(find.text('Sample item 2'));
        await settle(tester);

        _expectAnatomy(tester);
        expect(find.text('Selected Sample item 2.'), findsOneWidget);
        await captureWindow(
          tester,
          'overview-items-$label',
          devicePixelRatio: ratio,
        );
        await tester.pump(const Duration(seconds: 5));
      });

      avioWidgetTest('the about pane, $label', (tester) async {
        await pumpWindow(
          tester,
          const HomeScreen(),
          dark: dark,
          devicePixelRatio: ratio,
        );
        await tester.tap(find.text('About'));
        await settle(tester);

        _expectAnatomy(tester, toolbar: false);
        await captureWindow(tester, 'about-$label', devicePixelRatio: ratio);
      });

      avioWidgetTest('the single-pane variant, $label', (tester) async {
        await pumpWindow(
          tester,
          const _SinglePane(),
          dark: dark,
          devicePixelRatio: ratio,
        );
        _expectAnatomy(tester, root: find.byType(_SinglePane), sidebar: false);
        await captureWindow(
          tester,
          'single-pane-$label',
          devicePixelRatio: ratio,
        );
      });
    }
  }
}

Finder _toolbarButton(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is AvioIconButton && widget.tooltip == tooltip,
);

/// Holds the pumped window to the shared anatomy, in window coordinates.
void _expectAnatomy(
  WidgetTester tester, {
  Finder? root,
  bool sidebar = true,
  bool toolbar = true,
}) {
  final window = captureWindowRect;
  final row = captureControls.rowHeight;
  Rect local(Finder finder) => tester.getRect(finder).shift(-window.topLeft);

  final sidebars = find.byWidgetPredicate((w) => w is AvioSidebar);
  if (sidebar) {
    final rect = local(sidebars);
    expect(rect.left, 0);
    expect(rect.width, kAvioSidebarWidth);
    expect(rect.height, window.height);

    final search = local(find.byType(AvioSearchField));
    expect(search.center.dy, row / 2, reason: 'search centred in the row');
  } else {
    expect(sidebars, findsNothing);
  }

  if (toolbar) {
    final add = local(_toolbarButton('Add sample item'));
    expect(add.size, const Size.square(28));
    expect(add.center.dy, row / 2, reason: 'toolbar centred in the row');
    expect(
      add.right,
      window.width - captureControls.corner.width - kAvioToolbarControlsGap,
      reason: 'the toolbar ends 8 px short of the window controls',
    );
  }

  final title = local(
    find
        .descendant(
          of: find.byType(AvioPaneHeader),
          matching: find.byType(RichText),
        )
        .first,
  );
  expect(title.left, (sidebar ? kAvioSidebarWidth : 0) + kAvioPaneGutter);
  expect(title.top, greaterThanOrEqualTo(row), reason: 'title under the row');

  // Every line of text is Figtree, and every symbol an Avio Symbol.
  final families = <String?>{};
  void collect(RenderObject node) {
    if (node is RenderParagraph) families.add(node.text.style?.fontFamily);
    if (node is RenderEditable) families.add(node.text?.style?.fontFamily);
    node.visitChildren(collect);
  }

  collect(tester.renderObject(root ?? find.byType(HomeScreen)));
  expect(families, {AvioFontFamilies.primary});
  expect(find.byType(Icon), findsNothing);
  expect(find.byType(AvioIcon), findsWidgets);
  expect(tester.takeException(), isNull);
}

/// The window without a sidebar: what an app with one place builds.
class _SinglePane extends StatelessWidget {
  const _SinglePane();

  @override
  Widget build(BuildContext context) {
    return AvioWindowScaffold(
      toolbar: AvioToolbar(
        actions: [
          AvioIconButton(
            symbol: AvioSymbol.add,
            tooltip: 'Add sample item',
            onPressed: () {},
          ),
        ],
      ),
      header: const AvioPaneHeader(
        title: 'Single pane',
        caption: 'The same window without a sidebar.',
      ),
      body: const AvioListGroup(
        header: 'Sample items',
        children: [
          AvioListRow(symbol: AvioSymbol.fileText, title: 'Sample item 1'),
          AvioListRow(symbol: AvioSymbol.fileText, title: 'Sample item 2'),
        ],
      ),
    );
  }
}
