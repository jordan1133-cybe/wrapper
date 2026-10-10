# Project Decisions Log: Dashen Mobile App Flutter Wrappers

> **Standard**: Every significant architectural, security, and integration decision is recorded here with context, rationale, alternatives considered, and consequences.

---

## 2026-10-07 — Architecture: Flutter as Native Adapter for Next.js PWA
- **Decision**: The Flutter codebase serves strictly as a native shell/adapter around the Next.js PWA. All business logic, user session management, order workflows, and gamified reward calculations remain inside the PWA.
- **Reason**: The web application is developed by a dedicated web team. Duplicating business rules in Flutter creates dual-maintenance overhead, sync bugs, and architectural drift. Flutter's role is to provide native hardware access (GPS, Camera, Files, Intents, Offline caching support) when requested.
- **Alternatives Considered**: Rebuilding the entire mobile client natively in Flutter. Rejected due to development timeline and requirement to maintain a single core PWA for both web and mobile.
- **Consequences**: Flutter wrapper must be resilient to web loading states and expose a clean, decoupled bridge API.

---

## 2026-10-07 — Bridge: Correlated Request/Response JSON Envelope with Request IDs
- **Decision**: Use a single JavaScript Channel (`DashenBridge`) with a standard JSON envelope:
  - Request: `{"requestId": "uuid", "action": "get_location", "payload": { ... }}`
  - Response: `{"requestId": "uuid", "status": "success"|"error"|"denied"|"cancelled", "payload": { ... }, "error": { "code": "...", "message": "..." }}`
- **Reason**: Native device operations (GPS coordinate lookup, opening the camera, picking files) are asynchronous. Asynchronous requests require an explicit correlation ID (`requestId`) so the PWA knows which promise/callback to resolve when Flutter calls `window.DashenBridge.onResponse()`.
- **Alternatives Considered**: Multiple dedicated JS channels (`LocationChannel`, `CameraChannel`). Rejected because managing multiple channels increases boilerplate, complicates message ordering, and is harder to secure and log consistently.
- **Consequences**: Both Flutter and the PWA web client only need to maintain a single bridge router.

---

## 2026-10-07 — Separation of Concerns: Service Layer Isolated from BridgeHandler
- **Decision**: Keep native services (`LocationService`, `CameraService`, `FilePickerService`, `OtpService`) completely decoupled from `BridgeHandler` and `WebViewController`.
- **Reason**: Native services should be purely responsible for platform-specific hardware/API interactions, permissions, and timeout handling. They can be unit tested without initializing a WebView or mocking JavaScript channels.
- **Consequences**: `BridgeHandler` acts strictly as an adapter/router, translating bridge requests into service calls and mapping service results or `NativeOperationException` errors into `BridgeResponse` envelopes.

---

## 2026-10-08 — Development File Transport: Base64 as Verified Dev Transport
- **Decision**: Use Base64 encoding as the **provisional development transport** for camera captures and file picking in the bridge test harness.
- **Reason**: Enabled immediate end-to-end verification of camera and file picking on real hardware without waiting for backend cloud storage / S3 upload endpoints.
- **Constraint**: Marked strictly as `PROVISIONAL / TODO(CONTRACT)`. The web team must confirm whether production will use base64, Blob URLs, or direct multipart upload from Flutter.

---

## 2026-10-08 — Offline Architecture: No Speculative Offline Implementation
- **Decision**: Do not build a speculative offline database or synchronization queue in Flutter prior to contract confirmation.
- **Reason**: Sales Representative offline workflows (SR-03, SR-04, SR-05) involve complex database schemas, state management, conflict resolution, and synchronization ownership. Guessing whether Flutter or the PWA owns offline sync risks building redundant or incompatible storage engines.
- **Consequences**: Flutter provides connectivity monitoring hooks; full offline synchronization will be implemented once the web team defines the data contract.

---

## 2026-10-08 — Testing: Minimal Development-Only Bridge Test Harness
- **Decision**: Implement a lightweight, self-contained `test_harness.html` asset loaded via `AppConfig.useTestHarness` to validate the native bridge.
- **Reason**: Allows verifying the entire `JS -> postMessage -> BridgeHandler -> Native Service -> Android API -> onResponse -> JS` cycle on real physical Android devices before the production PWA URL is available.
- **Consequences**: Complete verification of camera, fine GPS, file picker, and error handling achieved on device without relying on external servers.

---

## 2026-10-08 — Security: Host Allowlisting & External Navigation Protection
- **Decision**: `NavigationHandler` restricts WebView navigation strictly to trusted PWA hosts (`AppConfig.trustedHosts`) and routes all external links, system intents (`tel:`, `mailto:`, `sms:`, `geo:`), and map URLs to the Android system's default applications.
- **Reason**: Prevents third-party external web pages from loading inside the privileged WebView where they could attempt to call `DashenBridge.postMessage()`.

---

## 2026-10-09 — Architecture: Web-First Hardware Strategy
- **Decision**: The PWA web team will attempt to handle hardware integration (Camera, Location, Files) natively on the web side using HTML5 Browser APIs (`<input type="file" capture="camera">`, Geolocation API) *before* relying on the Flutter native bridge. The Flutter bridge we built remains intact as a **fallback/escalation mechanism**.
- **Reason**: Using standard web APIs reduces coupling between the Next.js app and the Flutter wrapper, potentially simplifying the codebase for the web team.
- **Consequences**: We are now acting as a standard wrapper for the Stockist PWA development URL (`https://dashensalestracking.wearecerta.app/login`). The native services (`LocationService`, `CameraService`, `FilePickerService`) will sit idle unless the web team explicitly invokes them via `DashenBridge.postMessage()`. We do not remove them so they are ready if the web implementation faces Android WebView limitations.

---

## 2026-10-09 — UX Polish: Startup Screen Alignment
- **Decision**: Align the native Android splash screen (`launch_background.xml`) to the exact `#034F2A` green used by the Next.js PWA splash screen, and remove Flutter's `LinearProgressIndicator`.
- **Reason**: The Next.js app renders its own branded loading UI almost immediately. Having a competing native progress indicator or a white native splash screen creates a disjointed, unpolished experience. 
- **Consequences**: Seamless transition from Android launch to PWA render.

---

## 2026-10-09 — UX: Hide Android 12 Flutter splash icon and hold green until PWA paint
- **Decision**: On API 31+, set `windowSplashScreenAnimatedIcon` to a brand-green vector (not a 1dp transparent asset) and duplicate that theme in `values-night-v31`. Keep a Flutter green cover over the WebView until the first successful main-frame `onPageFinished`. Disable `forceDarkAllowed` on launch/normal themes. Do not change `AndroidManifest` activity structure for this; the launcher theme is already `LaunchTheme`.
- **Reason**: Night-mode resource precedence beats `values-v31`, so dark-mode Android 12+ was still using the Flutter launcher icon as the system splash. A 1dp transparent splash icon also falls back to that launcher icon. After the system splash dismisses, the WebView surface is typically black until the PWA login HTML paints.
- **Consequences**: Cold start should stay Dashen green from process start until the PWA login UI is on screen. The home-screen launcher icon can still be the default Flutter asset until branded mipmaps are supplied in Phase 5.

---

## 2026-10-10 — UX: Provisional web lockup on native launch cover; Android 12 icon stays mark-free
- **Decision**: Show the current web `DASHEN` lockup (`assets/branding/dashen_logo.png`, 69×65) centered on the Flutter green cover. Do **not** use that file as the Android 12 circular splash icon or the launcher icon.
- **Reason**: The long wait after process start is the Flutter cover, not the PWA splash (the WebView stays hidden until `onPageFinished` to avoid a black surface). A 69×65 PNG cannot survive 4× upscale. Android 12 crops splash icons to a circle and will clip the wordmark.
- **Consequences**: Launch shows a small/soft lockup until UX delivers a symbol-only splash/app icon plus a high-res or SVG full-screen lockup.

---

## 2026-10-10 — Branding: Asset request for splash symbol, launch lockup, and adaptive app icon
- **Decision**: Ask UX for three separate assets rather than reusing the 69×65 web PNG. Background for all three is `#034F2A`.
  1. **Symbol only** (no “DASHEN” text): Android 12 splash + adaptive launcher foreground. Master SVG plus PNG 1152×1152. Artwork inside the center 66% (safe zone); no baked circle or padding that assumes a circle.
  2. **Full lockup** (mark + wordmark): native launch cover. SVG preferred, or PNG at least 800px on the long edge, transparency OK.
  3. **Play Store / adaptive layers**: foreground 1024×1024 (or SVG), background 1024×1024 solid `#034F2A` or pattern, Play listing 512×512 PNG, no rounded corners baked in. Optional Android 13 monochrome 1024×1024.
- **Reason**: Circular OS masks crop wordmarks; 48dp launcher size cannot render “DASHEN”; 69×65 cannot be upscaled for xxxhdpi.

---

## 2026-10-09 — Security: OTP Autofill via SmsUserConsent
- **Decision**: Implemented OTP autofill using Android's native `SmsRetriever.startSmsUserConsent()` instead of third-party packages or `READ_SMS` permissions. The OTP is injected into the WebView via JS but *never* automatically submitted.
- **Reason**: `sms_autofill` package was unreliable and forced SDK changes. `SmsUserConsent` requires zero SMS permissions (preserves user privacy) and delegates the consent UI to Android Play Services.
- **Consequences**: Highly secure, zero-dependency, permissionless OTP flow.

---

## 2026-10-09 — WebView: Retry the failed trusted page, not `/login`
- **Decision**: On a main-frame `WebResourceError`, record `error.url` when it is HTTPS and its host is in `AppConfig.retryableApplicationHosts`. Retry loads that URL. If the failed URL is missing or untrusted, Retry falls back to the configured `webAppUrl`. A successful main-frame finish clears the recorded failed URL. Loopback and non-HTTPS URLs are not retried.
- **Reason**: Retry previously called `_loadContent()`, which always navigates to `https://dashensalestracking.wearecerta.app/login`, sending the user off the page that actually failed.
- **Limitation**: `WebResourceError.url` is optional. When it is absent, the wrapper may use the last *validated* trusted main-frame `onPageStarted` URL; it still will not retry an untrusted URL. Arbitrary last-visited URLs are not persisted to disk.
- **Consequences**: Repeated Retry taps call `loadRequest` on the same WebView controller and do not clear cookies, localStorage, or WebView storage.

---

## 2026-10-09 — Startup URL left at `/login` until the PWA source is available
- **Decision**: Do **not** change `AppConfig.devUrl` / `webAppUrl` from `https://dashensalestracking.wearecerta.app/login` to `/`, `/stockists`, or another guessed route. Do not switch `webAppUrl` to `prodUrl`.
- **Reason**: This repository does not contain the Next.js app. The documented Stockist entry URL is `/login`. Without middleware, `app/page.tsx` (or `pages/index`), auth guards, and token storage, a different path cannot be justified. `prodUrl` remains blocked on the previously reported TLS hostname mismatch and was not reverified here.
- **Web files needed**: Next.js `middleware.ts` / `middleware.js`, the root page (`app/page.tsx` or `pages/index.*`), login/OTP route files, auth session provider (cookies vs `localStorage` vs HTTP-only cookies), and any `next.config` redirects.
- **Consequences**: Every cold start still asks the WebView to load `/login`. If the PWA then shows OTP again, that may be PWA routing, missing session cookies, or token expiry — not something this wrapper can safely "fix" by guessing a dashboard path.

---

## 2026-10-09 — Session persistence: wrapper findings vs unknown PWA behavior
- **Verified in this repo**: No wrapper code calls `CookieManager`, `clearCache`, `clearLocalStorage`, or equivalent website-data APIs. `WebViewController` is created once in `WebViewScreen.initState` and is not recreated on Retry. Default (non-incognito) Android WebView storage is used. HTTP 401/403 are not treated as connection errors (`onHttpError` is unused).
- **Hypothesis (not proven)**: Showing OTP after force-stop is consistent with startup always loading `/login`. The PWA may render the login route before restoring a session, or it may not persist credentials in WebView-accessible storage. This is not proven without the web app and a cookie/localStorage inspection.
- **Not done**: No native auth, no last-URL persistence, no token/header changes, no OTP autofill changes.

---

## 2026-10-09 — Debug-only Android WebView inspection
- **Decision**: Call `AndroidWebViewController.enableDebugging(true)` from `main()` only when `kDebugMode && Platform.isAndroid`. `webview_flutter_android` is already the Android implementation of `webview_flutter` 4.14.1; it was added as a direct dependency so the import is explicit.
- **Reason**: chrome://inspect is needed to inspect whether the PWA stores session in cookies vs localStorage after OTP login. Release builds keep debugging off.

### Physical-device tests still required
These were **not** run in this environment (no device attached as part of this change):
1. Cold start while online.
2. Cold start while offline.
3. Successful login, force-stop, restart.
4. Main-frame network failure, then Retry (must not jump to `/login` if another trusted path failed).
5. Connectivity restored without manually going to OTP (PWA-dependent).
6. Retry on an approved internal URL.
7. Untrusted retry URL rejected (falls back to configured entry URL).
8. Internal navigation and Android back still work.

---

## 2026-10-09 — Architecture: Push Notifications Deferred
- **Decision**: Do not implement a push notification service (Firebase Cloud Messaging, Web Push, etc.) in the Flutter wrapper at this time.
- **Reason**: Push notifications require a backend contract (device token registration) and a provider decision from the PM/Web team. Speculatively adding Firebase would bloat the app and risk misalignment with the backend.
- **Consequences**: Notification capability boundary is defined and stubbed in `NotificationService` but remains inactive until the contract is provided.
