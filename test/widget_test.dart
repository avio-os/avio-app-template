/// Defends the starter screen's contract: the source list navigates between
/// panes, and the sample action reports back through a toast.
///
/// Replace these with tests for your own screens, but keep the shape — pump
/// [pumpAvio], drive real widgets, assert on what the user sees.
library;

import 'package:avio_app_template/src/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_avio.dart';

void main() {
  testWidgets('sidebar selection swaps the content pane', (tester) async {
    await pumpAvio(tester, const HomeScreen());
    await tester.pumpAndSettle();

    // Opens on Overview: sidebar row + pane title, and an empty sample list.
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('No items yet'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing has happened yet'), findsOneWidget);
    expect(find.text('No items yet'), findsNothing);
  });

  testWidgets('the sample action adds a row and confirms with a toast', (
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

    // Drain the toast's auto-dismiss timer so none outlives the test.
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Added Sample item 1.'), findsNothing);
  });
}
