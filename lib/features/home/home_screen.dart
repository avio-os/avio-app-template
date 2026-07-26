import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// The panes reachable from the source list.
enum _Pane { overview, activity, about }

/// Sample home screen — replace this with your app's content.
///
/// A neutral-chrome two-pane window in the avio skin: an opaque `bgCanvas`
/// source list on the left, an opaque `bgContent` pane on the right, a hairline
/// between them. Color arrives only through the sidebar's category wells and
/// the ink accent; there is no glass in app content. Every value comes from
/// `context.tokens`, so light, dark, accent and density changes restyle the
/// whole screen without touching this file.
///
/// `AvioWindowScaffold` is the SDK's two-pane composite, but it draws a
/// rounded, undecorated frame with a compositor-glass sidebar — that is for
/// first-party windows hosted inside the Avio compositor. A standalone app
/// gets a normal system title bar, so this screen composes the two panes
/// directly.
class HomeScreen extends StatefulWidget {
  /// Creates the sample home screen.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _sections = <AvioSidebarSection<_Pane>>[
    AvioSidebarSection<_Pane>(
      title: 'Workspace',
      items: [
        AvioSidebarItem(
          value: _Pane.overview,
          label: 'Overview',
          icon: Icons.dashboard_outlined,
          well: 'blue',
        ),
        AvioSidebarItem(
          value: _Pane.activity,
          label: 'Activity',
          icon: Icons.bolt_outlined,
          well: 'purple',
        ),
      ],
    ),
    AvioSidebarSection<_Pane>(
      title: 'App',
      items: [
        AvioSidebarItem(
          value: _Pane.about,
          label: 'About',
          icon: Icons.info_outline,
          well: 'gray',
        ),
      ],
    ),
  ];

  _Pane _pane = _Pane.overview;
  final List<String> _items = <String>[];

  void _addItem() {
    final name = 'Sample item ${_items.length + 1}';
    setState(() => _items.add(name));
    _toast('Added $name.', variant: AvioToastVariant.success);
  }

  void _clearItems() {
    setState(_items.clear);
    _toast('Cleared the sample list.');
  }

  /// Shows a toast. Without an explicit duration a toast waits for the user to
  /// dismiss it, which is rarely what you want for confirmations.
  void _toast(
    String message, {
    AvioToastVariant variant = AvioToastVariant.neutral,
  }) {
    AvioToastController.of(context).show(
      AvioToastData(
        message: message,
        variant: variant,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return ColoredBox(
      color: tokens.colors.bgCanvas,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvioSidebar<_Pane>(
            selected: _pane,
            onSelected: (pane) => setState(() => _pane = pane),
            sections: _sections,
            width: tokens.spacing.sidebarWidth,
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.colors.bgContent,
                border: Border(
                  left: BorderSide(color: tokens.colors.borderSubtle),
                ),
              ),
              child: _contentPane(tokens),
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentPane(AvioTokenData tokens) {
    final edge = tokens.spacing.contentEdge;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            edge,
            tokens.spacing.lg,
            edge,
            tokens.spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _paneTitle,
                style: tokens.typography.paneTitle.copyWith(
                  color: tokens.colors.inkPrimary,
                ),
              ),
              SizedBox(height: tokens.spacing.xxs),
              Text(
                _paneSubtitle,
                style: tokens.typography.body.copyWith(
                  color: tokens.colors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(edge, 0, edge, tokens.spacing.xl),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                // The content column stops at the reading measure instead of
                // stretching across a wide window.
                constraints: BoxConstraints(
                  maxWidth: tokens.spacing.contentMax,
                ),
                child: switch (_pane) {
                  _Pane.overview => _overviewPane(tokens),
                  _Pane.activity => const _PlaceholderPane(
                    title: 'Nothing has happened yet',
                    description:
                        'Replace this pane with your own content, built from '
                        'avio_ui components and context.tokens.',
                    icon: Icons.bolt_outlined,
                  ),
                  _Pane.about => const _PlaceholderPane(
                    title: 'About this app',
                    description:
                        'Version, credits and links belong here. Delete the '
                        'pane if your app has no use for it.',
                    icon: Icons.info_outline,
                  ),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  String get _paneTitle => switch (_pane) {
    _Pane.overview => 'Overview',
    _Pane.activity => 'Activity',
    _Pane.about => 'About',
  };

  String get _paneSubtitle => switch (_pane) {
    _Pane.overview => 'The starting point for your app.',
    _Pane.activity => 'A placeholder pane.',
    _Pane.about => 'A placeholder pane.',
  };

  Widget _overviewPane(AvioTokenData tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AvioCard(
          padding: tokens.spacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start here',
                style: tokens.typography.title.copyWith(
                  color: tokens.colors.inkPrimary,
                ),
              ),
              SizedBox(height: tokens.spacing.xs),
              Text(
                'This screen is a placeholder built from unified Avio '
                'components. Swap it for your own panes — the tokens, theme '
                'and system-appearance wiring stay the same.',
                style: tokens.typography.body.copyWith(
                  color: tokens.colors.inkSecondary,
                ),
              ),
              SizedBox(height: tokens.spacing.lg),
              Row(
                children: [
                  AvioButton(
                    onPressed: _addItem,
                    child: const Text('Add sample item'),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  AvioButton(
                    onPressed: _items.isEmpty ? null : _clearItems,
                    variant: AvioButtonVariant.secondary,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.md),
        _itemList(tokens),
      ],
    );
  }

  Widget _itemList(AvioTokenData tokens) {
    if (_items.isEmpty) {
      return AvioCard(
        padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
        child: const AvioEmptyState(
          title: 'No items yet',
          description: 'Add a sample item to see list rows here.',
          icon: Icon(Icons.inbox_outlined),
          size: AvioEmptyStateSize.small,
        ),
      );
    }

    return AvioCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++)
            AvioSimpleListItem(
              title: _items[i],
              subtitle: 'Select the row to confirm with a toast',
              leadingIcon: Icons.description_outlined,
              showDivider: i < _items.length - 1,
              onTap: () => _toast('Selected ${_items[i]}.'),
            ),
        ],
      ),
    );
  }
}

/// A pane with no content of its own — delete these once your app has real
/// panes to show.
class _PlaceholderPane extends StatelessWidget {
  const _PlaceholderPane({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return AvioCard(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xxl),
      child: AvioEmptyState(
        title: title,
        description: description,
        icon: Icon(icon),
      ),
    );
  }
}
