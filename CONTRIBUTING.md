# Contributing

## Filing bugs

When an issue might involve the design system (visual glitches, wrong
spacing, focus ring weirdness), include in the report:

- App version (`git rev-parse HEAD`)
- avio_ui version (`pubspec.lock` row for `avio_ui`)
- Whether `pubspec_overrides.yaml` is active

Triage rubric:

- Visual is broken in **multiple Avio apps** → file in `avio-sdk`
- Visual is broken in **this app only** → file here
- Compositor / window-management bug → file in `avio`
- Portal / consent dialog bug → file in `avio` (the portal helper lives there)

## Pull requests

- `flutter analyze --fatal-infos` must pass.
- `flutter test` must pass.
- Widget tests for new screens go in `test/`.
- Use `AvioTokens.of(context)` for all colors, spacing, motion. Don't
  hard-code values — that defeats theme follow-through and accessibility
  overrides (high contrast, reduced motion).

## SDK changes

If you need a new component or token, prefer adding it to `avio-sdk`
rather than hacking around it locally. Open the SDK PR first; once
merged and tagged, bump this app's `pubspec.yaml` ref to consume it.
