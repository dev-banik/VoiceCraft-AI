import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../core/utils/file_utils.dart';
import '../../domain/entities/recording_entity.dart';
import '../playback/controller/playback_controller.dart';

/// What the user chose when saving a processed take.
enum DerivativeSaveMode {
  /// The processed audio becomes the recording's audio. The take it had
  /// before is preserved as a [RecordingKind.archivedOriginal] so nothing
  /// is actually destroyed.
  replace,

  /// The processed audio is stored as its own [RecordingKind.modified]
  /// recording and the source is left exactly as it was.
  saveAsNew,
}

/// Stamps the derivative path onto whichever field the tool owns —
/// `denoisedPath` for noise removal, `themeVariants[theme]` for a voice
/// theme, and so on — so the playback screen's Versions row and the library
/// badges keep working whichever save mode was used.
typedef DerivativeMarker = RecordingEntity Function(
  RecordingEntity recording,
  String path,
);

/// Applies [patch] to the freshest stored copy of the recording [id] and
/// persists the result.
///
/// Every screen that changes a recording goes through here, for two reasons:
///
///  * the patch is applied to what is in storage *now*, not to the entity the
///    screen happened to be built with. Screens hold onto a recording for as
///    long as they are open, so patching that copy would silently roll back
///    any derivative saved from another screen in the meantime.
///  * [recordingByIdProvider] is invalidated afterwards. It has no
///    `autoDispose`, so without this every screen keeps rendering the entity
///    from the very first read — which is how a saved noise-removed version
///    could show up on the dashboard (backed by a live Hive stream) while the
///    playback screen still offered nothing but the original.
///
/// Returns the persisted entity, or `null` if the recording is gone or the
/// write failed.
Future<RecordingEntity?> saveRecordingPatch(
  Ref ref,
  String id,
  RecordingEntity Function(RecordingEntity current) patch,
) async {
  final usecases = ref.read(recordingUsecasesProvider);
  final current = (await usecases.getById(id)).valueOrNull;
  if (current == null) return null;

  final updated = patch(current);
  final result = await usecases.save(updated);
  if (result.isErr) return null;

  ref.invalidate(recordingByIdProvider(id));
  return updated;
}

/// Saves the output of a processing tool against recording [recordingId],
/// either over the recording or beside it, per [mode].
///
/// Neither mode deletes audio. Replacing archives the previous take instead
/// of overwriting it, so the untouched original stays playable from the
/// Originals tab — a processing pass is always undoable by keeping the file.
///
/// Returns the id of the recording the user should be looking at afterwards:
/// the new copy for [DerivativeSaveMode.saveAsNew], the same recording for
/// [DerivativeSaveMode.replace], or null if nothing was saved.
Future<String?> saveDerivative(
  Ref ref, {
  required String recordingId,
  required String processedPath,
  required String titleSuffix,
  required DerivativeSaveMode mode,
  required DerivativeMarker mark,
}) async {
  final usecases = ref.read(recordingUsecasesProvider);
  final current = (await usecases.getById(recordingId)).valueOrNull;
  if (current == null) return null;

  // The processed file has its own length and size — a denoise pass can
  // change both — so measure rather than carrying the source's numbers over.
  final duration =
      await ref.read(audioEditorServiceProvider).probeDuration(processedPath);
  final sizeBytes = await FileUtils.sizeOf(processedPath);

  switch (mode) {
    case DerivativeSaveMode.saveAsNew:
      final copy = mark(
        RecordingEntity(
          id: FileUtils.newId(),
          title: '${current.title} ($titleSuffix)',
          localPath: processedPath,
          duration: duration,
          sizeBytes: sizeBytes,
          createdAt: DateTime.now(),
          format: current.format,
          sampleRate: current.sampleRate,
          quality: current.quality,
          kind: RecordingKind.modified,
          sourceRecordingId: current.id,
        ),
        processedPath,
      );
      if ((await usecases.save(copy)).isErr) return null;
      ref.invalidate(recordingByIdProvider(recordingId));
      return copy.id;

    case DerivativeSaveMode.replace:
      final archive = RecordingEntity(
        id: FileUtils.newId(),
        title: '${current.title} (original)',
        localPath: current.localPath,
        duration: current.duration,
        sizeBytes: current.sizeBytes,
        createdAt: current.createdAt,
        format: current.format,
        sampleRate: current.sampleRate,
        quality: current.quality,
        kind: RecordingKind.archivedOriginal,
        sourceRecordingId: current.id,
      );
      // Archive first: if this write fails there is nothing to roll back,
      // whereas replacing first could leave the original unreferenced.
      if ((await usecases.save(archive)).isErr) return null;

      final replaced = mark(
        current.copyWith(
          localPath: processedPath,
          duration: duration,
          sizeBytes: sizeBytes,
        ),
        processedPath,
      );
      if ((await usecases.save(replaced)).isErr) return null;
      ref.invalidate(recordingByIdProvider(recordingId));
      return recordingId;
  }
}
