/// Defends the starter screen's contract: the sidebar navigates between
/// panes, New and the empty state add sample items, the sidebar's search
/// filters them, Delete and Clear act at once and offer the rows back, and
/// the same declared actions move into the toolbar when the person asks.
///
/// Replace these with tests for your own screens, but keep the shape — pump
/// [pumpAvio], drive real widgets, assert on what the user sees.
library;

import 'package:avio_app_template/features/home/home_screen.dart';
import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_avio.dart';

void main() {
  avioWidgetTest('tests run as a desktop platform', (tester) async {
    // Pins the harness contract. Scroll views and scrollbars behave
    // differently on mobile, and Android is flutter_test's default — a
    // desktop-only crash hides behind an Android-shaped suite.
    expect(defaultTargetPlatform, TargetPlatform.linux);
  });

  avioWidgetTest('sidebar selection swaps the content pane', (tester) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();

    // Opens on Overview: sidebar row + pane title, and the empty state.
    expect(find.text('Overview'), findsNWidgets(2));
    expect(find.text('No items yet'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing has happened yet'), findsOneWidget);
    expect(find.text('No items yet'), findsNothing);
    // New belongs to the app, so it stays beside the search on every pane.
    expect(actionButton('New sample item'), findsOneWidget);

    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text('0.1.0'), findsOneWidget);
  });

  avioWidgetTest('the window holds up in every appearance', (tester) async {
    // Light and dark are the same design, and high contrast, bold text and
    // a larger text scale restyle it without breaking the layout.
    for (final appearance in const [
      AvioAppearance(),
      AvioAppearance(brightness: Brightness.dark),
      AvioAppearance(highContrast: true, boldText: true, textScale: 1.3),
      AvioAppearance(
        brightness: Brightness.dark,
        highContrast: true,
        reduceTransparency: true,
      ),
      AvioAppearance(appActions: AvioAppActionsPlacement.toolbar),
    ]) {
      await pumpAvio(tester, const HomeScreen(), appearance: appearance);
      await tester.pumpAndSettle();
      expect(find.text('No items yet'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  avioWidgetTest('the empty state adds a row and confirms with a toast', (
    tester,
  ) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add sample item'));
    await tester.pump();
    // Let the toast slide in.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sample item 1'), findsOneWidget);
    expect(find.text('Added Sample item 1.'), findsOneWidget);

    // The toast leaves on its own; drain its timer so none outlives the test.
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Added Sample item 1.'), findsNothing);
  });

  avioWidgetTest('New stands beside the search and answers Ctrl+N', (
    tester,
  ) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();

    final add = tester.widget<AvioIconButton>(actionButton('New sample item'));
    expect(add.tooltip, 'New sample item · Ctrl+N');
    await tester.tap(actionButton('New sample item'));
    await tester.pump();
    expect(find.text('Sample item 1'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(find.text('Sample item 2'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });

  avioWidgetTest('Clear acts at once and offers the rows back', (tester) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();
    await _addItems(tester, 2);

    // The page's actions stand in its "…" at the pane title.
    await tester.tap(actionButton('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear sample items'));
    await tester.pumpAndSettle();

    expect(find.text('Sample item 1'), findsNothing);
    expect(find.text('No items yet'), findsOneWidget);
    expect(_pill('Cleared 2 sample items'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Sample item 1'), findsOneWidget);
    expect(find.text('Sample item 2'), findsOneWidget);
    expect(_pill('Cleared 2 sample items'), findsNothing);

    // Untaken, the offer ends after its ten seconds and the rows are gone.
    await tester.tap(actionButton('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear sample items'));
    await tester.pumpAndSettle();
    await tester.pump(kAvioUndoVisibleTime);
    await tester.pumpAndSettle();
    expect(_pill('Cleared 2 sample items'), findsNothing);
    expect(find.text('No items yet'), findsOneWidget);
  });

  avioWidgetTest('a row deletes from its own actions, and Ctrl+Z puts it '
      'back', (tester) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();
    await _addItems(tester, 2);

    // The row's actions stand on it while the pointer is over it.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('Sample item 2')));
    await tester.pumpAndSettle();
    await tester.tap(actionButton('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Sample item 2'), findsNothing);
    expect(find.text('Sample item 1'), findsOneWidget);
    expect(_pill('Deleted “Sample item 2”'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.text('Sample item 2'), findsOneWidget);
  });

  avioWidgetTest('Sort by name is a toggle in the page menu', (tester) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();
    await _addItems(tester, 11);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Sample item 2'), lessThan(top('Sample item 10')));

    await tester.tap(actionButton('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort by name'));
    await tester.pumpAndSettle();
    expect(top('Sample item 10'), lessThan(top('Sample item 2')));
  });

  avioWidgetTest('in the toolbar placement the same actions lead the '
      'controls row', (tester) async {
    await pumpAvio(
      tester,
      const HomeScreen(),
      appearance: const AvioAppearance(
        appActions: AvioAppActionsPlacement.toolbar,
      ),
    );
    await tester.pumpAndSettle();
    await _addItems(tester, 1);

    // No "…" at the pane title: Sort and Clear are buttons in the group.
    expect(actionButton('More'), findsNothing);
    final toolbar = find.byType(AvioToolbar);
    for (final label in ['New sample item', 'Sort by name']) {
      expect(
        find.descendant(of: toolbar, matching: actionButton(label)),
        findsOneWidget,
        reason: '$label leads the controls row',
      );
    }
    await tester.tap(
      find.descendant(
        of: toolbar,
        matching: actionButton('Clear sample items'),
      ),
    );
    await tester.pumpAndSettle();
    expect(_pill('Cleared 1 sample item'), findsOneWidget);
  });

  avioWidgetTest('the sidebar search filters the sample items', (tester) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();
    await _addItems(tester, 3);

    // Searching from another pane brings the results into view.
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'ITEM 2');
    await tester.pumpAndSettle();

    expect(find.text('Sample items'), findsOneWidget);
    expect(find.text('Sample item 2'), findsOneWidget);
    expect(find.text('Sample item 1'), findsNothing);
    expect(find.text('Sample item 3'), findsNothing);

    await tester.enterText(find.byType(EditableText), 'nothing like it');
    await tester.pumpAndSettle();
    expect(find.text('No matches'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '');
    await tester.pumpAndSettle();
    expect(find.text('Sample item 1'), findsOneWidget);
    expect(find.text('Sample item 3'), findsOneWidget);
  });
}

/// The button the SDK draws for the declared action labelled [label] (its
/// tooltip is the label, then the shortcut).
Finder actionButton(String label) => find.byWidgetPredicate(
  (widget) =>
      widget is AvioIconButton &&
      (widget.tooltip == label || '${widget.tooltip}'.startsWith('$label ·')),
);

/// The undo pill saying [message].
Finder _pill(String message) => find.descendant(
  of: find.byType(AvioUndoPill),
  matching: find.textContaining(message, findRichText: true),
);

/// Adds [count] items with New, then lets their toasts leave.
Future<void> _addItems(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.tap(actionButton('New sample item'));
    await tester.pump();
  }
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}
