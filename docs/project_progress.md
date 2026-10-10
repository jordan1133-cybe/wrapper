# Project Progress: Dashen Mobile App Flutter Wrappers

> **Tracking Standard**: Spec-Driven Development (SDD) Actionable Task Registry  
> **Rule**: Items marked `[Done]` have passed static analysis, unit tests, and/or physical device verification.

---

## Phase 1 — Wrapper Foundation
- [x] Create clean multi-module structure (`stockist_wrapper` and `sales_rep_wrapper`).
- [x] Configure `webview_flutter` with unrestricted JavaScript and secure `NavigationDelegate`.
- [x] Implement `PopScope` for Android system back button navigation within WebView history.
- [x] Implement loading indicator (`LinearProgressIndicator`) and retry UI on connection failures.
- [x] Fix package name typos and add `INTERNET` permission to `AndroidManifest.xml`.
- [x] Add intent queries in `AndroidManifest.xml` for `tel:`, `mailto:`, `sms:`, `geo:`, and `https:` URL schemes.

---

## Phase 2 — Native Capability Foundation & Physical Device Validation
- [x] **Location Service**: Integrate `geolocator`, request Android runtime permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`), fetch coordinates with timeout.
- [x] **Camera Service**: Integrate `image_picker`, request `CAMERA` permission, return provisional image data.
- [x] **File Picker Service**: Integrate `file_picker`, support image/media/any file selection.
- [x] **Provisional Bridge Handler**: Implement JSON request/response envelope with `requestId` routing.
- [x] **Unit Testing**: Add `bridge_message_test.dart` for request parsing, envelope validation, and error serialization.
- [x] **Local Test Harness**: Create `test_harness.html` asset and integrate with `AppConfig.useTestHarness`.
- [x] **Physical Device End-to-End Verification**:
  - [x] GPS `get_location` -> Real coordinates received (Lat: 9.034105, Lng: 38.764766, Acc: 38m).
  - [x] Camera `open_camera` -> Real image captured and returned through bridge.
  - [x] File Picker `pick_file` -> Successfully selected and returned file metadata/data.
  - [x] Error Routing -> `test_unknown_action` returned structured `UNKNOWN_ACTION` error.

---

## Phase 3 — Native Wrapper Hardening (Risk-Free)
- [x] **3A — Bridge Hardening**:
  - [x] Standardize all error codes across `BridgeConstants` and `NativeOperationException`.
  - [x] Add safe payload sanitization for debug logging (no giant base64 dumps or leaked credentials).
  - [x] Handle missing action, malformed JSON, and invalid argument types gracefully.
- [x] **3B — Native Service Boundaries**:
  - [x] Clean separation between `BridgeHandler` and native services.
  - [x] Map Android permission states (`denied`, `deniedForever`) to explicit error codes.
  - [x] Handle cancellation cleanly across camera and file pickers.
- [x] **3C — Configuration Preparation**:
  - [x] Centralize `devUrl`, `prodUrl`, `useTestHarness`, and `trustedHosts` in `AppConfig`.
  - [x] Enable `useTestHarness = true` by default in `stockist_wrapper` for device testing.
- [x] **3D — WebView Security Hardening**:
  - [x] Enforce host allowlisting in `NavigationHandler` to protect `DashenBridge` from untrusted web content.
  - [x] Route external  web navigation and hardware intents to external system apps.
- [x] **3E — Permission and Error UX**:
  - [x] Return structured, localized-ready error messages without leaking internal exception stack traces.
- [x] **3F — Documentation Maintenance**:
  - [x] Establish `docs/project_plan.md`, `docs/project_progress.md`, and `docs/project_decisions.md`.

---

## Phase 4 — Production Web Integration (Blocked on Web Team)
- [ ] **Contract Finalization**:
  - [ ] Receive confirmed JavaScript channel name & response callback from web team.
  - [ ] Receive confirmed action names and payload schemas.
  - [ ] Agree on production file/image transport (Base64 vs Blob vs Multipart Upload).
- [ ] **URL & Identity Finalization**:
  - [ ] Configure real development and production PWA URLs.
  - [ ] Update Android application IDs and package namespaces.
- [ ] **OTP Autofill Integration** (Pending SMS template and web field agreement).
- [ ] **Push Notifications Integration** (Pending backend provider and token registration API).
- [ ] **Offline Synchronization** (Pending Sales Rep offline data schema & ownership decision).

---

## Phase 5 — Production Release & Hardening
- [ ] Production build signing configuration (Keystore / Release Build Types).
- [ ] Launcher icons and branded splash screens for both Stockist and Sales Rep apps.
- [ ] End-to-end regression testing on real device with staging/production PWA.
- [ ] Release APK/AAB generation.

---

## Phase 6 — UX Polish & Assessment (Current)
- [x] **Phase A — Audit and specification**: Audited launch screens, loading indicators, error UI, OTP state, and offline/notification readiness.
- [x] **Phase B — Visual polish and startup reliability**: Remove Flutter branding, remove redundant loading UI, create branded connection error experience.
- [x] **Phase B follow-up — Splash gap**: Android 12+ splash uses a green icon (including night mode), WebView/window stay `#034F2A`, and a green cover hides the WebView until the first successful page finish.
- [x] **Phase B follow-up — Provisional launch lockup**: Centered 69×65 web logo on the green cover. Android 12 circular splash and launcher icon still await UX assets.
- [x] **Phase C — OTP autofill**: Implement safe, limited OTP autofill (fill, do not submit) using native APIs/WebView.
- [x] **Phase D — Offline and notification assessment**: Finalize capability assessment document.
- [x] **Phase E — Final verification**: Static analysis, formatting, tests, and build verification.

---

## Phase 7 — Stockist Retry Target & Session Investigation (2026-10-09)
- [x] **Task A — Retry failed page**: Retry now reloads the failed main-frame HTTPS URL when it is on an approved application host; otherwise it falls back to `AppConfig.webAppUrl`. Retry does not recreate the WebView or clear cookies/localStorage.
- [x] **Task B — Startup route**: Inspected `_loadContent()` / `AppConfig.webAppUrl`. The Next.js source is not in this repository, so the startup URL was **left at `/login`**. No speculative origin or path change.
- [x] **Task C — Cold-start session**: Wrapper does not clear cookies/website data. Startup always loads `webAppUrl` (`…/login`). Session restoration cannot be confirmed without PWA/backend auth source.
- [x] **Task D — Debug WebView inspect**: `AndroidWebViewController.enableDebugging(true)` is enabled only when `kDebugMode` on Android.
- [ ] **Physical-device verification** of retry, back navigation, and session persistence (see checklist in `project_decisions.md`).
