# Android release signing

Release builds must use the app's private upload key. The debug key must never
be used for a store build.

## Configure the upload key

Create a long-lived upload keystore and keep a secure backup outside this
repository. Do not regenerate it between releases. Android Studio's signing
wizard or the JDK `keytool` can create the keystore. Add its details to
`android/key.properties` (this file is ignored by Git):

```properties
storePassword=<keystore password>
keyPassword=<key password>
keyAlias=<key alias>
storeFile=<path to keystore, relative to android/>
```

Keep the passwords and keystore in a password manager or the CI secret store.
Never commit `key.properties`, `.jks`, or `.keystore` files.

## Build store artifacts

Google Play requires new apps and app updates to target API level 36 or higher
starting 2026-08-31. This project pins `targetSdk` to 36 in
`android/app/build.gradle.kts`; recheck the Play Console requirement before each
submission in case Google raises the minimum.

From the Flutter project root, with the signing file in place:

```powershell
flutter build appbundle --release -t lib/main.dart --dart-define=ENV=production --dart-define=BASE_URL=https://<production-api-host>
```

Release app startup also rejects the mock API, non-HTTPS API URLs, and `ENV=dev`.
Use `ENV=staging` for an HTTPS staging backend on a private testing track. The
Android Gradle configuration fails release tasks when any signing value is
missing. Debug builds continue to use the normal debug signing configuration.
The resulting Play Store bundle is under `build/app/outputs/bundle/release/`.

Before a store upload, confirm the Play Console application ID matches
`com.medsuper.med_super`, and keep the upload key backed up independently from
the Play App Signing key managed by Google Play.
