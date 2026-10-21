/// Draws the starter window as Avio presents it — light and dark, at device
/// pixel ratios 1 and 2, with the real fonts — and holds it to the window
/// anatomy every Avio app shares: the 232 px sidebar, the search field and
/// New beside it centred in the compositor's controls row, the window
/// controls standing alone (no app action in the controls row, or, when the
/// person puts app actions in the toolbar, one group at its start), the
/// pane title at the 24 px gutter, Figtree on every line of text, and Avio
/// Symbols for every symbol. The single-pane variant (the same window
/// without its sidebar) is held to the same rules.
///
/// `AVIO_UI_CAPTURE_DIR=<dir> flutter test test/features/home` also writes
/// each state as a PNG, to look at before you call a UI change done.
library;

import 'package:avio_app_template/features/home/home_screen.dart';
import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
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
          await tester.tap(_actionButton('New sample item'));
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

      avioWidgetTest('app actions in the toolbar, $label', (tester) async {
        await pumpWindow(
          tester,
          const HomeScreen(),
          dark: dark,
          devicePixelRatio: ratio,
          appActions: AvioAppActionsPlacement.toolbar,
        );
        for (var i = 0; i < 3; i++) {
          await tester.tap(_actionButton('New sample item'));
          await tester.pump();
        }
        await tester.pump(const Duration(seconds: 5));
        await settle(tester);

        _expectAnatomy(tester, placement: AvioAppActionsPlacement.toolbar);
        await captureWindow(
          tester,
          'overview-toolbar-$label',
          devicePixelRatio: ratio,
        );
      });

      avioWidgetTest('a row deleted and offered back, $label', (tester) async {
        await pumpWindow(
          tester,
          const HomeScreen(),
          dark: dark,
          devicePixelRatio: ratio,
        );
        for (var i = 0; i < 3; i++) {
          await tester.tap(_actionButton('New sample item'));
          await tester.pump();
        }
        await tester.pump(const Duration(seconds: 5));
        await settle(tester);
        // The pointer over a row stands its actions on it.
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        addTearDown(mouse.removePointer);
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(tester.getCenter(find.text('Sample item 3')));
        await settle(tester);
        await tester.tap(_actionButton('Delete'));
        await settle(tester);
        await mouse.moveTo(tester.getCenter(find.text('Sample item 1')));
        await settle(tester);

        _expectAnatomy(tester);
        expect(find.byType(AvioUndoPill), findsOneWidget);
        await captureWindow(
          tester,
          'overview-undo-$label',
          devicePixelRatio: ratio,
        );
        // Let the offer end, so no clock outlives the test.
        await tester.pump(kAvioUndoVisibleTime);
        await settle(tester);
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

        _expectAnatomy(tester);
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

/// The button the SDK draws for the declared action labelled [label].
Finder _actionButton(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is AvioIconButton &&
      (widget.tooltip == label || '${widget.tooltip}'.startsWith('$label ·')),
);

/// Holds the pumped window to the shared anatomy, in window coordinates.
void _expectAnatomy(
  WidgetTester tester, {
  Finder? root,
  bool sidebar = true,
  AvioAppActionsPlacement placement = AvioAppActionsPlacement.contextual,
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
    if (placement == AvioAppActionsPlacement.contextual) {
      final add = local(_actionButton('New sample item'));
      expect(add.size, const Size.square(28));
      expect(add.center.dy, row / 2, reason: 'New centred in the row');
      expect(add.left, search.right + 4, reason: 'New stands 4 after search');
      expect(
        add.right,
        lessThanOrEqualTo(kAvioSidebarWidth - 8),
        reason: 'New keeps the sidebar inset',
      );
    }
  } else {
    expect(sidebars, findsNothing);
  }

  // The window controls stand alone: in the content column's controls row
  // there is no app action, or, in the toolbar placement, one group that
  // starts at the content edge and leaves the title its room.
  final content = sidebar ? kAvioSidebarWidth : 0.0;
  final inRow = [
    for (final element in find.byType(AvioIconButton).evaluate())
      if (local(find.byWidget(element.widget)) case final rect
          when rect.top < row && rect.left >= content)
        rect,
  ]..sort((a, b) => a.left.compareTo(b.left));
  if (placement == AvioAppActionsPlacement.contextual) {
    expect(inRow, isEmpty, reason: 'no app action beside the controls');
  } else {
    expect(inRow, isNotEmpty);
    expect(inRow.first.left, content + 16, reason: 'the group leads');
    for (final rect in inRow) {
      expect(rect.center.dy, row / 2, reason: 'group centred in the row');
      expect(
        rect.right,
        lessThanOrEqualTo(
          window.width -
              captureControls.corner.width -
              kAvioToolbarTitleMinWidth,
        ),
        reason: 'nothing stands beside the window controls',
      );
    }
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
    // Without a sidebar there is no search to stand New beside: the window
    // declares it as a page action, and the page's "…" (with one entry,
    // that action's own button) stands at the pane title.
    return AvioActionHost(
      page: [
        AvioAction(
          id: 'template.new',
          label: 'New sample item',
          scope: AvioActionScope.page,
          symbol: AvioSymbol.add,
          onInvoke: () {},
        ),
      ],
      child: const AvioWindowScaffold(
        toolbar: AvioToolbar(),
        header: AvioPaneHeader(
          title: 'Single pane',
          caption: 'The same window without a sidebar.',
          trailing: AvioActionMenuButton(),
        ),
        body: AvioListGroup(
          header: 'Sample items',
          children: [
            AvioListRow(symbol: AvioSymbol.fileText, title: 'Sample item 1'),
            AvioListRow(symbol: AvioSymbol.fileText, title: 'Sample item 2'),
          ],
        ),
      ),
    );
  }
}
