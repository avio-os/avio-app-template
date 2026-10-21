# Contributing

## Design

The Avio design language is
[`DESIGN_LANGUAGE.md`](https://github.com/avio-os/avio-sdk/blob/main/DESIGN_LANGUAGE.md)
in avio-sdk. Where this app and that file disagree, the app is the defect.
Every change keeps these rules (`test/design_rules_test.dart` checks them on
`lib/`):

- **Window anatomy from the SDK**: `AvioWindowScaffold` with `AvioSidebar`,
  `AvioToolbar` and `AvioPaneHeader`, inside the `AppRoot` window surface. No
  per-app chrome, no hard-coded header heights, controls offsets or sidebar
  widths.
- **No raw colours**: tokens only (`context.ink`, `context.tokens.colors`).
  No `Color(0x…)`, no `Colors.*`, no `.withValues(alpha:)`/`withOpacity`, no
  `Opacity` for states.
- **No raw TextStyles**: a type role from `context.type`, changing only its
  colour. No `TextStyle(…)`, `fontSize:`, `FontWeight` or `letterSpacing:`.
- **No Material icons**: `AvioIcon(AvioSymbol.x)` at 12/16/20/24. No
  `Icons.*`, Cupertino, MDI, `Icon`, `IconData(…)` or painted glyphs.
- **Avio components, not Material widgets**, and `MaterialApp` only in
  `lib/app.dart`.
- **Exact-size images**: every `Image.*` passes `cacheWidth`/`cacheHeight`
  at `round(logical × devicePixelRatio)`, or decodes through `ResizeImage`.
- **The pixel grid**: padding and gap literals are multiples of 4; hairlines
  come from `AvioHairline`/`AvioHairlineBox`, never a `Border` of your own.

A rule failing names the file, the line and what to use instead. Fix the
code; never loosen a rule or skip a test to get green. If the SDK lacks the
token or component you need, add it to avio-sdk.

## Pull requests

Run the checks with the engine-fork toolchain
(`export FLUTTER_ROOT=$(cd ../avio && scripts/flutter-test-harness.sh root)`;
the stock Flutter SDK cannot compile `avio_ui`):

- `dart format --set-exit-if-changed lib test` must pass.
- `flutter analyze --fatal-infos` must pass. Deprecated SDK APIs are errors:
  migrate to the replacement the analyzer names.
- `dart run custom_lint` must pass (this is what runs the Riverpod lints).
- `flutter test` must pass, with no skipped test. It includes the design
  rules and the window-anatomy captures.
- New screens get widget tests in `test/` (mirroring `lib/`) and a capture
  in the style of `test/features/home/home_window_test.dart`. Look at the
  captures (`AVIO_UI_CAPTURE_DIR=<dir> flutter test test/features`) light and
  dark, at 1x and 2x, before calling a UI change done.

## Filing bugs

When an issue might involve the design system (visual glitches, wrong
spacing, focus ring weirdness), include in the report:

- App version (`git rev-parse HEAD`)
- avio-sdk commit (the `ref:` of `avio_ui` in `pubspec.yaml`)
- Whether `pubspec_overrides.yaml` is active

Triage rubric:

- Visual is broken in **multiple Avio apps** → file in `avio-sdk`
- Visual is broken in **this app only** → file here
- Compositor / window-management bug → file in `avio`
- Portal / consent dialog bug → file in `avio` (the portal helper lives there)

## SDK changes

If you need a new component or token, add it to `avio-sdk` rather than
hacking around it locally. Open the SDK PR first; once it is merged, move
all three SDK `ref:`s in `pubspec.yaml` to that commit together.
