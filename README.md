# esim_manager

A new Flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

The plugin project was generated without specifying the `--platforms` flag, no platforms were originally supported.
To add platforms, run `flutter create -t plugin --platforms <platforms> .` in this directory.
You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/to/pubspec-plugin-platforms.

## Android support (experimental) 🚧

I added an Android plugin skeleton (Kotlin) with the following:

- `EsimManagerPlugin.kt` (Android platform entry, method-channel "esim_manager").
- Basic implementation of `isEsimSupported()` using `EuiccManager` (API 29+).
- Stubs for `listProfiles`, `installFromActivationCode`, `installFromSmDp`, `removeProfile`, `getActiveProfile` which are TODOs needing device testing and implementation.
- Added `WRITE_EMBEDDED_SUBSCRIPTIONS` permission to `android/src/main/AndroidManifest.xml` (note: many eSIM operations require system/carrier privileges; some APIs will only work on carrier or OEM apps).

Notes:
- Real eSIM installation flows require `EuiccManager.downloadSubscription()` and handling a result via `PendingIntent` — they need real devices and carrier support for testing.
- Next steps: implement `downloadSubscription` flow, add request/result handling (the plugin now emits `onInstallResult` callbacks to Dart on Android and iOS), implement fully-tested iOS provisioning using `CTCellularPlanProvisioning` (requires device testing and may require entitlements), add integration tests in `example/` and document required permissions/entitlements.

---

## Entitlements & Device Test Plan 🧪

I created a detailed reference (platform entitlements, required permissions, OS notes, and a step-by-step device test plan) in `docs/ENTITLEMENTS_AND_TEST_PLAN.md`. This is the primary checklist to follow before attempting to run provisioning flows on real devices.

Please read that doc before implementing the full provisioning flows — it contains device/test guidance, expected behavior, and integration checklist items.
