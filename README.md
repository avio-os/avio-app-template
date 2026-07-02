# avio-app-template

GitHub template repository for first-party Avio applications (file browser,
settings, terminal, calculator, media player, …). Provides a working
Flutter Linux skeleton wired to the Avio SDK so every new app starts with
the same lints, CI, design tokens, and update workflow.

## Use this template

1. Click **Use this template → Create a new repository** on GitHub.
2. Name the new repo `avio-<your-app>` (e.g. `avio-calculator`).
3. Clone it locally next to `avio-sdk`:

   ```
   ~/projects/avio_research/
     ├── avio                 ← compositor + shell + portal
     ├── avio-sdk             ← design system (separate repo)
     ├── avio-calculator      ← new app (this template)
     └── avio-app-template    ← this template (don't edit in place)
   ```

4. **Run `flutter create` over the directory** to fill in the Flutter
   Linux platform scaffold (`linux/`, `android/`, etc. — we keep `linux/`,
   delete the rest):

   ```bash
   cd avio-calculator
   flutter create --platforms=linux --org=com.avio \
                  --project-name=avio_calculator \
                  --description="Avio Calculator" .
   ```

5. Rename `lib/main.dart`'s app class to your app's name.
6. Update `pubspec.yaml` — change `name:` from `avio_app_template` to your
   chosen package name (must match `--project-name` above).
7. Customise `assets/` and `lib/`.
8. `flutter pub get` and verify the SDK fetches cleanly.
9. `flutter run -d linux` to smoke-test the design-system wiring.

## What's in the template

| Path | Purpose |
|---|---|
| `pubspec.yaml` | Dependencies pinned to `avio-sdk` git ref; lints + dev deps |
| `pubspec_overrides.yaml.example` | Local-dev override that points to a sibling `avio-sdk` clone |
| `analysis_options.yaml` | Strict mode, Avio lint set |
| `lib/main.dart` | `runApp` wrapped in `AvioTokens` + `AvioToastProvider` |
| `lib/src/app.dart` | Sample `AvioWindowScaffold` glass screen (sidebar + toolbar + glass components), ready to replace |
| `test/widget_test.dart` | Smoke test |
| `.github/workflows/ci.yml` | analyze + test + linux build on every push |
| `.github/workflows/release.yml` | Tag-driven Flutter Linux build artifact |
| `.gitignore` | Standard Flutter + Dart entries |
| `LICENSE` | Placeholder — set to your preferred SPDX before first release |

## Cross-repo development (SDK + app)

When you need to test a local SDK change in your app, copy the example
override into place:

```bash
cp pubspec_overrides.yaml.example pubspec_overrides.yaml
flutter pub get
```

`pubspec_overrides.yaml` is gitignored. CI never sees it; production
builds always use the pinned git ref.

To bump the SDK version your app depends on, edit the `ref:` in
`pubspec.yaml` (use a tag like `avio_ui-v1.2.0`, never a branch in
production) and commit.

## Conventions

- **App-id**: `dev.avio.<app>` (e.g. `dev.avio.calculator`) — matches Flatpak.
- **Package name**: `avio_<app>` snake_case (Dart pubspec restriction).
- **Repo name**: `avio-<app>` kebab-case (GitHub convention).
- **Bundle id (Linux desktop file)**: `dev.avio.<app>.desktop`.
- **App talks to compositor** via the standard Wayland surface plus, when
  needed, the `io.avio.Settings1` or other public D-Bus interfaces. Apps
  do **not** see the private `CompositorBridge1` / `ShellUi1` interfaces
  — those are reserved for the portal helper and the shell.

## Reference

See [`avio/PORTAL_SPEC.md`](https://github.com/avio-os/avio/blob/main/PORTAL_SPEC.md)
for the full architecture: trust topology, IPC layering, design rules.
