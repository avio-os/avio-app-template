import 'package:avio_ui/avio_ui.dart';
import 'package:flutter/widgets.dart';

/// Sample home screen — replace with your app's content.
///
/// Demonstrates the recommended layout pattern: an [AvioPanel] root,
/// padding via density tokens, content built from primitives in
/// `avio_ui`.
class AppHome extends StatelessWidget {
  const AppHome({
    required this.onBrightnessChanged,
    required this.onDensityChanged,
    super.key,
  });

  final ValueChanged<Brightness> onBrightnessChanged;
  final ValueChanged<AvioDensity> onDensityChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = AvioTokens.of(context);

    return AvioPanel(
      padding: EdgeInsets.all(tokens.spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avio App Template',
            style: tokens.typography.title.copyWith(
              color: tokens.colors.text.primary,
            ),
          ),
          SizedBox(height: tokens.spacing.md),
          Text(
            'This screen is a placeholder. Edit lib/src/app.dart to build '
            'your app. The avio_ui design system is already wired — try '
            'AvioButton, AvioListItem, AvioDialog, AvioPopover, …',
            style: tokens.typography.body.copyWith(
              color: tokens.colors.text.secondary,
            ),
          ),
          SizedBox(height: tokens.spacing.lg),
          Row(
            children: [
              AvioButton.primary(
                onPressed: () {},
                child: const Text('Primary action'),
              ),
              SizedBox(width: tokens.spacing.sm),
              AvioButton.secondary(
                onPressed: () {},
                child: const Text('Secondary'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
