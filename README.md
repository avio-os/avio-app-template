# avio-app-template

GitHub template repository for standalone Avio applications (calculator,
media player, notes, …). It is a working Flutter Linux app wired to the Avio
SDK, so every new app starts with the same window, design rules, lints, tests
and update workflow. (Apps that ship as part of the OS live in the `avio`
repo under `apps/`; they start from this template too.)

## The design language

Avio's design language is one document:
[`DESIGN_LANGUAGE.md`](https://github.com/avio-os/avio-sdk/blob/main/DESIGN_LANGUAGE.md)
in avio-sdk (`../avio-sdk/DESIGN_LANGUAGE.md` in a local checkout). Read it
before you design a screen. It wins over this README, over the SDK's code and
over any older guideline. The rules an app author meets every day:

- **The window is the SDK's.** Every Avio app has the same frame: a
  chrome-glass window, the compositor's window controls top-right, and the
  controls row every app reserves through `AvioWindowControlsInset`. Build it
  from `AvioWindowScaffold`: an `AvioSidebar` (232 wide, search on top), an
  `AvioToolbar` of 28 px `AvioIconButton`s in the controls row, an
  `AvioPaneHeader`, and the body at the 24 px gutter. A single-pane app drops
  the sidebar. Never hard-code a header height, a controls offset or a
  sidebar width.
- **No raw colours.** Every colour comes from the tokens: `context.ink`
  (ink-1/2/3, placeholder, divider, hover, selected, pressed, disabled) and
  `context.tokens.colors` (accent, surfaces, status). No `Color(0x…)`, no
  `Colors.*`, no `.withValues(alpha:)` or `Opacity` to make a state — the
  tokens already are the state. The only hue is sky; app icons carry colour,
  the chrome does not.
- **No raw TextStyles.** Text uses a type role (`context.type.body`,
  `.paneTitle`, `.caption` …) on Figtree and changes only its colour. No
  `TextStyle(…)`, no font size, weight or tracking of your own.
- **No Material icons.** Symbols are Avio Symbols: `AvioIcon(AvioSymbol.trash)`
  at 12, 16, 20 or 24. No `Icons.*`, Cupertino or MDI icons, no `Icon`, no
  `IconData(…)`, no painted glyphs.
- **Components, not Material widgets.** `AvioButton`, `AvioListRow`,
  `AvioListGroup`, `AvioEmptyState`, `AvioAsk`, `AvioTextField` … Browse
  `avio-sdk/packages/avio_ui/lib/src/components/` before hand-rolling one, and
  add what is missing to the SDK. `MaterialApp` appears once, in
  `lib/app.dart`.
- **Exact-size images.** Decode every image at the size it is drawn:
  `cacheWidth`/`cacheHeight` = `round(logical size × devicePixelRatio)`, or a
  `ResizeImage`. Never decode large "for later" and let it be resampled.
- **The pixel grid.** Spacing is 4, 8, 12, 16, 20, 24, 32; heights are
  multiples of 4. A hairline is exactly one device pixel: draw it with
  `AvioHairline`/`AvioHairlineBox`, never a `Border` of your own.
- **Light and dark are one design.** Check both, and high contrast.

`test/design_rules_test.dart` enforces the rules on everything under `lib/`
(the SDK ships no lint package yet; the rules live in
`test/design_rules/design_rules.dart` and move to the SDK when it does).
`analysis_options.yaml` makes any deprecated SDK API an error, so an app
never stays on a replaced component.

## Use this template

1. Click **Use this template → Create a new repository** on GitHub.
2. Name the new repo `avio-<your-app>` (e.g. `avio-calculator`).
3. Clone it locally next to `avio` and `avio-sdk`:

   ```
   ~/projects/avio_research/
     ├── avio                 ← compositor + shell + portal
     ├── avio-sdk             ← design system (separate repo)
     ├── avio-calculator      ← new app (this template)
     └── avio-app-template    ← this template (don't edit in place)
   ```

4. **Run `flutter create` over the directory** to fill in the Linux
   platform scaffold. It keeps every file the template already has —
   `lib/`, `test/` and the Avio-aware `linux/runner/my_application.cc` — and
   `--empty` keeps it from adding a counter-app test:

   ```bash
   cd avio-calculator
   flutter create --empty --platforms=linux --org=dev.avio \
                  --project-name=avio_calculator .
   ```

5. Rename the app: `name:` in `pubspec.yaml` (the `--project-name` above),
   `AvioTemplateApp` and the `title:` in `lib/app.dart`, `kWindowTitle` in
   `linux/runner/my_application.cc`, and `APPLICATION_ID` in
   `linux/CMakeLists.txt` (`dev.avio.calculator`).
6. Replace the panes in `lib/features/home/` with your own.
7. `flutter pub get`, then `flutter analyze --fatal-infos` and
   `flutter test` with the engine-fork toolchain (below).

## Toolchain

`avio_ui` ships on Avio's engine fork (its `dart:ui` extensions carry the
compositor materials), so the stock Flutter SDK cannot compile it. Analyze
and test with the engine-fork harness the avio repository builds:

```bash
(cd ../avio && scripts/flutter-test-harness.sh build)   # once
export FLUTTER_ROOT=$(cd ../avio && scripts/flutter-test-harness.sh root)
$FLUTTER_ROOT/bin/flutter analyze --fatal-infos
$FLUTTER_ROOT/bin/flutter test
```

## What's in the template

| Path | Purpose |
|---|---|
| `pubspec.yaml` | The SDK (`avio_ui`, `avio_system`, `avio_materials`) pinned to one avio-sdk commit; lints and dev deps |
| `pubspec_overrides.yaml.example` | Local-dev override that points the SDK at a sibling `avio-sdk` clone |
| `analysis_options.yaml` | Strict mode, the lint set, deprecated SDK APIs as errors |
| `lib/main.dart` | Composition root: asks the compositor for window materials, then `runApp` |
| `lib/app.dart` | `AvioTemplateApp` (follows the system appearance) and `AppRoot`, the sanctioned root the tests mount too |
| `lib/features/home/home_screen.dart` | The sample window: sidebar, toolbar, pane header, panes — ready to replace |
| `linux/runner/my_application.cc` | Flutter's runner, with the undecorated, transparent window Avio frames and draws glass behind |
| `test/helpers/pump_avio.dart` | Widget-test harness: desktop-pinned `avioWidgetTest` and `pumpAvio`, which mounts `AppRoot` |
| `test/helpers/window_capture.dart` | Draws the window as Avio presents it (real fonts, glass over the sky) for geometry checks and review PNGs |
| `test/features/home/` | Behaviour tests for the sample screen, and the window-anatomy captures |
| `test/design_rules_test.dart` | The design rules, enforced on `lib/` |
| `test/provider_retry_test.dart` | Pins the composition root's no-auto-retry policy |
| `.github/workflows/ci.yml` | analyze + test + linux build on every push (it still installs stock Flutter, which cannot compile `avio_ui`; see Toolchain) |
| `.github/workflows/release.yml` | Tag-driven Flutter Linux build artifact |
| `LICENSE` | Placeholder — set to your preferred SPDX before first release |

## How the window works

`lib/app.dart` mounts, from the outside in: the compositor material host
(when the compositor offers Avio's materials, it renders the window's glass
in the same frame as the app), `MaterialApp` with the SDK's one theme factory
`AvioTheme.data`, `AvioRoot` (tokens, theme, Figtree body text in ink-1, the
text scale and bold text applied once), the toast host, and
`AvioDesktopApplicationSurface`, the window's one chrome-glass surface: it
reads where the compositor's window controls sit, makes blank space drag the
window, and hosts in-window popups. Panes put no glass or blur of their own
on top of it.

Under Avio the runner leaves the window undecorated and transparent, and the
compositor frames it. Apps the compositor frames seamlessly have the window
controls floating over the controls row's trailing corner, and the toolbar
keeps clear of them; other apps get the compositor's title band, and the same
layout runs to the window's edge. Off Avio the runner is Flutter's stock one.

`lib/app.dart` follows the system appearance (light or dark and the Avio
accent) over the desktop portal with `avio_system`'s `AvioAppearanceMonitor`.
With no portal reachable it stays on the light default.

## Checking what you built

Look at every UI change before calling it done, light and dark, at device
pixel ratios 1 and 2:

```bash
AVIO_UI_CAPTURE_DIR=/tmp/captures $FLUTTER_ROOT/bin/flutter test test/features/home
```

`test/features/home/home_window_test.dart` draws each state with the real
fonts, over a sky, through the window's glass, and writes the PNGs there. It
also holds the window to the shared anatomy on every run: the 232 px sidebar,
the search field and toolbar centred in the controls row, the toolbar ending
8 px short of the controls, the pane title at the 24 px gutter, Figtree on
every line and Avio Symbols for every symbol. Add a capture for each new
screen.

## Cross-repo development (SDK + app)

To try a local SDK change in your app, copy the example override into place:

```bash
cp pubspec_overrides.yaml.example pubspec_overrides.yaml
$FLUTTER_ROOT/bin/flutter pub get
```

`pubspec_overrides.yaml` is gitignored. CI never sees it; production builds
always use the pinned git ref.

To move the SDK your app depends on, set the `ref:` of all three SDK packages
in `pubspec.yaml` to the same avio-sdk commit and commit it.

## Conventions

- **App-id**: `dev.avio.<app>` (e.g. `dev.avio.calculator`) — matches Flatpak.
- **Package name**: `avio_<app>` snake_case (Dart pubspec restriction).
- **Repo name**: `avio-<app>` kebab-case (GitHub convention).
- **Bundle id (Linux desktop file)**: `dev.avio.<app>.desktop`.
- **App talks to compositor** via the standard Wayland surface (and Avio's
  window materials on it) plus, when needed, the `io.avio.Settings1` or other
  public D-Bus interfaces. Apps do **not** see the private
  `CompositorBridge1` / `ShellUi1` interfaces — those are reserved for the
  portal helper and the shell.

## Reference

See [`avio/PORTAL_SPEC.md`](https://github.com/avio-os/avio/blob/main/PORTAL_SPEC.md)
for the full architecture: trust topology, IPC layering, design rules.
