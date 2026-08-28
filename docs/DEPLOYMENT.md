# Deployment guide

## 1. Firebase project setup

1. Create a project at https://console.firebase.google.com.
2. Enable **Authentication → Sign-in method → Google**.
3. Enable **Firestore Database** (production mode) and **Storage**.
4. From the repo root:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-project-id>
   ```
   This overwrites `lib/firebase_options.dart`,
   `android/app/google-services.json` and
   `ios/Runner/GoogleService-Info.plist` with real values (all three ship
   as placeholders in this repo so the app compiles before you do this).
5. Deploy the security rules:
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase deploy --only firestore:rules,storage:rules --project <your-project-id>
   ```
   (`firebase.json` already points at `firebase/firestore.rules` and
   `firebase/storage.rules` in this repo.)
6. iOS only: after `flutterfire configure`, open
   `ios/Runner/GoogleService-Info.plist`, copy the `REVERSED_CLIENT_ID`
   value, and paste it into the `CFBundleURLSchemes` entry in
   `ios/Runner/Info.plist` (replacing the `REPLACE_WITH_REVERSED_CLIENT_ID`
   placeholder) — required for Google Sign-In to return to the app.

## 2. Android — release signing (for Play Store)

The CI workflow and a plain `flutter build apk` both work out of the box
using the Flutter debug key — fine for side-loading, not for Play Store.

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
cp android/key.properties.example android/key.properties
# edit android/key.properties with the keystore path + passwords above
flutter build appbundle --release   # for Play Store
flutter build apk --release         # for direct distribution
```

`android/key.properties` is gitignored — never commit it or the `.jks`
file. If you want CI to produce a Play-Store-signed build, add the
keystore (base64-encoded) and its passwords as GitHub Actions secrets and
extend `.github/workflows/build_apk.yml` to reconstruct
`android/key.properties` from them before the build step.

## 3. Android — Play Store checklist

- [ ] Replace the default Flutter launcher icon (`android/app/src/main/res/mipmap-*`) — consider the `flutter_launcher_icons` package.
- [ ] Set a real `applicationId` if you don't want `com.voicecraft.ai` (must also match Firebase's registered Android app).
- [ ] Bump `version` in `pubspec.yaml` (`versionName+versionCode`) per release.
- [ ] Fill in a real Privacy Policy URL (the in-app dialog in Settings has placeholder text — required by Play Console before publishing, especially given microphone + account data usage).
- [ ] Complete Play Console's Data Safety form (microphone audio, account email — see what's actually collected in [docs/FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md)).
- [ ] Target API level / `compileSdk`/`targetSdk` in `android/app/build.gradle` must stay current with Play's requirements at submission time.

## 4. iOS — running on a device

No CI shortcut here: Apple requires you to sign the build with your own
Apple ID (even a free account works for local device installs, renews
every 7 days).

```bash
flutter create --platforms=ios .   # only if ios/Runner.xcodeproj is missing —
                                    # this repo ships the files that need real
                                    # customization (Info.plist, Podfile,
                                    # AppDelegate.swift) but not the generated
                                    # Xcode project itself; this command fills
                                    # in exactly that missing boilerplate
                                    # without touching what's already there
cd ios && pod install && cd ..
open ios/Runner.xcworkspace
```

In Xcode: select your team under **Signing & Capabilities**, plug in a
device, hit Run. For TestFlight/App Store distribution you need a paid
Apple Developer Program membership, an App Store Connect record, and
`flutter build ipa` with a distribution certificate — see Apple's and
Flutter's own docs for that flow; it's outside what any CI script can do
for you without your credentials.

## 5. CI

`.github/workflows/build_apk.yml` runs on every push/PR to `main` and on
`workflow_dispatch`:

1. Sets up JDK 17 + Flutter stable.
2. Runs `flutter create --platforms=android,ios .` to fill in the Gradle
   wrapper and Xcode project boilerplate this repo intentionally doesn't
   commit (see the comment in the workflow file for why).
3. `flutter pub get`, `flutter analyze` (non-blocking), `flutter test`.
4. `flutter build apk --release --split-per-abi` and
   `flutter build apk --debug`, uploaded as workflow artifacts.
5. On a `v*` tag push, attaches the release APKs to a GitHub Release.

To get a signed release build out of CI, add your keystore as a secret and
extend the workflow to write `android/key.properties` before the build
step (see section 2).
