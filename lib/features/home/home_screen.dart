import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/widgets.dart';

/// The panes reachable from the sidebar.
enum _Pane { overview, activity, about }

/// Sample home screen — replace its panes with your app's content.
///
/// It is the Avio window anatomy every app shares, from the SDK: an
/// [AvioSidebar] down the leading edge (search on top, aligned with the
/// window controls), an [AvioToolbar] in the controls row, an
/// [AvioPaneHeader] at the same inset as in every other app, and the body
/// 24 in from the pane's edges. [AvioWindowScaffold] lays them out; the
/// window's glass comes from the `AvioDesktopApplicationSurface` that
/// `AppRoot` puts around this screen. Nothing here picks a colour, a size or
/// a font: light, dark, high contrast and the accent restyle it for free.
///
/// A single-pane app drops the `sidebar:` argument; the toolbar, header and
/// body keep their places.
class HomeScreen extends StatefulWidget {
  /// Creates the sample home screen.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Pane _pane = _Pane.overview;
  final List<String> _items = <String>[];
  int _added = 0;
  String _query = '';

  void _addItem() {
    final name = 'Sample item ${++_added}';
    setState(() => _items.add(name));
    _toast('Added $name.', variant: AvioToastVariant.success);
  }

  void _clearItems() {
    setState(_items.clear);
    _toast('Cleared the sample list.');
  }

  /// The sidebar's search filters the sample items, which live on Overview.
  void _search(String query) {
    setState(() {
      _query = query.trim();
      if (_query.isNotEmpty) _pane = _Pane.overview;
    });
  }

  /// Shows a toast that leaves on its own after four seconds. Without a
  /// duration a toast waits for the user to dismiss it, which is rarely what
  /// a confirmation wants.
  void _toast(
    String message, {
    AvioToastVariant variant = AvioToastVariant.neutral,
  }) {
    AvioToastController.of(context).show(
      AvioToastData(
        message: message,
        variant: variant,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pane = _paneBody();
    return AvioWindowScaffold(
      sidebar: AvioSidebar<_Pane>(
        selected: _pane,
        onSelected: (pane) => setState(() => _pane = pane),
        search: AvioSidebarSearch(
          placeholder: 'Search items',
          onChanged: _search,
        ),
        children: const [
          AvioSidebarRow(
            value: _Pane.overview,
            symbol: AvioSymbol.home,
            label: 'Overview',
          ),
          AvioSidebarRow(
            value: _Pane.activity,
            symbol: AvioSymbol.history,
            label: 'Activity',
          ),
          AvioSidebarSection<_Pane>(
            title: 'App',
            children: [
              AvioSidebarRow(
                value: _Pane.about,
                symbol: AvioSymbol.info,
                label: 'About',
              ),
            ],
          ),
        ],
      ),
      // Toolbar actions belong to the pane they act on. The most frequent
      // one sits nearest the window controls.
      toolbar: AvioToolbar(
        actions: [
          if (_pane == _Pane.overview) ...[
            AvioIconButton(
              symbol: AvioSymbol.trash,
              tooltip: 'Clear sample items',
              onPressed: _items.isEmpty ? null : _clearItems,
            ),
            AvioIconButton(
              symbol: AvioSymbol.add,
              tooltip: 'Add sample item',
              onPressed: _addItem,
            ),
          ],
        ],
      ),
      header: switch (_pane) {
        _Pane.overview => const AvioPaneHeader(
          title: 'Overview',
          caption: 'The starting point for your app.',
        ),
        _Pane.activity => const AvioPaneHeader(
          title: 'Activity',
          caption: 'A placeholder pane.',
        ),
        _Pane.about => const AvioPaneHeader(
          title: 'About',
          caption: 'What this app is and who made it.',
        ),
      },
      scrollable: pane.scrolls,
      body: pane.scrolls ? pane.body : Center(child: pane.body),
    );
  }

  /// The current pane's content, and whether it scrolls. Content scrolls; an
  /// empty state stands centred in the pane.
  _PaneBody _paneBody() => switch (_pane) {
    _Pane.overview => _overview(),
    _Pane.activity => (
      body: const AvioEmptyState(
        symbol: AvioSymbol.history,
        title: 'Nothing has happened yet',
        description:
            'Replace this pane with your own content, built from avio_ui '
            'components and the design tokens.',
      ),
      scrolls: false,
    ),
    _Pane.about => (
      body: const AvioListGroup(
        header: 'This app',
        footer:
            'Version, credits and links belong here. Delete the pane if '
            'your app has no use for it.',
        children: [
          AvioListRow(title: 'Version', value: '0.1.0'),
          AvioListRow(title: 'Built with', value: 'Flutter and the Avio SDK'),
        ],
      ),
      scrolls: true,
    ),
  };

  _PaneBody _overview() {
    if (_items.isEmpty) {
      return (
        body: AvioEmptyState(
          symbol: AvioSymbol.inbox,
          title: 'No items yet',
          description: 'Add a sample item to see list rows here.',
          primaryActionLabel: 'Add sample item',
          onPrimaryAction: _addItem,
        ),
        scrolls: false,
      );
    }
    final query = _query.toLowerCase();
    final shown = [
      for (final item in _items)
        if (item.toLowerCase().contains(query)) item,
    ];
    if (shown.isEmpty) {
      return (
        body: AvioEmptyState(
          symbol: AvioSymbol.search,
          title: 'No matches',
          description: 'No sample item contains “$_query”.',
        ),
        scrolls: false,
      );
    }
    final list = AvioListGroup(
      header: 'Sample items',
      footer: 'Select a row to confirm with a toast.',
      children: [
        for (final item in shown)
          AvioListRow(
            symbol: AvioSymbol.fileText,
            title: item,
            onPressed: () => _toast('Selected $item.'),
          ),
      ],
    );
    return (body: list, scrolls: true);
  }
}

/// A pane's content and whether it scrolls.
typedef _PaneBody = ({Widget body, bool scrolls});
