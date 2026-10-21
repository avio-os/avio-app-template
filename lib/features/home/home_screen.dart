import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/services.dart';
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
/// **Actions are declared, not placed.** The window states what it can do
/// once, as [AvioAction]s in an [AvioActionHost]: New for the app, Sort and
/// Clear for the page, Delete on each row. The SDK puts each where the hand
/// is (New beside the sidebar search, the page's actions in its "…" at the
/// pane title, a row's on the row), or, when the person picks "App actions:
/// In the toolbar" in Settings, in one group at the start of the controls
/// row. The window controls always stand alone; never draw a button for a
/// declared action yourself.
///
/// **Act, then offer it back.** Delete and Clear never ask first: the rows
/// leave at once and an [AvioUndoHost] offers them back for ten seconds.
/// The removal is held (`AvioUndoKind.deferred`) and carried out only when
/// the offer ends untaken.
///
/// A single-pane app drops the `sidebar:` argument and declares its New as
/// a `page` action; the toolbar, header and body keep their places.
class HomeScreen extends StatefulWidget {
  /// Creates the sample home screen.
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  _Pane _pane = _Pane.overview;
  final List<String> _items = <String>[];

  /// Items removed while their undo offer stands: hidden now, gone for good
  /// when the offer ends untaken.
  final Set<String> _held = <String>{};
  final AvioUndoController _undo = AvioUndoController();
  int _added = 0;
  String _query = '';
  bool _sorted = false;

  @override
  void dispose() {
    // Commits whatever is still held.
    _undo.dispose();
    super.dispose();
  }

  /// The items the list shows: not held for undo, sorted when asked.
  List<String> get _shown {
    final shown = [
      for (final item in _items)
        if (!_held.contains(item)) item,
    ];
    if (_sorted) shown.sort();
    return shown;
  }

  void _addItem() {
    final name = 'Sample item ${++_added}';
    setState(() {
      _items.add(name);
      _pane = _Pane.overview;
    });
    _toast('Added $name.', variant: AvioToastVariant.success);
  }

  /// Removes [names] at once and offers them back.
  void _remove(List<String> names, String message) {
    setState(() => _held.addAll(names));
    _undo.offer(
      AvioUndoOffer(
        message: message,
        kind: AvioUndoKind.deferred,
        onUndo: () => setState(() => _held.removeAll(names)),
        // The rows are already hidden, so carrying the removal out changes
        // nothing on screen. A real app deletes the data here.
        onCommit: () {
          _items.removeWhere(names.contains);
          _held.removeAll(names);
        },
      ),
    );
  }

  void _deleteItem(String name) => _remove([name], 'Deleted “$name”');

  void _clearItems() {
    final names = _shown;
    _remove(
      names,
      names.length == 1
          ? 'Cleared 1 sample item'
          : 'Cleared ${names.length} sample items',
    );
  }

  /// The sidebar's search filters the sample items, which live on Overview.
  void _search(String query) {
    setState(() {
      _query = query.trim();
      if (_query.isNotEmpty) _pane = _Pane.overview;
    });
  }

  /// Shows a toast that leaves on its own after four seconds. A toast
  /// reports an event; it is never the only way back (that is [AvioUndo]).
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

  /// New: the app's action, beside the sidebar search.
  AvioAction get _newItem => AvioAction(
    id: 'template.new',
    label: 'New sample item',
    scope: AvioActionScope.app,
    symbol: AvioSymbol.add,
    shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
    onInvoke: _addItem,
  );

  /// The Overview page's actions, in its "…".
  List<AvioAction> _pageActions() {
    if (_pane != _Pane.overview || _shown.isEmpty) return const [];
    return [
      AvioAction(
        id: 'template.sort',
        label: 'Sort by name',
        scope: AvioActionScope.page,
        symbol: AvioSymbol.sort,
        checked: _sorted,
        onInvoke: () => setState(() => _sorted = !_sorted),
      ),
      AvioAction(
        id: 'template.clear',
        label: 'Clear sample items',
        scope: AvioActionScope.page,
        symbol: AvioSymbol.trash,
        destructive: true,
        onInvoke: _clearItems,
      ),
    ];
  }

  /// One row's actions, on the row.
  List<AvioAction> _itemActions(String item) => [
    AvioAction(
      id: 'template.delete',
      label: 'Delete',
      scope: AvioActionScope.item,
      symbol: AvioSymbol.trash,
      destructive: true,
      shortcut: const SingleActivator(LogicalKeyboardKey.delete),
      semanticLabel: 'Delete “$item”',
      onInvoke: () => _deleteItem(item),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pane = _paneBody();
    return AvioUndoHost(
      controller: _undo,
      child: AvioActionHost(
        app: [_newItem],
        page: _pageActions(),
        child: AvioWindowScaffold(
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
          // The controls row: navigation would lead it. It holds no app
          // action of its own; in the toolbar placement the SDK puts the
          // declared set at its start.
          toolbar: const AvioToolbar(),
          header: switch (_pane) {
            _Pane.overview => const AvioPaneHeader(
              title: 'Overview',
              caption: 'The starting point for your app.',
              trailing: AvioActionMenuButton(),
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
        ),
      ),
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
    final items = _shown;
    if (items.isEmpty) {
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
      for (final item in items)
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
            actions: _itemActions(item),
            onPressed: () => _toast('Selected $item.'),
          ),
      ],
    );
    return (body: list, scrolls: true);
  }
}

/// A pane's content and whether it scrolls.
typedef _PaneBody = ({Widget body, bool scrolls});
