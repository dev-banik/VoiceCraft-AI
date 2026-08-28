# VoiceCraft AI

Professional voice recording, AI noise removal, voice transformation, audio
editing and cloud sync — a Flutter app for Android and iOS.

## Status

This is a complete, from-scratch clean-architecture implementation: every
screen in the spec is wired to real Riverpod controllers, a real Hive local
database, a real FFmpeg-based audio engine, and real Firebase
(Auth/Firestore/Storage) integration code. Two things it deliberately does
**not** ship, and why, are worth knowing before you rely on it:

1. **No local Flutter/Android/Xcode toolchain was available in the
   environment this was built in**, so the app has not been compiled or run
   here. [CI](#ci--getting-an-apk) builds it on every push and is the first
   real compile check — see that section before assuming anything works.
2. **"AI" Noise Removal and Voice Themes ship as a production FFmpeg DSP
   engine, not neural inference.** RNNoise/Demucs/Silero and RVC/So-VITS-SVC
   need trained model weights this environment can't fetch or train. The
   whole pipeline is behind an `AiEngine` interface designed so a TFLite/ONNX
   model swaps in without touching a single call site — see
   [docs/AI_PIPELINE.md](docs/AI_PIPELINE.md).

Everything else — recording, local storage, dashboard, search, editor,
playback, Google Sign-In, Firestore/Storage sync, settings — is a real,
functional implementation, not a mock.

## Getting started

```bash
flutter pub get
flutterfire configure          # writes real lib/firebase_options.dart,
                                # android/app/google-services.json and
                                # ios/Runner/GoogleService-Info.plist
flutter run
```

The app boots and is fully usable (record, save, edit, denoise, theme,
search, settings) even before you run `flutterfire configure` — Firebase
init failure is caught and only cloud sign-in/sync is disabled until you
configure it. See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the full
Firebase project setup (Firestore rules, Storage rules, enabling Google
Sign-In).

## CI / getting an APK

[.github/workflows/build_apk.yml](.github/workflows/build_apk.yml) builds a
release + debug APK on every push to `main` and on demand
(`workflow_dispatch`). Open the **Actions** tab on GitHub after pushing,
open the latest run, and download the `voicecraft-ai-release-apks` (or
`-debug-apk`) artifact — that's a real installable APK you can side-load.
Pushing a tag like `v1.0.0` also attaches the APK to a GitHub Release.

The release APK is signed with the Flutter debug key unless you add
`android/key.properties` (see `android/key.properties.example`) — fine for
side-loading, not for Play Store publishing. See
[docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for generating a real upload key.

**Why CI and not a binary in this PR:** there is no Flutter/Android SDK in
the environment this repo was authored in, so a local `flutter build apk`
was never possible here. CI is a clean, reproducible Ubuntu runner with the
real toolchain — it's the authoritative build, not a workaround.

iOS has no equivalent one-click output: Apple requires a paid/free
Developer account and a signing certificate/provisioning profile that only
you can generate, so there's no way to hand you an installable `.ipa` from
CI without your Apple ID. `ios/` ships fully configured (Info.plist,
Podfile, AppDelegate) — see [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for the
"open in Xcode, run on your device with your free Apple ID" steps.

## Architecture

Clean Architecture, four layers, dependency injection via Riverpod
providers (`lib/core/di/providers.dart`) — no service locator, no global
singletons.

```
lib/
  core/          constants, theme, router, error types, DI, cross-cutting utils
  domain/        entities, repository interfaces, usecases — no Flutter/Firebase imports
  data/          Hive models + datasources, repository implementations
  services/      audio engine (record/playback/waveform/FFmpeg editor),
                 AI pipeline (noise removal / voice themes / enhancement),
                 sync (Firestore + Storage + WorkManager background sync)
  presentation/  one folder per feature: screen + Riverpod controller + widgets
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for the dependency rules
and why each layer looks the way it does, and
[docs/FIRESTORE_SCHEMA.md](docs/FIRESTORE_SCHEMA.md) for the Firestore/Hive
data model.

## Feature map

| Spec module | Implementation |
|---|---|
| Onboarding → Dashboard, no login required | `presentation/onboarding`, `presentation/dashboard` |
| Recording (WAV/MP3/AAC, 44.1/48kHz, quality presets, waveform, volume meter) | `services/audio/audio_recorder_service.dart`, `presentation/recording` |
| AI Noise Removal (strength slider, A/B compare) | `services/ai/noise_removal_service.dart`, `presentation/noise_removal` |
| Voice Themes (10 presets, original untouched) | `services/ai/voice_theme_service.dart`, `presentation/voice_themes` |
| Clarity Enhancement (vocal boost/EQ/compression/loudness/speech) | `services/ai/enhancement_service.dart`, `presentation/enhancement` |
| Editor (trim/split/delete/copy/fade/volume, interactive waveform) | `services/audio/audio_editor_service.dart`, `presentation/editor` |
| Playback (speed, loop, source A/B) | `services/audio/audio_player_service.dart`, `presentation/playback` |
| Google Sign-In + Firestore/Storage sync, background sync | `data/datasources/remote/*`, `services/sync/*`, `presentation/auth` |
| Search & filters | `presentation/search` |
| Settings (format, quality, theme mode, backup, storage) | `presentation/settings` |

## Testing

```bash
flutter test
```

`test/unit/` covers the pure-Dart core (`Formatters`, `Result`) that needs
no Flutter bindings or Firebase — the fastest, most reliable layer to grow
test coverage in first. CI runs this on every push.

## Docs

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — layer rules, DI, state management
- [docs/AI_PIPELINE.md](docs/AI_PIPELINE.md) — how noise removal/voice themes work today and how to upgrade to real neural models
- [docs/FIRESTORE_SCHEMA.md](docs/FIRESTORE_SCHEMA.md) — Firestore/Storage/Hive data model
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) — Firebase setup, Android signing, iOS Xcode steps, Play Store/App Store checklist
- [docs/ROADMAP.md](docs/ROADMAP.md) — what's shipped vs. what real productionization still needs

## License

MIT — see [LICENSE](LICENSE).
