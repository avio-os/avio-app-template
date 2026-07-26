import 'package:flutter/widgets.dart';

import 'src/app.dart';

/// Composition root. Keep it tiny: initialise bindings, build the real
/// services your app needs, then hand them to the root widget and `runApp`.
void main() {
  runApp(const AvioTemplateApp());
}
