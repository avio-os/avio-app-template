/// Holds the app's own code to the Avio design rules
/// (`test/design_rules/design_rules.dart` lists them), and proves each rule
/// catches what it bans, however it is spelled, and passes what it allows.
///
/// A rule failing here names the file, the line and what to do instead. Fix
/// the code; never loosen a rule to get green. If the SDK lacks the token or
/// component you need, add it to avio-sdk.
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'design_rules/design_rules.dart';

/// What every case is resolved with: the imports an app might use, under
/// their own names and behind prefixes, and a few values to work on.
const _header = '''
import 'dart:ui' as ui;

import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoButton, CupertinoColors, CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as m;

late final BuildContext context;
late final Widget child;
late final TextStyle body;
late final Color edge;
late final String url;
late final ImageProvider<Object> photo;
final ResizeImage thumbnail = ResizeImage(photo, width: 64);
const double off = 6;
void go() {}
''';

void main() {
  late DesignRuleChecker checker;

  setUpAll(() => checker = DesignRuleChecker.forPackage());

  test('lib/ keeps the Avio design rules', () async {
    final files =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .map((file) => file.path.replaceAll(r'\', '/'))
            .where((path) => path.endsWith('.dart'))
            .where((path) => !path.endsWith('.g.dart'))
            .toList()
          ..sort();
    expect(files, isNotEmpty);

    final violations = <DesignViolation>[];
    final errors = <String>[];
    for (final file in files) {
      final check = await checker.checkFile(file);
      violations.addAll(check.violations);
      errors.addAll(check.errors);
    }
    expect(errors, isEmpty, reason: errors.join('\n'));
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  group('each rule catches what it bans', () {
    // One banned use per line. Each line must break exactly its rule, and no
    // line of the header may break any.
    const cases = <String, List<String>>{
      'symbols': [
        'final a = Icon(Icons.add);',
        'final b = IconData(0xe000);',
        'final c = CupertinoIcons.add;',
        'final d = m.Icon(m.Icons.add);',
      ],
      'colours': [
        'final a = Color(0xFF8E8E93);',
        'final b = Color.fromARGB(255, 0, 0, 0);',
        'final c = Colors.black;',
        'final d = ui.Color(0xFF000000);',
        'final e = m.Colors.red;',
        'final f = CupertinoColors.systemBlue;',
        'final g = Color.lerp(edge, edge, 0.5);',
        'final h = HSLColor.fromAHSL(1, 210, 0.6, 0.7);',
      ],
      'type': [
        'final a = TextStyle(fontSize: 11);',
        'final b = body.copyWith(fontWeight: FontWeight.w600);',
        "final c = ui.FontVariation('wght', 540);",
        'final d = body.copyWith(height: 4);',
        'final e = body.apply(fontSizeFactor: 2);',
        'final f = body.copyWith(letterSpacing: 0.2);',
      ],
      'alpha': [
        'final a = edge.withValues(alpha: 0.5);',
        'final b = edge.withOpacity(0.4);',
        'final c = Opacity(opacity: 0.4, child: child);',
      ],
      'controls': [
        'final a = Scaffold(body: child);',
        'final b = TextButton(onPressed: go, child: child);',
        'final c = MaterialApp(home: child);',
        'final d = m.ListTile(title: child);',
        'final e = Theme.of(context);',
        'final f = showDialog<void>(context: context, builder: (_) => child);',
        'final g = CupertinoButton(onPressed: go, child: child);',
      ],
      'images': [
        "final a = Image.asset('assets/hero.png');",
        'final b = Image(image: NetworkImage(url));',
        'final c = DecorationImage(image: NetworkImage(url));',
        "final d = Image.asset('a.png', cacheWidth: null, cacheHeight: null);",
        'final e = Image(image: ResizeImage.resizeIfNeeded(null, null, photo));',
        'final f = Image(image: photo);',
      ],
      'hairlines': [
        'final a = Border.all(width: 0.5);',
        'final b = BorderSide(color: edge);',
        'final c = m.Border(top: BorderSide.none);',
      ],
      'grid': [
        'final a = EdgeInsets.all(10);',
        'final b = EdgeInsets.fromLTRB(16, 6, 16, 8);',
        'final c = SizedBox(height: 14);',
        'final d = Row(spacing: 6, children: const []);',
        'final e = Wrap(runSpacing: 10, children: const []);',
        'final f = SizedBox(width: off);',
        'final g = EdgeInsets.only(left: -6);',
      ],
    };

    for (final MapEntry(key: rule, value: lines) in cases.entries) {
      test(rule, () async {
        final check = await checker.checkSource(
          '$_header\n${lines.join('\n')}\n',
        );
        expect(check.errors, isEmpty, reason: check.errors.join('\n'));

        final first = _header.split('\n').length + 1;
        final banned = {for (var i = 0; i < lines.length; i++) first + i};
        final found = check.violations;
        expect(found.map((v) => v.rule).toSet(), {
          rule,
        }, reason: found.join('\n'));
        expect(
          found.map((v) => v.line).toSet(),
          banned,
          reason: found.join('\n'),
        );
      });
    }

    test(
      'MaterialApp is the root only: lib/app.dart builds nothing else',
      () async {
        final check = await checker.checkSource(
          '$_header\n'
          'final a = MaterialApp(home: child);\n'
          'final b = Scaffold(body: child);\n',
          root: true,
        );
        expect(check.errors, isEmpty, reason: check.errors.join('\n'));
        expect(check.violations.map((v) => (v.rule, v.detail)), [
          ('controls', 'Scaffold(…)'),
        ]);
      },
    );
  });

  test('the rules pass the sanctioned forms', () async {
    final check = await checker.checkSource('''
$_header
// Icons.add and Color(0xFF000000) in a comment are fine.
final a = AvioIcon(AvioSymbol.add);
final b = body.copyWith(color: edge);
const c = EdgeInsets.fromLTRB(24, 0, 24, 8);
const d = SizedBox(height: 12);
final e = Image.asset('assets/hero.png', cacheWidth: 64, cacheHeight: 64);
final f = Image(image: ResizeImage(photo, width: 32));
final g = 'Colors.black and TextStyle( in a string are fine';
final h = AvioHairline(color: edge);
final i = Image(image: thumbnail);
final j = DecorationImage(image: ResizeImage(photo, height: 48));
final k = Row(spacing: 8, children: const []);
final l = SizedBox(width: kAvioPaneGutter);
final n = BorderSide.none;
class Preferences {
  const Preferences({this.fontSize = 13, this.height = 1});
  final double fontSize;
  final double height;
  Preferences copyWith({double? fontSize, double? height}) => Preferences(
    fontSize: fontSize ?? this.fontSize,
    height: height ?? this.height,
  );
}
final o = const Preferences().copyWith(fontSize: 15, height: 2);
''');
    expect(check.errors, isEmpty, reason: check.errors.join('\n'));
    expect(check.violations, isEmpty, reason: check.violations.join('\n'));
  });
}
