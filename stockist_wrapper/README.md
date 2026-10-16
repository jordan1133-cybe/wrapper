# Stockist Wrapper

Flutter Android WebView wrapper for the Dashen Stockist PWA.

## Build

Run commands from this directory:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

The current Gradle configuration requires local `android/key.properties` values
even for a debug build. That ignored file is not included in this repository.

## Configuration and release

The PWA URL and trusted hosts are configured in `lib/config/app_config.dart`.
Android application ID and namespace are currently
`com.dashen.breweries.salesincentive`; confirm the final ID and configure the
release signing key before release.

Firebase initialization and push messaging are present but remain in progress.
The checked-in Firebase configuration targets a temporary development project;
decide whether it should be included before delivering this app to its own
repository.
