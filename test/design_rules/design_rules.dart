/// The Avio design rules an app's own code must keep, checked on its resolved
/// syntax.
///
/// The rules are the "Do and do not" of the SDK's `DESIGN_LANGUAGE.md`
/// (sections 2, 4.4, 5.2, 6, 8.6, 9.19 and 14): every colour, type style,
/// symbol, state wash and hairline comes from the SDK, every spacing value
/// sits on the 4 px grid, actions are declared rather than placed, and no
/// decision is a dialog. They match what the analyzer resolves — the class a constructor
/// builds, the declaration a name refers to, the static type a method is
/// called on — so an import prefix, a variable or a re-export cannot hide a
/// use, comments and strings never trip them, and an app's own
/// `copyWith(fontSize: …)` on a preferences object is not a type style.
///
/// A file that does not resolve proves nothing, so a check reports its
/// analysis errors next to its violations, and the tests fail on either.
///
/// The SDK has no lint package yet; when it ships one, these rules move there
/// and this file goes.
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' show DiagnosticSeverity;
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

/// One place where code breaks a rule.
final class DesignViolation {
  /// Records [rule] broken at [line] of [path].
  const DesignViolation(this.path, this.line, this.rule, this.detail);

  /// The file, relative to the package root.
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
      'no Color literals, no Colors.* and no colours mixed by hand',
  'type':
      'use a type role (context.type.body …) and change only its colour; no '
      'TextStyle literals and no size, weight, family, tracking or line '
      'height of your own',
  'alpha':
      'use the token for the state (ink.secondary, ink.hover, ink.disabled …); '
      'never re-alpha a colour or fade a control with Opacity',
  'controls':
      'build from the Avio components (AvioButton, AvioListRow, AvioAsk …); '
      'no Material or Cupertino API, and MaterialApp only in lib/app.dart',
  'images':
      'decode images at their drawn size: pass cacheWidth/cacheHeight '
      '(round(logical × devicePixelRatio)), or give the image a ResizeImage',
  'hairlines':
      'draw lines with AvioHairline/AvioHairlineBox (exactly one device '
      'pixel); no Border or BorderSide of your own',
  'grid':
      'space on the 4 px grid (4, 8, 12, 16, 20, 24, 32 …): every padding, '
      'gap and spacing value is a multiple of 4',
  'actions':
      'declare actions as AvioActions in an AvioActionHost (New in app, the '
      "page's in page, a row's in AvioListRow.actions); the SDK places them "
      'and the window controls stand alone, so never fill '
      'AvioToolbar.actions',
  'asks':
      'take the first rung of the decision ladder that fits: act and offer '
      'it back (AvioUndo), confirm in place (AvioArmedButton, '
      'AvioConfirmRow), edit in place (AvioInlineField), AvioPopoverAsk, a '
      'window bar, AvioInspector, or AvioGuidedScreen.ask with a reason; '
      'never a dialog (showAvioAsk, showAvioDialog, AvioDialog, '
      'AvioDialogHost, showGeneralDialog)',
};

/// What checking one file found.
final class DesignCheck {
  /// The [violations] and the analysis [errors] of one file.
  const DesignCheck(this.violations, this.errors);

  /// Where the file breaks a rule.
  final List<DesignViolation> violations;

  /// The file's analysis errors. The rules match resolved elements, so with
  /// any of these the file has not really been checked.
  final List<String> errors;
}

/// Checks this package's Dart files, resolved against its dependencies.
final class DesignRuleChecker {
  DesignRuleChecker._(this._root, this._overlay, this._collection);

  /// A checker for the package at [root], by default the current directory
  /// (the package root under `flutter test`). It resolves against the
  /// Flutter toolchain running the test.
  factory DesignRuleChecker.forPackage([String? root]) {
    final package = Directory(root ?? Directory.current.path).absolute.path;
    final flutter = Platform.environment['FLUTTER_ROOT'];
    if (flutter == null) {
      throw StateError(
        'FLUTTER_ROOT is unset: run the design rules with flutter test',
      );
    }
    final overlay = OverlayResourceProvider(PhysicalResourceProvider.INSTANCE);
    return DesignRuleChecker._(
      package,
      overlay,
      AnalysisContextCollection(
        includedPaths: ['$package/lib'],
        resourceProvider: overlay,
        sdkPath: '$flutter/bin/cache/dart-sdk',
      ),
    );
  }

  final String _root;
  final OverlayResourceProvider _overlay;
  final AnalysisContextCollection _collection;
  var _cases = 0;

  /// Checks the file at [path], relative to the package root.
  /// `lib/app.dart` is the root and may build the `MaterialApp`.
  Future<DesignCheck> checkFile(String path) {
    final relative = path.replaceAll(r'\', '/');
    return _check(relative, root: relative == 'lib/app.dart');
  }

  /// Checks [source] as a file of `lib/` that exists only in memory; with
  /// [root] it is checked as `lib/app.dart`.
  Future<DesignCheck> checkSource(String source, {bool root = false}) async {
    final relative = 'lib/__design_rules_case_${_cases++}__.dart';
    final path = '$_root/$relative';
    _overlay.setOverlay(path, content: source, modificationStamp: _cases);
    try {
      return await _check(relative, root: root);
    } finally {
      _overlay.removeOverlay(path);
    }
  }

  Future<DesignCheck> _check(String relative, {required bool root}) async {
    final path = '$_root/$relative';
    final result = await _collection
        .contextFor(path)
        .currentSession
        .getResolvedUnit(path);
    if (result is! ResolvedUnitResult) {
      throw StateError('$relative did not resolve: $result');
    }
    final errors = [
      for (final diagnostic in result.diagnostics)
        if (diagnostic.diagnosticCode.severity == DiagnosticSeverity.ERROR)
          '$relative:${result.lineInfo.getLocation(diagnostic.offset)} '
              '${diagnostic.message}',
    ];
    final visitor = _RuleVisitor(relative, result.unit, root: root);
    result.unit.accept(visitor);
    return DesignCheck(visitor.violations, errors);
  }
}

const _ui = 'dart:ui';
const _painting = 'package:flutter/src/painting/';
const _widgets = 'package:flutter/src/widgets/';
const _rendering = 'package:flutter/src/rendering/';
const _material = 'package:flutter/src/material/';
const _cupertino = 'package:flutter/src/cupertino/';
const _avio = 'package:avio_ui/';

/// The SDK's dialog presenters, restricted to portal and system asks.
const _askFunctions = {'showAvioAsk', 'showAvioDialog'};
const _askTypes = {'AvioDialog', 'AvioDialogHost'};

/// Icon fonts whose import alone is a breach.
const _iconPackages = [
  'package:cupertino_icons/',
  'package:material_design_icons_flutter/',
];

/// Text style fields a type role keeps: `copyWith`/`apply` may not name them.
const _typeArguments = {
  'fontSize',
  'fontWeight',
  'fontFamily',
  'fontFamilyFallback',
  'fontVariations',
  'letterSpacing',
  'wordSpacing',
  'height',
  'fontSizeFactor',
  'fontSizeDelta',
  'fontWeightDelta',
  'letterSpacingFactor',
  'letterSpacingDelta',
  'wordSpacingFactor',
  'wordSpacingDelta',
  'heightFactor',
  'heightDelta',
};

const _alphaMethods = {'withValues', 'withOpacity', 'withAlpha'};

/// The spacing arguments of each spacing constructor; null means every
/// argument (the [EdgeInsets] family).
const _spacing = <(String, String), Set<String>?>{
  (_painting, 'EdgeInsets'): null,
  (_painting, 'EdgeInsetsDirectional'): null,
  (_widgets, 'SizedBox'): {'width', 'height', 'dimension'},
  (_widgets, 'Flex'): {'spacing'},
  (_widgets, 'Row'): {'spacing'},
  (_widgets, 'Column'): {'spacing'},
  (_widgets, 'Wrap'): {'spacing', 'runSpacing'},
  (_rendering, 'SliverGridDelegateWithFixedCrossAxisCount'): {
    'mainAxisSpacing',
    'crossAxisSpacing',
  },
  (_rendering, 'SliverGridDelegateWithMaxCrossAxisExtent'): {
    'mainAxisSpacing',
    'crossAxisSpacing',
  },
};

class _RuleVisitor extends RecursiveAstVisitor<void> {
  _RuleVisitor(this.path, this.unit, {required this.root});

  final String path;
  final CompilationUnit unit;
  final bool root;
  final List<DesignViolation> violations = [];

  void _flag(AstNode node, String rule, String detail) {
    final line = unit.lineInfo.getLocation(node.offset).lineNumber;
    violations.add(DesignViolation(path, line, rule, detail));
  }

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';
    if (_iconPackages.any(uri.startsWith)) {
      _flag(node, 'symbols', 'import $uri');
    }
    super.visitImportDirective(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.element case final constructor?) {
      _construct(node, constructor, node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) {
    if (node.constructorName.element case final ConstructorElement c) {
      _construct(node, c, node.argumentList);
    }
    super.visitDotShorthandConstructorInvocation(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.element case final ExecutableElement method) {
      _invoke(node, method, node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitDotShorthandInvocation(DotShorthandInvocation node) {
    if (node.memberName.element case final ExecutableElement method) {
      _invoke(node, method, node.argumentList);
    }
    super.visitDotShorthandInvocation(node);
  }

  /// A static member read: `Colors.black`, `Icons.add`, `FontWeight.w600`.
  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    final isStatic = switch (element) {
      PropertyAccessorElement(:final isStatic) => isStatic,
      FieldElement(:final isStatic) => isStatic,
      _ => false,
    };
    final owner = isStatic ? _owner(element) : null;
    if (owner != null) {
      final read = '${owner.name}.${node.name}';
      if (_is(owner, _material, 'Colors') ||
          _is(owner, _cupertino, 'CupertinoColors')) {
        _flag(node, 'colours', read);
      }
      if (_is(owner, _material, 'Icons') ||
          _is(owner, _cupertino, 'CupertinoIcons') ||
          owner.name == 'MdiIcons') {
        _flag(node, 'symbols', read);
      }
      if (_is(owner, _ui, 'FontWeight')) _flag(node, 'type', read);
    }
    super.visitSimpleIdentifier(node);
  }

  void _construct(
    AstNode node,
    ConstructorElement constructor,
    ArgumentList arguments,
  ) {
    final type = constructor.enclosingElement;
    final named = constructor.name;
    final isNamed = named != null && named.isNotEmpty && named != 'new';
    final call = '${type.name}${isNamed ? '.$named' : ''}(…)';

    if (_is(type, _widgets, 'Icon') || _is(type, _widgets, 'IconData')) {
      _flag(node, 'symbols', call);
    }
    if (_is(type, _ui, 'Color') ||
        _is(type, _painting, 'HSLColor') ||
        _is(type, _painting, 'HSVColor')) {
      _flag(node, 'colours', call);
    }
    if (_is(type, _painting, 'TextStyle') ||
        _is(type, _painting, 'StrutStyle') ||
        (_in(type, _ui) &&
            const {
              'TextStyle',
              'ParagraphStyle',
              'StrutStyle',
              'FontVariation',
              'FontWeight',
            }.contains(type.name))) {
      _flag(node, 'type', call);
    }
    if (_is(type, _widgets, 'Opacity')) _flag(node, 'alpha', call);
    if (_in(type, _material) || _in(type, _cupertino)) {
      if (!(root && _is(type, _material, 'MaterialApp'))) {
        _flag(node, 'controls', call);
      }
    }
    if (_is(type, _painting, 'Border') || _is(type, _painting, 'BorderSide')) {
      _flag(node, 'hairlines', call);
    }
    if (_in(type, _avio) && _askTypes.contains(type.name)) {
      _flag(node, 'asks', call);
    }
    if (_is(type, _widgets, 'RawDialogRoute')) _flag(node, 'asks', call);
    if (_is(type, _avio, 'AvioToolbar') &&
        _named(arguments).containsKey('actions')) {
      _flag(node, 'actions', 'AvioToolbar(actions: …)');
    }
    if (_is(type, _widgets, 'Image')) {
      final sized = isNamed
          ? _namesDecodeSize(arguments)
          : _isSizedProvider(_named(arguments)['image']);
      if (!sized) _flag(node, 'images', '$call without a decode size');
    }
    if (_is(type, _painting, 'DecorationImage') &&
        !_isSizedProvider(_named(arguments)['image'])) {
      _flag(node, 'images', '$call without a decode size');
    }
    for (final MapEntry(key: (library, name), value: names)
        in _spacing.entries) {
      if (_is(type, library, name)) _checkGrid(arguments, names);
    }
  }

  void _invoke(AstNode node, ExecutableElement method, ArgumentList args) {
    final owner = _owner(method);
    final call = '${method.name}(…)';
    if (_in(method, _material) || _in(method, _cupertino)) {
      _flag(node, 'controls', owner == null ? call : '${owner.name}.$call');
    }
    if ((_in(method, _avio) && _askFunctions.contains(method.name)) ||
        (_in(owner, _avio) && (owner?.name ?? '').contains('AvioDialogHost')) ||
        (_in(method, _widgets) && method.name == 'showGeneralDialog')) {
      _flag(node, 'asks', owner == null ? call : '${owner.name}.$call');
    }
    if (_is(owner, _ui, 'Color')) {
      if (_alphaMethods.contains(method.name)) {
        _flag(node, 'alpha', '.$call');
      } else if (method.isStatic) {
        _flag(node, 'colours', 'Color.$call');
      }
    }
    if (_is(owner, _ui, 'FontWeight') && method.isStatic) {
      _flag(node, 'type', 'FontWeight.$call');
    }
    if (_is(owner, _painting, 'TextStyle') &&
        (method.name == 'copyWith' || method.name == 'apply')) {
      for (final argument in args.arguments.whereType<NamedExpression>()) {
        final label = argument.name.label.name;
        if (_typeArguments.contains(label)) {
          _flag(argument, 'type', '${method.name}($label: …)');
        }
      }
    }
  }

  /// `Image.asset/file/network/memory` name a decode size that is not null.
  bool _namesDecodeSize(ArgumentList arguments) {
    final named = _named(arguments);
    return [
      named['cacheWidth'],
      named['cacheHeight'],
    ].any((size) => size != null && size is! NullLiteral);
  }

  /// Whether [image] is a provider that decodes at a bounded size: a
  /// [ResizeImage] with a width or height, `ResizeImage.resizeIfNeeded`
  /// with a size, or any expression whose static type is a `ResizeImage`.
  bool _isSizedProvider(Expression? image) {
    switch (image) {
      case null:
        return false;
      case InstanceCreationExpression(
            :final constructorName,
            :final argumentList,
          )
          when _is(
            constructorName.element?.enclosingElement,
            _painting,
            'ResizeImage',
          ):
        final named = _named(argumentList);
        return [
          named['width'],
          named['height'],
        ].any((size) => size != null && size is! NullLiteral);
      case MethodInvocation(:final methodName, :final argumentList)
          when methodName.name == 'resizeIfNeeded' &&
              _is(_owner(methodName.element), _painting, 'ResizeImage'):
        return argumentList.arguments
            .where((argument) => argument is! NamedExpression)
            .take(2)
            .any((size) => size is! NullLiteral);
    }
    final type = image.staticType;
    return type is InterfaceType &&
        [
          type,
          ...type.allSupertypes,
        ].any((t) => _is(t.element, _painting, 'ResizeImage'));
  }

  /// Flags spacing values off the 4 px grid among [arguments]; [names]
  /// limits the check to those named arguments, or null checks them all.
  void _checkGrid(ArgumentList arguments, Set<String>? names) {
    for (final argument in arguments.arguments) {
      final Expression value;
      if (argument is NamedExpression) {
        if (names != null && !names.contains(argument.name.label.name)) {
          continue;
        }
        value = argument.expression;
      } else {
        if (names != null) continue;
        value = argument;
      }
      final number = _number(value);
      if (number != null && number % 4 != 0) {
        final shown = number == number.roundToDouble()
            ? number.round()
            : number;
        _flag(value, 'grid', '$shown is off the 4 px grid');
      }
    }
  }
}

/// The value of a numeric literal or constant reference, or null.
double? _number(Expression value) {
  switch (value) {
    case IntegerLiteral(value: final number?):
      return number.toDouble();
    case DoubleLiteral(value: final number):
      return number;
    case ParenthesizedExpression(:final expression):
      return _number(expression);
    case PrefixExpression(:final operator, :final operand)
        when operator.lexeme == '-':
      final number = _number(operand);
      return number == null ? null : -number;
  }
  final element = switch (value) {
    SimpleIdentifier(:final element) => element,
    PrefixedIdentifier(:final element) => element,
    PropertyAccess(:final propertyName) => propertyName.element,
    _ => null,
  };
  final variable = switch (element) {
    PropertyAccessorElement(:final variable) => variable,
    VariableElement() => element,
    _ => null,
  };
  if (variable == null || !variable.isConst) return null;
  final constant = variable.computeConstantValue();
  return constant?.toDoubleValue() ?? constant?.toIntValue()?.toDouble();
}

Map<String, Expression> _named(ArgumentList arguments) => {
  for (final argument in arguments.arguments)
    if (argument is NamedExpression)
      argument.name.label.name: argument.expression,
};

/// The class [element] is, or the class it is a member of.
InterfaceElement? _owner(Element? element) => switch (element) {
  InterfaceElement() => element,
  Element(:final InterfaceElement enclosingElement) => enclosingElement,
  _ => null,
};

/// Whether [element] is declared in a library under [library].
bool _in(Element? element, String library) =>
    element?.library?.uri.toString().startsWith(library) ?? false;

/// Whether [element] is the class [name] from a library under [library].
bool _is(Element? element, String library, String name) =>
    element != null && element.name == name && _in(element, library);
