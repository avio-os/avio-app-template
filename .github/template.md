## Post-template-instantiation checklist

After clicking "Use this template" on GitHub and cloning locally:

1. **Run flutter create for the Linux runner**
   ```bash
   flutter create --platforms=linux --org=com.avio \
                  --project-name=avio_<yourapp> \
                  --description="Avio <YourApp>" .
   ```

2. **Rename the package**
   - Edit `pubspec.yaml` → `name: avio_<yourapp>`
   - Update imports from `package:avio_app_template/...` to
     `package:avio_<yourapp>/...`

3. **Replace the placeholder LICENSE** with your chosen SPDX text.

4. **Update README.md** — replace template prose with app-specific docs.

5. **First build**
   ```bash
   flutter pub get
   flutter run -d linux
   ```

6. **Set up local SDK override** for cross-repo dev
   ```bash
   cp pubspec_overrides.yaml.example pubspec_overrides.yaml
   ```

7. **Enable CI** — GitHub Actions runs automatically on push to `main`.

8. **First release**
   ```bash
   git tag v0.1.0 && git push --tags
   ```
   The `release.yml` workflow builds a Linux tarball and attaches it to
   the GitHub release.
