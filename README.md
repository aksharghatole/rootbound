# Rootbound

A turn-based survival game about being a tree. Choose deeper roots, a taller trunk or more leaves each season, survive hazards, and reach Season 12 to unlock the next seed.

## Play

Android (portrait), built with Godot 4.3 and GDScript.

- [Download the M8 debug APK](https://github.com/aksharghatole/rootbound/releases/tag/m8-debug-1).
- For development, open `project.godot` in Godot 4.3.

## Development

Run the headless import and regression suite on Linux or Codespaces:

```sh
bash scripts/check.sh
```

Set `GODOT_BIN` if the executable is not named `godot`.

To build a debug APK in Codespaces:

```sh
bash scripts/setup_android_sdk.sh
bash scripts/build_android.sh
```

Output: `build/rootbound.apk`. The Android build workflow also produces a downloadable debug APK artifact after successful headless checks and signature verification. See [Actions](https://github.com/aksharghatole/rootbound/actions) and the [device checklist](docs/android_test_checklist.md). CI uses a temporary debug signing key; existing APKs signed with another key cannot be updated in place. Do not uninstall an existing installation without considering its local save data.

## Status

M8 Android debug build is released. [M9](https://github.com/aksharghatole/rootbound/issues/9) covers safe-area handling, audio verification and UX polish. Physical Android verification is required before declaring M9 complete.

## License

MIT — see `LICENSE`.
