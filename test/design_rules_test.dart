/// Holds the app's own code to the Avio design rules
/// (`test/design_rules/design_rules.dart` lists them), and proves each rule
/// catches what it bans.
///
/// A rule failing here names the file, the line and what to do instead. Fix
/// the code; never loosen a rule to get green. If the SDK lacks the token or
/// component you need, add it to avio-sdk.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'design_rules/design_rules.dart';

void main() {
  test('lib/ keeps the Avio design rules', () {
    final files =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.endsWith('.g.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty);

    final violations = [
      for (final file in files)
        ...checkDesignRules(file.path, file.readAsStringSync()),
    ];
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  group('each rule catches what it bans', () {
    const cases = <String, String>{
      'symbols': '''
import 'package:flutter/cupertino.dart';
final a = Icon(Icons.add);
final b = IconData(0xe000);
final c = CupertinoIcons.add;
''',
      'colours': '''
final a = Color(0xFF8E8E93);
final b = Color.fromARGB(255, 0, 0, 0);
final c = Colors.black;
''',
      'type': '''
final a = TextStyle(fontSize: 11);
final b = type.body.copyWith(fontWeight: FontWeight.w600);
final c = const FontVariation('wght', 540);
''',
      'alpha': '''
final a = ink.primary.withValues(alpha: 0.5);
final b = color.withOpacity(0.4);
final c = Opacity(opacity: 0.4, child: child);
''',
      'controls': '''
final a = Scaffold(body: child);
final b = TextButton(onPressed: go, child: child);
final c = MaterialApp(home: child);
''',
      'images': '''
final a = Image.asset('assets/hero.png');
final b = Image(image: AssetImage('assets/hero.png'));
final c = DecorationImage(image: NetworkImage(url));
''',
      'hairlines': '''
final a = Border.all(width: 0.5);
final b = BorderSide(color: edge);
''',
      'grid': '''
final a = EdgeInsets.all(10);
final b = EdgeInsets.fromLTRB(16, 6, 16, 8);
final c = SizedBox(height: 14);
''',
    };

    for (final MapEntry(key: rule, value: source) in cases.entries) {
      test(rule, () {
        final lines = source.trim().split('\n').length;
        final violations = checkDesignRules('lib/sample.dart', source);
        expect(violations.map((violation) => violation.rule).toSet(), {
          rule,
        }, reason: violations.join('\n'));
        // Every line of the case breaks the rule at least once.
        expect(violations.map((violation) => violation.line).toSet(), {
          for (var line = 1; line <= lines; line++) line,
        }, reason: violations.join('\n'));
      });
    }
  });

  test('the rules pass the sanctioned forms', () {
    const source = '''
// Icons.add and Color(0xFF000000) in a comment are fine.
final a = AvioIcon(AvioSymbol.add, size: AvioIconSize.s16);
final b = type.body.copyWith(color: context.ink.secondary);
final c = const EdgeInsets.fromLTRB(24, 0, 24, 8);
final d = const SizedBox(height: 12);
final e = Image.asset('assets/hero.png', cacheWidth: 64, cacheHeight: 64);
final f = Image(image: ResizeImage(AssetImage('a.png'), width: 32));
final g = 'Colors.black and TextStyle( in a string are fine';
final h = AvioHairline(color: context.ink.divider);
''';
    expect(checkDesignRules('lib/sample.dart', source), isEmpty);
    expect(
      checkDesignRules('lib/app.dart', 'final app = MaterialApp(home: h);'),
      isEmpty,
    );
  });
}
