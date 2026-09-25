# Store release readiness

This checklist is for the Egypt-first Android and iOS release. A successful
Flutter build alone does not complete a store submission.

## Repository configuration

- Android application ID: `com.medsuper.med_super`.
- iOS bundle ID: `com.medsuper.medSuper`.
- Flutter version: `1.0.0+1`; increment the build number for every upload.
- Android release signing is configured in `android/app/build.gradle.kts` to
  require the private upload key in the ignored `android/key.properties` file.
  Follow [`ANDROID_RELEASE.md`](ANDROID_RELEASE.md); the upload keystore has not
  been created or supplied here.
- Google Play requires API 36 or higher for new Android app submissions and
  updates starting 2026-08-31. This project pins `targetSdk` to 36; confirm the
  current minimum again before submission. See [Google Play target API
  requirements](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en).
- iOS archive and signing must be produced with Xcode on macOS. This Windows
  workspace cannot create or validate an App Store archive. As of 2026-04-28,
  App Store Connect requires Xcode 26 or later with the iOS 26 SDK. See [Apple's
  SDK minimum requirements](https://developer.apple.com/news/upcoming-requirements/).

## Required before submission

- Publish a privacy policy on an active public HTTPS URL and link it both in
  the app and in each store console. The policy must accurately describe the
  personal and health data collected, processors, retention, and deletion
  request process.
- Implement an in-app account-deletion request and a public web request path.
  Neither a deletion request flow nor a deletion endpoint exists in the current
  app/backend. Google Play requires both paths for apps that let people create
  accounts. Apple's rule also requires an in-app deletion initiation path; for
  highly regulated industries, customer-service review may confirm/facilitate
  deletion. See the official [Apple account deletion guidance](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
  and [Google Play account deletion requirements](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en).
- Resolve the project's `DEC-014` legal question before deciding which health
  records must be retained when an account is deleted. Do not promise hard
  deletion of records the law requires to be kept.
- Complete Google Play's health-app declaration and Data safety disclosures;
  the Play health-app policy also requires a privacy policy in the listing and
  in the app. See [Health apps declaration](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en),
  [Health content and services](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en-GB),
  and [Apple's App Review information](https://developer.apple.com/app-store/review/).
- Prepare store name, description, support contact, age/content answers, app
  icon, phone/tablet screenshots, review notes, and a working reviewer account.
- Confirm production API, SMS/OTP delivery, payment and push provider settings;
  the Flutter production build must use `ENV=production` and a real HTTPS
  `BASE_URL`.

## Verification still required

- Create the Android upload key, then build and install a signed Android App
  Bundle and verify its signature and release API configuration.
- On a Mac, archive and sign iOS, install through TestFlight, and verify push
  notifications, deep links, permissions, and production API connectivity.
- Complete real-device patient booking, pharmacy and lab journeys in Arabic and
  English, with network-loss, authentication, payment, and notification checks.
- Complete the Play internal/closed test and App Store TestFlight review before
  requesting production release.
