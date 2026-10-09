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

## 2026-10-09 — Security: OTP Autofill via SmsUserConsent
- **Decision**: Implemented OTP autofill using Android's native `SmsRetriever.startSmsUserConsent()` instead of third-party packages or `READ_SMS` permissions. The OTP is injected into the WebView via JS but *never* automatically submitted.
- **Reason**: `sms_autofill` package was unreliable and forced SDK changes. `SmsUserConsent` requires zero SMS permissions (preserves user privacy) and delegates the consent UI to Android Play Services.
- **Consequences**: Highly secure, zero-dependency, permissionless OTP flow.

---

## 2026-10-09 — Architecture: Push Notifications Deferred
- **Decision**: Do not implement a push notification service (Firebase Cloud Messaging, Web Push, etc.) in the Flutter wrapper at this time.
- **Reason**: Push notifications require a backend contract (device token registration) and a provider decision from the PM/Web team. Speculatively adding Firebase would bloat the app and risk misalignment with the backend.
- **Consequences**: Notification capability boundary is defined and stubbed in `NotificationService` but remains inactive until the contract is provided.
