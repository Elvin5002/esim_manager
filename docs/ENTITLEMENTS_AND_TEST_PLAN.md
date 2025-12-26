# eSIM Entitlements & Device Test Plan

This document summarizes the required permissions/entitlements and provides a detailed device test plan for Android and iOS eSIM features (detection, listing, install, remove, activate). Use this as a reference while implementing platform flows and preparing manual integration tests.

---

## Important notes (short)
- eSIM provisioning features require **real devices** and **carrier support**. Emulators generally do not support provisioning flows.
- Many operations may be restricted to carrier/system apps or require special privileges; behavior varies across OEMs and OS versions.
- Only the Dart layer can be unit-tested automatically; most platform provisioning flows require manual testing.

---

## Android

### API & OS requirements
- Target Android devices that have eSIM support (many modern Pixel devices, some Samsung/OnePlus devices). 
- Many useful APIs require **Android 10 / API 29+** (DownloadableSubscription / EuiccManager provisioning enhancements). Some EuiccManager functionality may be present on earlier versions but behavior varies by device.

### Permissions / manifest
- Add the following to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.WRITE_EMBEDDED_SUBSCRIPTIONS" />
```

- Note: declaring the permission in the manifest is **not** a guarantee the app can perform all provisioning operations at runtime. Some operations may throw `SecurityException` if the app lacks carrier privileges or is not a privileged system app.

### Runtime behavior & cautions
- Use `EuiccManager` to check support and perform operations like `downloadSubscription(...)`. Many operations require a `PendingIntent` for result callbacks (success/failure/user interaction). 
- Be prepared to handle:
  - `SecurityException` when the app lacks permission or carrier privileges.
  - User cancellation (user may be shown system UI and cancel provisioning).
  - Network/server errors from the SM‑DP+ endpoint.
- Implementation guidance:
  - Build and pass a `DownloadableSubscription` (from activation code or SM‑DP+ URL) to `EuiccManager.downloadSubscription`.
  - Use a `BroadcastReceiver` or a `PendingIntent`-delivered `Activity` to receive the result and map it to plugin `InstallResult` statuses.

Example (pseudocode):

```kotlin
val euiccManager = context.getSystemService(EuiccManager::class.java)
val ds = DownloadableSubscription.createFromActivationCode(activationCode)
euiccManager.downloadSubscription(ds, false, pendingIntent)
```

> Important: test this flow on a real device with operator support — many carriers control provisioning and may return operator-specific flows.

### Android test checklist
- Devices:
  - Pixel 3/4/5/6/7 with eSIM support (or other verified eSIM device).
  - Test on at least one device with operator eSIM support.
- OS versions:
  - Android 10+ (API 29 or higher) recommended.

Test cases:
1. isEsimSupported(): returns true on supported device and false on unsupported devices.
2. listProfiles(): returns a list of installed profiles (empty or populated). Validate fields (id, iccid, eid, nickname, isActive).
3. installFromActivationCode(): provide a valid activation code; verify the plugin starts provisioning and returns success/pending/failure as appropriate. Confirm system UI, user acceptance, or automatic completion.
4. installFromSmDp(): provide a valid SM‑DP+ URL and optional confirmation code; verify behavior as above.
5. removeProfile(): remove a removable profile; verify result and that profile is removed from listProfiles.
6. getActiveProfile(): matches the device active subscription.
7. Error & permission handling: attempt install/remove when device lacks privileges and verify graceful error reporting (InstallResult.failed with informative message).
8. Edge cases: network failure, invalid SM‑DP+ URL, user cancellation, non-removable profiles.

Automation notes:
- Unit tests should mock the method channel (already in repo).
- Integration tests for provisioning flows should be manual and documented in the example app.

---

## iOS

### OS & API
- eSIM was introduced on iOS around iOS 12.1 and later; the `CoreTelephony` API includes `CTCellularPlanProvisioning` to add plans programmatically (often invokes system UI and requires user acceptance).

### Entitlements & App Store
- Some provisioning features may be restricted on iOS and require approval or entitlements from Apple or the carrier. Behavior and availability can vary depending on iOS version and carrier.
- If you rely on restricted behaviors, plan to coordinate with Apple/Carrier for entitlements and App Store review notes.

### Implementation & test notes
- Use `CTCellularPlanProvisioning` to request adding a plan (e.g., via QR or activation code). The system typically presents a UI for the user to confirm the plan installation.
- Test on real devices that support eSIM (iPhone XS and newer models that support eSIM).

Test cases:
1. isEsimSupported(): returns true on devices that support eSIM.
2. installFromActivationCode(): initiate an addPlan flow with a valid activation payload and confirm user consent flow works.
3. installFromSmDp(): where applicable, verify that provisioning via SM‑DP+ works or returns a clear failure if not supported.
4. removeProfile(): verify user or system-driven removal behaves as expected.
5. Entitlements: verify behavior when entitlements are not granted — the plugin should surface informative errors.

Automation notes:
- Most flows require manual testing on real hardware with carrier support.

---

## Test plan & process

1. Add manual integration test pages to the `example/` app:
   - A page to display `isEsimSupported()` and `listProfiles()` results.
   - Buttons to trigger `installFromActivationCode()` and `installFromSmDp()` with text fields to paste an activation code or SM‑DP+ URL.
   - A test log view showing step-by-step result messages and raw payloads returned from platform.

2. Prepare test cases and expected outcomes (see checklists above). For each test, collect:
   - Device model and OS version
   - Carrier name and whether eSIM provisioning is supported
   - Input used (activation code or SM‑DP+ URL)
   - Screenshots of system UI prompts (user consent) and returned results
   - Relevant logcat (Android) or device logs (iOS)

3. Reproduce failure scenarios: test invalid codes, user cancellation, network failure, and permission denials. Ensure plugin returns deterministic, documentable error messages.

4. Document known limitations and required permissions/entitlements in README and the example app (so testers know what to expect).

---

## Security & privacy
- Treat activation codes and SM‑DP+ URLs as sensitive: do not log them in plaintext in production logs. For test logs, redact or avoid storing codes.
- Clearly inform users and testers that provisioning will involve contacting carrier servers and may incur operator behavior (billing, restrictions).

---

## Appendices
- Links & references (update as needed):
  - Android EuiccManager documentation: https://developer.android.com/reference/android/telephony/euicc/EuiccManager
  - Android DownloadableSubscription: https://developer.android.com/reference/android/telephony/euicc/DownloadableSubscription
  - iOS CoreTelephony / CTCellularPlanProvisioning docs (Apple Developer)


---

If you'd like, I can also:
- Add an integration test page in `example/` that implements the manual test UI described above.
- Create a checklist template you can use when requesting carrier test support (email template, data to provide).

Let me know which of those you want next.