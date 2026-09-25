# Release signing

## Why this exists

Android refuses to upgrade an installed app when the new APK carries a
different signature. Before this was set up, `android/app/build.gradle.kts`
fell back to the **debug** signing config whenever no `key.properties` was
present — and CI runs on a fresh ephemeral runner every time, which generates
a brand-new debug keystore per run.

The result: every CI build was signed with a different random key, so no build
could ever upgrade another. Installing a new one meant uninstalling the old
one first, and because recordings live in app-private internal storage
(`getApplicationDocumentsDirectory()/recordings`), uninstalling wiped them.

With a fixed keystore, every build shares one signature and installs straight
over the last one, recordings intact.

## The keystore

`secrets/voicecraft-release.jks`, alias `voicecraft`, valid ~27 years.

**It is gitignored and must stay that way.** This is a public repo; anyone
holding this key could build an APK that Android would happily install over
yours. Back it up somewhere private — a password manager or an encrypted
drive. If you lose it, no future build can upgrade an install signed with it,
and the only way out is uninstall-and-reinstall again.

`secrets/` also holds `KEYSTORE_BASE64.txt` and `KEYSTORE_PASSWORD.txt`, which
exist purely so the values can be copied into GitHub. Both are gitignored.

## Local builds

`android/key.properties` is already written and points at the keystore by
absolute path. Nothing else to do — `flutter build apk --release` picks it up.

## CI

The workflow reconstructs the keystore from two repository secrets, then
writes `android/key.properties` before building. Add them at
**Settings → Secrets and variables → Actions → New repository secret**:

| Secret name         | Value                                             |
| ------------------- | ------------------------------------------------- |
| `KEYSTORE_BASE64`   | the entire contents of `secrets/KEYSTORE_BASE64.txt` |
| `KEYSTORE_PASSWORD` | the contents of `secrets/KEYSTORE_PASSWORD.txt`   |

Until both are set, the build still succeeds — it falls back to debug signing
and emits a warning in the run log saying the APK can't upgrade an existing
install. That keeps the repo buildable by anyone who clones it without needing
your key.

## The one unavoidable uninstall

The app currently on your phone was signed with an old throwaway key, so it
cannot be upgraded to a properly signed build. You have to uninstall it once,
and that clears its recordings. Every install after this one upgrades cleanly.
