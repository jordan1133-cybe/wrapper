# Sales Rep Wrapper

Android Flutter WebView wrapper for the Dashen Sales Rep PWA.

## Build

Run commands from this directory:

```sh
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Configuration and release

The PWA URL and trusted hosts are configured in `lib/config/app_config.dart`.
Android application ID and namespace are currently `com.dashen.breweries.salesrep`;
confirm the final ID before release. Release builds currently use debug signing;
production signing is not configured.

The wrapper handles trusted-origin geolocation and image selection for the PWA.
