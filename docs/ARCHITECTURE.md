# Architecture

## Layers and the dependency rule

```
presentation  ->  domain  <-  data
      \                        /
       \------ services ------/
```

- **`domain/`** has zero Flutter, Firebase, Hive or FFmpeg imports. It's
  entities (`RecordingEntity`, `UserEntity`, `EnhancementSettings`),
  repository *interfaces* (`RecordingRepository`, `AuthRepository`,
  `SyncRepository`), and usecases that are thin orchestration over those
  interfaces. This layer defines the contract everything else honors —
  nothing in it knows Hive or Firebase exist.
- **`data/`** implements those interfaces. `models/` are the Hive-persisted
  shapes (`RecordingModel`, `AppSettingsModel`) with `toEntity()`/
  `fromEntity()` mapping at the boundary — the rest of the app never sees a
  `HiveObject`. `datasources/` wrap Hive boxes and Firebase SDKs directly;
  `repositories/` compose datasources and translate `Exception`s into
  `Failure`s.
- **`services/`** is the audio/AI engine: recording, playback, waveform
  extraction, the FFmpeg-based editor, and the noise-removal/voice-theme/
  enhancement pipeline. These are plain Dart classes with no dependency on
  `domain/` — they operate on file paths in, file paths out, which is why
  they're reusable from both controllers and (for background sync) a
  separate WorkManager isolate.
- **`presentation/`** is one folder per feature (`recording/`, `playback/`,
  `noise_removal/`, ...), each with a `screen`, a Riverpod
  `StateNotifierController` (or plain `Provider`-based controller for
  simpler cases), and feature-local `widgets/`. Screens never call
  `services/` or `data/` directly — always through a controller, which goes
  through a usecase or service provider from `core/di/providers.dart`.

## Dependency injection

Everything is wired through Riverpod providers in
`lib/core/di/providers.dart` — datasources → repositories → usecases →
services, all as `Provider`s that `ref.watch`/`ref.read` compose. There is
no `GetIt`/service-locator and no global singleton state; swapping an
implementation (e.g. the `AiEngine` behind noise removal, see
[AI_PIPELINE.md](AI_PIPELINE.md)) means changing one provider binding.

## State management

- Simple derived/async state (recordings list, current recording, search
  results) is `StreamProvider`/`FutureProvider` reading straight from a
  usecase.
- Screens with multi-step user interaction and mutable local state
  (recording in progress, editor selection, noise-removal strength +
  processing status) use `StateNotifierProvider` with an immutable state
  class and a `copyWith`.
- `core/utils/result.dart` provides a minimal `Result<T>` (`Ok`/`Err`) used
  at the repository/usecase boundary instead of throwing, so controllers
  handle failures explicitly via `.when(ok: ..., err: ...)` rather than
  try/catching platform exceptions everywhere.

## Local persistence

Hive, not Isar — two boxes (`recordings_box`, `settings_box`), see
`data/datasources/local/hive_boxes.dart`. Both `.g.dart` adapter files
(`recording_model.g.dart`, `app_settings_model.g.dart`) are **hand-written**,
matching exactly what `hive_generator`/`build_runner` would produce. This
is deliberate, not a placeholder: `hive_generator` and `riverpod_generator`
(originally both dev dependencies here) turned out to have an unresolvable
transitive `analyzer`/`macros` conflict on current Flutter/Dart SDKs, and
since nothing in this codebase actually uses `@riverpod`/`@freezed`
code-gen annotations — every provider and adapter is written by hand — the
whole code-gen toolchain (`build_runner`, `hive_generator`, `freezed`,
`json_serializable`, `riverpod_generator` and their `_annotation` packages)
was dropped from `pubspec.yaml` rather than fought with. If you add a new
Hive model field, update the model, its adapter, and its `typeId`/
`HiveField` indices by hand together — or re-add `hive_generator` +
`build_runner` as dev dependencies yourself and run
`flutter pub run build_runner build --delete-conflicting-outputs` to
generate an equivalent file.

## Non-destructive editing model

- **Voice Themes**: never touches the source file. `VoiceThemeService`
  always reads the original and writes a new derived file; the recording's
  `themeVariants` map accumulates paths per theme.
- **Noise Removal / Clarity Enhancement**: also non-destructive on disk (new
  file written), but conceptually "replace" the recording's primary
  denoised/enhanced representation — `RecordingEntity.denoisedPath` /
  `.enhancedPath` point at the latest derived file, and Playback exposes
  Original/Denoised/Enhanced/per-theme as explicit source choices.
- **Editor** (trim/delete/fade/volume): also writes new files, then the
  recording's `localPath`/`duration`/`sizeBytes` are updated to point at the
  edited result — this is the one operation that's conceptually "in place"
  editing, matching how a voice-memo editor behaves. **Split** and **Copy
  segment** instead create brand-new `RecordingEntity` rows, since the spec
  calls for those to "save separately."
