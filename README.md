![Timer Guy Logo](./static/svg/logo.svg)

_Workout creation app for interval training and probably more eventually_

Name tbd

- Works offline
- Will eventually be climbing specific

## Builds

GitHub Actions builds both targets on every push to `main`:

- **Web** — `.github/workflows/deploy-pages.yml` builds the web app and commits the
  output to `docs/`, which GitHub Pages serves at
  <https://bocsir.github.io/timer-guy/>.
- **Android** — `.github/workflows/build-android.yml` builds a release APK and
  publishes it to the [latest Android release](https://github.com/bocsir/timer-guy/releases/tag/android-latest).
  The APK is also available as a workflow artifact.

Both workflows can be run manually from the Actions tab. Pushing a `v*` tag
creates a versioned Android release instead of updating `android-latest`.

### Android signing

The CI build uses the same release keystore as local builds when these repository
secrets are configured:

| Secret | Description |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 ~/upload-keystore.jks` |
| `ANDROID_KEY_ALIAS` | Keystore alias (e.g. `upload`) |
| `ANDROID_STORE_PASSWORD` | Keystore password |
| `ANDROID_KEY_PASSWORD` | Key password |

Without them, the APK falls back to debug signing, which is installable for
sideloading but cannot update an app previously installed with the release key.
