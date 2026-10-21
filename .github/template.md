## Post-template-instantiation checklist

After clicking "Use this template" on GitHub and cloning locally:

1. **Run flutter create for the Linux scaffold** (it keeps the template's
   `lib/`, `test/` and `linux/runner/my_application.cc`)
   ```bash
   flutter create --empty --platforms=linux --org=dev.avio \
                  --project-name=avio_<yourapp> .
   ```

2. **Rename the app**
   - `pubspec.yaml` → `name: avio_<yourapp>`
   - Imports from `package:avio_app_template/...` →
     `package:avio_<yourapp>/...`
   - `AvioTemplateApp` and `title:` in `lib/app.dart`
   - `kWindowTitle` in `linux/runner/my_application.cc`
   - `APPLICATION_ID` in `linux/CMakeLists.txt` → `dev.avio.<yourapp>`

3. **Read the design language** — `DESIGN_LANGUAGE.md` in avio-sdk — and
   replace the sample panes in `lib/features/home/`.

4. **Replace the placeholder LICENSE** with your chosen SPDX text.

5. **Update README.md** — replace template prose with app-specific docs.

6. **First check**, with the engine-fork toolchain
   ```bash
   export FLUTTER_ROOT=$(cd ../avio && scripts/flutter-test-harness.sh root)
   $FLUTTER_ROOT/bin/flutter pub get
   $FLUTTER_ROOT/bin/flutter analyze --fatal-infos
   $FLUTTER_ROOT/bin/flutter test
   ```

7. **Set up local SDK override** for cross-repo dev
   ```bash
   cp pubspec_overrides.yaml.example pubspec_overrides.yaml
   ```

8. **Enable CI** — GitHub Actions runs automatically on push to `main`.

9. **First release**
   ```bash
   git tag v0.1.0 && git push --tags
   ```
   The `release.yml` workflow builds a Linux tarball and attaches it to
   the GitHub release.
