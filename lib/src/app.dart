import 'dart:ui' show Brightness;

import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// Sample home screen — replace with your app's content.
///
/// Demonstrates the Avio glass direction: an [AvioWindowScaffold] with a
/// frosted [AvioSidebar], a search field, a toolbar, and a content pane built
/// from `avio_ui` glass components. Everything is wired to design tokens, so
/// switching brightness or density restyles the whole app.
class AppHome extends StatefulWidget {
  const AppHome({
    required this.onBrightnessChanged,
    required this.onDensityChanged,
    super.key,
  });

  final ValueChanged<Brightness> onBrightnessChanged;
  final ValueChanged<AvioDensity> onDensityChanged;

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  static const _sections = <AvioSidebarSection<String>>[
    AvioSidebarSection<String>(
      title: 'General',
      items: [
        AvioSidebarItem(
          value: 'appearance',
          label: 'Appearance',
          icon: Icons.palette_outlined,
        ),
        AvioSidebarItem(
          value: 'notifications',
          label: 'Notifications',
          icon: Icons.notifications_outlined,
        ),
      ],
    ),
    AvioSidebarSection<String>(
      title: 'Workspace',
      items: [
        AvioSidebarItem(
          value: 'layout',
          label: 'Layout',
          icon: Icons.grid_view_outlined,
        ),
        AvioSidebarItem(
          value: 'shortcuts',
          label: 'Shortcuts',
          icon: Icons.keyboard_outlined,
        ),
      ],
    ),
    AvioSidebarSection<String>(
      title: 'System',
      items: [
        AvioSidebarItem(
          value: 'about',
          label: 'About',
          icon: Icons.info_outline,
        ),
      ],
    ),
  ];

  static const _titles = <String, String>{
    'appearance': 'Appearance',
    'notifications': 'Notifications',
    'layout': 'Layout',
    'shortcuts': 'Shortcuts',
    'about': 'About',
  };

  String _selected = 'appearance';
  int _viewMode = 0;
  bool _reduceMotion = false;
  double _accentStrength = 0.6;

  @override
  Widget build(BuildContext context) {
    final tokens = AvioTokens.of(context);

    return AvioWindowScaffold(
      title: Text(_titles[_selected] ?? 'Avio App'),
      searchField: const AvioSearchField(placeholder: 'Search settings'),
      actions: [
        AvioSegmentedControl<Brightness>(
          value: tokens.brightness,
          onChanged: widget.onBrightnessChanged,
          showLabels: false,
          segments: const [
            AvioSegmentData(
              value: Brightness.light,
              label: 'Light',
              icon: Icon(Icons.light_mode_outlined),
            ),
            AvioSegmentData(
              value: Brightness.dark,
              label: 'Dark',
              icon: Icon(Icons.dark_mode_outlined),
            ),
          ],
        ),
      ],
      sidebar: AvioSidebar<String>(
        selected: _selected,
        onSelected: (v) => setState(() => _selected = v),
        sections: _sections,
      ),
      content: _buildContent(tokens),
    );
  }

  Widget _buildContent(AvioTokenData tokens) {
    return switch (_selected) {
      'appearance' => _appearancePane(tokens),
      _ => _placeholderPane(
          tokens,
          _titles[_selected] ?? '',
          'This pane is a placeholder. Build it from avio_ui components.',
        ),
    };
  }

  Widget _appearancePane(AvioTokenData tokens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The star: a frosted glass card showcasing components on glass.
        AvioGlassSurface(
          tier: AvioGlassTier.elevated,
          borderRadius: tokens.radius.borderRadiusLg,
          padding: EdgeInsets.all(tokens.spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Liquid glass', style: tokens.typography.title),
              SizedBox(height: tokens.spacing.xs),
              Text(
                'Components adopt the frosted panel automatically when placed '
                'on an AvioGlassSurface — no per-widget styling required.',
                style: tokens.typography.body,
              ),
              SizedBox(height: tokens.spacing.lg),
              Row(
                children: [
                  AvioButton(
                    onPressed: () {},
                    child: const Text('Primary action'),
                  ),
                  SizedBox(width: tokens.spacing.sm),
                  AvioButton(
                    onPressed: () {},
                    variant: AvioButtonVariant.secondary,
                    child: const Text('Secondary'),
                  ),
                ],
              ),
              SizedBox(height: tokens.spacing.lg),
              _row(
                tokens,
                'Reduce motion',
                AvioToggle(
                  value: _reduceMotion,
                  onChanged: (v) => setState(() => _reduceMotion = v),
                ),
              ),
              SizedBox(height: tokens.spacing.md),
              _row(
                tokens,
                'Accent strength',
                SizedBox(
                  width: 200,
                  child: AvioSlider(
                    value: _accentStrength,
                    onChanged: (v) => setState(() => _accentStrength = v),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.spacing.lg),
        // A floating glass toolbar (capture-toolbar chrome).
        AvioToolbar(
          children: [
            AvioSegmentedControl<int>(
              value: _viewMode,
              onChanged: (v) => setState(() => _viewMode = v),
              showLabels: false,
              segments: const [
                AvioSegmentData(
                  value: 0,
                  label: 'Grid',
                  icon: Icon(Icons.grid_view),
                ),
                AvioSegmentData(
                  value: 1,
                  label: 'List',
                  icon: Icon(Icons.view_list),
                ),
              ],
            ),
            const AvioToolbarDivider(),
            AvioIconButton(
              onPressed: () {},
              icon: const Icon(Icons.add),
              tooltip: 'Add',
            ),
          ],
        ),
      ],
    );
  }

  Widget _placeholderPane(AvioTokenData tokens, String title, String body) {
    return AvioPanel(
      padding: EdgeInsets.all(tokens.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: tokens.typography.title.copyWith(
              color: tokens.colors.textPrimary,
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            body,
            style: tokens.typography.body.copyWith(
              color: tokens.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AvioTokenData tokens, String label, Widget control) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: tokens.typography.body),
        ),
        control,
      ],
    );
  }
}
