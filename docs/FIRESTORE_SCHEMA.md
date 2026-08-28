# Data model

## Hive (local, source of truth for the device)

### `recordings_box` — `RecordingModel` (key = recording id)

| Field | Type | Notes |
|---|---|---|
| `id` | String | UUID v4 |
| `title` | String | user-editable |
| `localPath` | String | path to the *current* primary audio file (original, or edited-in-place result — see [ARCHITECTURE.md](ARCHITECTURE.md#non-destructive-editing-model)) |
| `durationMs` | int | |
| `sizeBytes` | int | of `localPath` |
| `createdAt` | DateTime | |
| `format` | String | `RecordingFormat.name` — `wav`/`mp3`/`aac` |
| `sampleRate` | int | 44100 or 48000 |
| `quality` | String | `RecordingQuality.name` — `standard`/`high`/`studio` |
| `denoisedPath` | String? | latest noise-removal output |
| `enhancedPath` | String? | latest clarity-enhancement output |
| `themeVariants` | Map\<String,String\> | `VoiceTheme.name` → file path, one entry per generated theme |
| `synced` | bool | true once uploaded |
| `cloudUrl` | String? | Storage download URL, set after sync |
| `tags` | List\<String\> | reserved for future manual tagging |

### `settings_box` — single `AppSettingsModel` record (key `'settings'`)

Recording format/sample rate/quality defaults, theme mode, default voice
theme, backup toggles, language — see `data/models/app_settings_model.dart`.

## Cloud (only for signed-in users who opt into backup)

### Firestore

```
users/{uid}                          — profile doc: { uid }
users/{uid}/recordings/{recordingId} — RecordingModel.toFirestore():
  id, title, durationMs, sizeBytes, createdAt (ISO 8601), format,
  sampleRate, quality, cloudUrl, tags
```

Deliberately **not** synced to Firestore: `localPath`, `denoisedPath`,
`enhancedPath`, `themeVariants` — these point at on-device file paths that
are meaningless on another device. Only the original audio (via `cloudUrl`)
and its metadata sync; a device that pulls this recording down gets the
original take and can re-run noise removal/themes/enhancement locally.

Rules: [`firebase/firestore.rules`](../firebase/firestore.rules) — a user
can only read/write their own `users/{uid}` subtree; everything else is
denied by default.

### Firebase Storage

```
users/{uid}/recordings/{recordingId}.<ext>
```

One audio file per recording, uploaded from `localPath` on sync. Rules
([`firebase/storage.rules`](../firebase/storage.rules)) scope read/write to
the owning uid and cap uploads at 500MB per file.

## Sync algorithm

See the class doc on `SyncRepositoryImpl` in
`lib/data/repositories/sync_repository_impl.dart` — last-write-wins on
`createdAt` (recordings are immutable takes, not co-edited documents),
`synced` flag as the single source of truth for "needs upload", remote
metadata pulled down immediately with audio fetched lazily the first time
any screen opens that recording (see `recordingByIdProvider` in
`lib/presentation/playback/controller/playback_controller.dart`) rather
than eagerly for every device.
