/// Defends the starter screen's contract: the sidebar navigates between
/// panes, the toolbar and the empty state add sample items, the sidebar's
/// search filters them, and every action reports back through a toast.
///
/// Replace these with tests for your own screens, but keep the shape — pump
/// [pumpAvio], drive real widgets, assert on what the user sees.
library;

import 'package:avio_app_template/features/home/home_screen.dart';
import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
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
    // The toolbar's actions belong to Overview.
    expect(_toolbarButton('Add sample item'), findsNothing);

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

  avioWidgetTest('the toolbar adds and clears sample items', (tester) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();

    // Nothing to clear yet: the clear action is disabled.
    final clear = _toolbarButton('Clear sample items');
    expect(tester.widget<AvioIconButton>(clear).onPressed, isNull);

    await tester.tap(_toolbarButton('Add sample item'));
    await tester.pump();
    await tester.tap(_toolbarButton('Add sample item'));
    await tester.pump();
    expect(find.text('Sample item 1'), findsOneWidget);
    expect(find.text('Sample item 2'), findsOneWidget);

    await tester.tap(_toolbarButton('Clear sample items'));
    await tester.pump();
    expect(find.text('Sample item 1'), findsNothing);
    expect(find.text('No items yet'), findsOneWidget);
    expect(find.text('Cleared the sample list.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });

  avioWidgetTest('the sidebar search filters the sample items', (tester) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();
    for (var i = 0; i < 3; i++) {
      await tester.tap(_toolbarButton('Add sample item'));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 5));

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

Finder _toolbarButton(String tooltip) => find.byWidgetPredicate(
  (widget) => widget is AvioIconButton && widget.tooltip == tooltip,
);
