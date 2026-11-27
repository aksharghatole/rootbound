# Android device verification — M9

Use a fresh debug APK from the Android debug APK workflow. CI-generated debug keys are temporary; if Android rejects an update because the previous app has another signing key, preserve existing save data and test on a separate device/profile where possible. Do not uninstall without understanding data loss.

Record device model, Android version, screen resolution, build commit and APK SHA-256.

- [ ] Install and launch; version label reads 0.9.0-m9.
- [ ] Portrait notch/cutout and gesture bar do not obscure title, HP, season or buttons.
- [ ] On a phone with no cutout, no unnecessary safe-area padding.
- [ ] Main menu, seed picker, gameplay and results remain readable.
- [ ] Tap sounds audible on menu, seed and growth buttons.
- [ ] Ambient audio starts on gameplay and stops on returning to menu.
- [ ] Seasonal event, win and death sounds audible without clipping.
- [ ] Growth points, advance season, event log and results function normally.
- [ ] Continue restores a run after closing and reopening the app.
- [ ] Finish a run; unlock and retry seeds as expected.
- [ ] Record screenshots and audio observations, and report any defects in issue #9.

Headless CI cannot establish real-device audio quality or display cutout behavior. Mark the checklist only after physical verification.
