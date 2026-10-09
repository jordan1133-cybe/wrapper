# Project Plan: Dashen Breweries Sales Tracking & Incentive Platform (Flutter Wrappers)

> **Document Type**: Living Architecture & Product Specification  
> **Status**: Active (Phase 3 Hardening)  
> **Target Audience**: Mobile Engineering Team, Tech Mentors, PM, Web/Backend Teams  
> **Last Updated**: October 2026

---

## 1. Project Overview & Context

### 1.1 What Is Being Built?
We are building two production-grade Android native wrapper applications using Flutter:
1. **Dashen Stockist Wrapper** (`stockist_wrapper`)
2. **Dashen Sales Representative (SR) Wrapper** (`sales_rep_wrapper`)

These applications wrap localized Next.js Progressive Web Applications (PWAs) inside high-performance native WebViews and expose essential device-level hardware capabilities via a bidirectional JavaScript ↔ Flutter bridge.

### 1.2 Why Does It Exist?
While the core business logic, order placing, gamified dashboards, and user sessions are owned by the PWA, pure mobile browsers lack accurate native GPS accuracy, direct hardware camera integration for document compliance, seamless file picking, and native offline resilience in remote regions of Ethiopia. The Flutter wrapper acts as a **native hardware adapter** for the PWA.

### 1.3 Users & Roles
- **Stockists (Retailers / Bar Owners)**: Authenticate via phone SMS OTP, view order history, track incentive campaigns (e.g. Bajaj/Fridge giveaways), check trophy cabinet, and place orders.
- **Sales Representatives (Field Force)**: Travel to remote storefronts, register new Stockists with geolocation and compliance photos (TIN/Trade License), record on-the-spot direct sales, verify market share, and fulfill pending pre-orders.

---

## 2. Architecture & System Boundaries

### 2.1 The Fundamental Architecture
```text
┌──────────────────────────────────────────────────────────────┐
│                  DASHEN PWA / WEB APP (Next.js)              │
│  - Authentication & Session State                            │
│  - Business Logic & Catalog / Order Flow                     │
│  - Gamification Engine & Reports                             │
└──────────────────────────────┬───────────────────────────────┘
                               │ JSON via postMessage()
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                    JAVASCRIPT BRIDGE                         │
│  - Channel: "DashenBridge"                                   │
│  - Callback: "window.DashenBridge.onResponse"                │
└──────────────────────────────┬───────────────────────────────┘
                               │ Correlated Requests (requestId)
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                 FLUTTER NATIVE WRAPPER                       │
│  - WebViewController & NavigationHandler                     │
│  - BridgeHandler (Parsing, Validation, Routing)              │
│  - Native Services (GPS, Camera, FilePicker, Phone, etc.)    │
└──────────────────────────────┬───────────────────────────────┘
                               │ Android System APIs / Intents
                               ▼
┌──────────────────────────────────────────────────────────────┐
│                    DEVICE HARDWARE / OS                      │
│  - GPS Sensors / Fused Location Provider                     │
│  - Camera Hardware & System File Picker                      │
│  - Default Dialer / Maps Application / Connectivity State    │
└──────────────────────────────────────────────────────────────┘
```

### 2.2 Strict Separation of Concerns
- **PWA Owns**: Business logic, UI layout, user authentication, session persistence, OTP verification flow, catalog, rewards calculations.
- **Flutter Wrapper Owns**: Hosting the WebView, intercepting external navigation, requesting Android runtime permissions, executing native hardware actions, routing bridge messages, and providing connectivity diagnostics.
- **Do NOT**: Duplicate PWA business logic or database state in Flutter without confirmed requirements.

---

## 3. Native Features & Technical Specifications

> **Architecture Shift (2026-10-09)**: The web team has clarified that the PWA will attempt to handle hardware features (Camera, Location, Files) using standard HTML5 Browser APIs natively inside the WebView first. The Flutter Bridge documented here acts as a **fallback and escalation mechanism** if those browser APIs prove insufficient on certain Android devices. The native capabilities remain fully wired but will only be invoked if the PWA explicitly sends a bridge message.

| Feature | Requirement Source | Implementation Mechanism | Status |
| :--- | :--- | :--- | :--- |
| **WebView Core** | PRD §2 | `webview_flutter` with unrestricted JS and custom NavigationDelegate | **CONFIRMED & TESTED** |
| **JS ↔ Native Bridge** | PRD §2, PM Q4 | `JavaScriptChannel('DashenBridge')` + JSON Envelope + Request IDs | **CONFIRMED & TESTED** |
| **GPS / Location** | PRD §4.1, PM Q3/Q8 | `geolocator` (Fine & Coarse foreground GPS) | **CONFIRMED (Fallback)** |
| **Camera Capture** | PRD §4.1 (SR-01), PM Q3 | `image_picker` (Camera intent with quality optimization) | **CONFIRMED (Fallback)** |
| **File / Photo Selection**| PRD §4.1, PM Q3 | `file_picker` (System document & media picker) | **CONFIRMED (Fallback)** |
| **Phone Calls** | PRD §4.1, PM Q3 | `url_launcher` via `tel:` URI scheme intent | **CONFIRMED** |
| **Maps & External URLs**| PRD §4.1, PM Q3 | `url_launcher` + `NavigationHandler` allowlist | **CONFIRMED** |
| **Camera/File Transport**| PRD §4.1 | Development: base64 payload. Production: Pending contract | **PROVISIONAL** |
| **OTP Autofill** | PM Q6 | Best-effort SMS listener hook (Bridge stubbed) | **OPEN QUESTION / BLOCKED** |
| **Push Notifications** | PM Q3 | Native boundary stubbed (Awaiting backend push provider) | **OPEN QUESTION / BLOCKED** |
| **Offline Data Sync (SR)**| PM Q5, Q8 | Diagnostic connectivity monitoring (Awaiting data sync contract)| **OPEN QUESTION / BLOCKED** |

---

## 4. Contract Status Matrix

### 4.1 Confirmed Items (FACTS)
- Stockist and Sales Rep exist as distinct applications.
- WebView unrestricted JavaScript execution is enabled.
- Runtime permissions (`ACCESS_FINE_LOCATION`, `CAMERA`, `INTERNET`) are correctly declared in `AndroidManifest.xml`.
- Bridge architecture using correlated JSON envelopes (`requestId`, `action`, `payload`, `status`, `error`) verified on physical Android hardware.
- The Stockist development PWA URL is confirmed (`https://dashensalestracking.wearecerta.app/login`).

### 4.2 Provisional Decisions (TODO: CONTRACT)
1. **Bridge Channel Name**: `DashenBridge`
2. **Bridge Response Callback**: `window.DashenBridge.onResponse`
3. **Action Identifiers**: `get_location`, `open_camera`, `pick_file`, `start_otp_listener`
4. **File Transport (Dev)**: base64-encoded strings with MIME type and file name.
5. **Location Output**: `{ latitude, longitude, accuracy }`

### 4.3 Open Questions & Blockers (Awaiting External Confirmation)
1. **Production URLs**: Prod URL for Stockist, and Dev/Prod URLs for Sales Rep PWAs.
2. **Application IDs**: Production Android package names (replacing `com.example.*`).
3. **File Upload Contract**: Whether PWA expects base64 in JS, Blob/File, or direct multipart upload to backend S3/storage if they fall back to the bridge.
4. **Offline Business Logic**: Data schema for offline sales entry (SR-03/SR-05), local storage ownership (PWA IndexedDB vs Flutter SQLite), and sync/conflict resolution rules.
5. **Push Notifications**: Infrastructure decision (Firebase Cloud Messaging vs Web Push vs Custom).
6. **OTP Message Format**: SMS template and hash signature for Android SMS Retriever API.

---

## 5. Security & Non-Functional Requirements

1. **Host Allowlisting & Navigation Isolation**:
   - Internal URLs (belonging to the configured PWA host or localhost in dev) are loaded within the WebView.
   - External HTTP/HTTPS links are automatically routed to the default system browser to prevent external scripts from gaining access to `window.DashenBridge`.
   - Hardware intents (`tel:`, `mailto:`, `sms:`, `geo:`) are dispatched to native apps.
2. **Safe Diagnostics & Privacy**:
   - Base64 payload data, passwords, OTP tokens, and user credentials must never be printed to application logs.
   - Debug logs summarize payloads safely.
3. **Error Resilience**:
   - All native failures produce structured errors with standard codes (`PERMISSION_DENIED`, `OPERATION_CANCELLED`, `TIMEOUT`, `INVALID_ARGUMENT`, etc.) so the PWA can display localized user feedback.
