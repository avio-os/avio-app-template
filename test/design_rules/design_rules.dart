/// The Avio design rules an app's own code must keep, checked on its syntax.
///
/// The rules are the "Do and do not" of the SDK's `DESIGN_LANGUAGE.md`
/// (sections 2, 4.4, 5.2, 6 and 14): every colour, type style, symbol, state
/// wash and hairline comes from the SDK, and every spacing literal sits on the
/// 4 px grid. They read the source with the Dart parser — not regular
/// expressions — so comments and strings never trip them, and they need no
/// resolution, so they run in a plain widget test.
///
/// The SDK has no lint package yet; when it ships one, these rules move there
/// and this file goes.
library;

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// One place where code breaks a rule.
final class DesignViolation {
  /// Records [rule] broken at [line] of [path].
  const DesignViolation(this.path, this.line, this.rule, this.detail);

  /// The file, as given to [checkDesignRules].
  final String path;

  /// The 1-based line.
  final int line;

  /// The rule's id, one of [designRules].
  final String rule;

  /// What was found.
  final String detail;

  @override
  String toString() => '$path:$line [$rule] $detail — ${designRules[rule]}';
}

/// Every rule, by id, with what to do instead.
const Map<String, String> designRules = {
  'symbols':
      'draw symbols with AvioIcon(AvioSymbol.x); no Material, Cupertino or '
      'MDI icons, no Icon widgets, no IconData literals',
  'colours':
      'take colours from the tokens (context.ink, context.tokens.colors); '
      'no Color literals and no Colors.*',
  'type':
      'use a type role (context.type.body …) and change only its colour; no '
      'TextStyle literals and no size, weight, family or tracking overrides',
  'alpha':
      'use the token for the state (ink.secondary, ink.hover, ink.disabled …); '
      'never re-alpha a colour or fade a control with Opacity',
  'controls':
      'build from the Avio components (AvioButton, AvioListRow, AvioAsk …); '
      'no Material widgets, and MaterialApp only in lib/app.dart',
  'images':
      'decode images at their drawn size: pass cacheWidth/cacheHeight '
      '(round(logical × devicePixelRatio)), or wrap the provider in '
      'ResizeImage',
  'hairlines':
      'draw lines with AvioHairline/AvioHairlineBox (exactly one device '
      'pixel); no Border or BorderSide of your own',
  'grid':
      'space on the 4 px grid (4, 8, 12, 16, 20, 24, 32 …): every padding and '
      'gap literal is a multiple of 4',
};

const _symbolTypes = {'Icon', 'IconData'};
const _symbolSets = {'Icons', 'CupertinoIcons', 'MdiIcons'};
const _bannedImports = {
  'package:flutter/cupertino.dart': 'symbols',
  'package:cupertino_icons/cupertino_icons.dart': 'symbols',
  'package:material_design_icons_flutter/material_design_icons_flutter.dart':
      'symbols',
};
const _colourSets = {'Colors', 'CupertinoColors'};
const _typeArguments = {
  'fontSize',
  'fontWeight',
  'fontFamily',
  'fontFamilyFallback',
  'fontVariations',
  'letterSpacing',
  'wordSpacing',
};
const _alphaMethods = {'withValues', 'withOpacity', 'withAlpha'};
const _materialWidgets = {
  'AlertDialog',
  'AppBar',
  'BottomNavigationBar',
  'Card',
  'Checkbox',
  'Chip',
  'CircularProgressIndicator',
  'Divider',
  'Drawer',
  'DropdownButton',
  'ElevatedButton',
  'FilledButton',
  'FloatingActionButton',
  'IconButton',
  'InkWell',
  'LinearProgressIndicator',
  'ListTile',
  'Material',
  'NavigationRail',
  'OutlinedButton',
  'PopupMenuButton',
  'Radio',
  'Scaffold',
  'SimpleDialog',
  'Slider',
  'SnackBar',
  'Switch',
  'TabBar',
  'TextButton',
  'TextField',
  'TextFormField',
  'Tooltip',
  'showDialog',
  'showMenu',
  'showModalBottomSheet',
};
const _hairlineTypes = {'Border', 'BorderSide'};
const _spacingTypes = {'EdgeInsets', 'EdgeInsetsDirectional', 'SizedBox'};
const _spacingArguments = {
  'all',
  'horizontal',
  'vertical',
  'left',
  'top',
  'right',
  'bottom',
  'start',
  'end',
  'width',
  'height',
  'dimension',
};
const _sizedDecodes = {'cacheWidth', 'cacheHeight'};

/// Checks [source], the contents of the Dart file at [path].
///
/// [path] decides one thing beyond reporting: `lib/app.dart` is the root and
/// may build the `MaterialApp`.
List<DesignViolation> checkDesignRules(String path, String source) {
  final unit = parseString(content: source, path: path).unit;
  final visitor = _RuleVisitor(path, unit, allowsMaterialApp: _isRoot(path));
  unit.accept(visitor);
  return visitor.violations;
}

bool _isRoot(String path) =>
    path.replaceAll(r'\', '/').endsWith('lib/app.dart');

class _RuleVisitor extends RecursiveAstVisitor<void> {
  _RuleVisitor(this.path, this.unit, {required this.allowsMaterialApp});

  final String path;
  final CompilationUnit unit;
  final bool allowsMaterialApp;
  final List<DesignViolation> violations = [];

  void _flag(AstNode node, String rule, String detail) {
    final line = unit.lineInfo.getLocation(node.offset).lineNumber;
    violations.add(DesignViolation(path, line, rule, detail));
  }

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (_bannedImports[uri] case final rule?) _flag(node, rule, 'import $uri');
    super.visitImportDirective(node);
  }

  // `const Foo(…)`, `new Foo(…)` and `Foo<T>(…)` parse as instance
  // creations; a bare `Foo(…)` or `Foo.named(…)` parses as a method
  // invocation until it is resolved. Both reach [_construct].
  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    _construct(
      node,
      node.constructorName.type.name.lexeme,
      node.constructorName.name?.name,
      node.argumentList,
    );
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target;
    final method = node.methodName.name;
    if (target == null) {
      _construct(node, method, null, node.argumentList);
    } else if (target is SimpleIdentifier && _isTypeName(target.name)) {
      _construct(node, target.name, method, node.argumentList);
    } else if (_alphaMethods.contains(method)) {
      _flag(node, 'alpha', '.$method(…)');
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _member(node, node.prefix.name, node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.target case SimpleIdentifier(:final name)) {
      _member(node, name, node.propertyName.name);
    }
    super.visitPropertyAccess(node);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    final label = node.name.label.name;
    if (_typeArguments.contains(label)) _flag(node, 'type', '$label: …');
    super.visitNamedExpression(node);
  }

  void _member(AstNode node, String owner, String member) {
    if (_symbolSets.contains(owner)) _flag(node, 'symbols', '$owner.$member');
    if (_colourSets.contains(owner)) _flag(node, 'colours', '$owner.$member');
    if (owner == 'FontWeight') _flag(node, 'type', 'FontWeight.$member');
  }

  void _construct(
    AstNode node,
    String type,
    String? constructor,
    ArgumentList arguments,
  ) {
    final call = constructor == null ? type : '$type.$constructor';
    if (_symbolTypes.contains(type)) _flag(node, 'symbols', '$call(…)');
    if (type == 'Color') _flag(node, 'colours', '$call(…)');
    if (type == 'TextStyle' ||
        type == 'FontVariation' ||
        type == 'FontWeight') {
      _flag(node, 'type', '$call(…)');
    }
    if (type == 'Opacity') _flag(node, 'alpha', '$call(…)');
    if (_materialWidgets.contains(type) ||
        (type == 'MaterialApp' && !allowsMaterialApp)) {
      _flag(node, 'controls', '$call(…)');
    }
    if (_hairlineTypes.contains(type)) _flag(node, 'hairlines', '$call(…)');
    if (type == 'Image' || type == 'DecorationImage') {
      _checkDecode(node, call, constructor, arguments);
    }
    if (_spacingTypes.contains(type)) _checkGrid(arguments);
  }

  /// `Image.asset/file/network/memory` must name a decode size; `Image(…)`
  /// and `DecorationImage(…)` must get a [ResizeImage].
  void _checkDecode(
    AstNode node,
    String call,
    String? constructor,
    ArgumentList arguments,
  ) {
    final named = {
      for (final argument in arguments.arguments)
        if (argument is NamedExpression)
          argument.name.label.name: argument.expression,
    };
    final sized = constructor == null
        ? _isResizeImage(named['image'])
        : named.keys.any(_sizedDecodes.contains);
    if (!sized) _flag(node, 'images', '$call(…) without a decode size');
  }

  bool _isResizeImage(Expression? image) => switch (image) {
    InstanceCreationExpression(:final constructorName) =>
      constructorName.type.name.lexeme == 'ResizeImage',
    MethodInvocation(:final methodName, :final target) =>
      methodName.name == 'ResizeImage' ||
          (target is SimpleIdentifier && target.name == 'ResizeImage'),
    _ => false,
  };

  void _checkGrid(ArgumentList arguments) {
    for (final argument in arguments.arguments) {
      final Expression value;
      if (argument is NamedExpression) {
        if (!_spacingArguments.contains(argument.name.label.name)) continue;
        value = argument.expression;
      } else {
        value = argument;
      }
      final number = switch (value) {
        IntegerLiteral(:final value?) => value.toDouble(),
        DoubleLiteral(:final value) => value,
        _ => null,
      };
      if (number != null && number % 4 != 0) {
        _flag(value, 'grid', '$number is off the 4 px grid');
      }
    }
  }
}

bool _isTypeName(String name) =>
    name.isNotEmpty && name[0].toUpperCase() == name[0] && name[0] != '_';
