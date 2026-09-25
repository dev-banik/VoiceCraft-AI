import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/constants/app_constants.dart';
import '../../../core/di/providers.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/recording_entity.dart';
import '../../../services/ai/processed_media.dart';

/// Why an import failed, so the dashboard can say something specific rather
/// than a generic error.
enum ImportFailure { cancelled, unreadable, copyFailed, saveFailed }

class ImportResult {
  final String? recordingId;
  final ImportFailure? failure;

  const ImportResult.success(this.recordingId) : failure = null;
  const ImportResult.failed(this.failure) : recordingId = null;

  bool get isSuccess => recordingId != null;
  bool get wasCancelled => failure == ImportFailure.cancelled;

  String get message {
    switch (failure) {
      case ImportFailure.unreadable:
        return "That file couldn't be read.";
      case ImportFailure.copyFailed:
        return "That file couldn't be copied into your library.";
      case ImportFailure.saveFailed:
        return "That file couldn't be added to your library.";
      case ImportFailure.cancelled:
      case null:
        return '';
    }
  }
}

/// Brings an audio file already on the device into the library so it can be
/// denoised or themed like anything recorded in the app.
///
/// The file is *copied* rather than referenced in place: the source could be
/// in a downloads folder the user later clears, or on removable storage, and
/// a library entry pointing at a file that vanishes is worse than a copy.
///
/// Currently audio only. Video is a deliberate next step — the same pipeline
/// would extract the audio track, process it and mux it back.
class ImportController {
  final Ref ref;
  const ImportController(this.ref);

  Future<ImportResult> pickAndImport() async {
    FilePickerResult? picked;
    try {
      // `media` covers audio and video in one picker, so importing a clip
      // to clean up its soundtrack is the same gesture as importing audio.
      picked = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: false,
        withData: false,
      );
    } catch (e) {
      appLogger.w('File picker failed: $e');
      return const ImportResult.failed(ImportFailure.unreadable);
    }

    final sourcePath = picked?.files.single.path;
    if (sourcePath == null) {
      return const ImportResult.failed(ImportFailure.cancelled);
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      return const ImportResult.failed(ImportFailure.unreadable);
    }

    String destinationPath;
    try {
      final dir = await FileUtils.recordingsDirectory();
      final extension = p.extension(sourcePath).replaceFirst('.', '');
      destinationPath = p.join(
        dir.path,
        '${FileUtils.newId()}.${extension.isEmpty ? 'm4a' : extension}',
      );
      await source.copy(destinationPath);
    } catch (e) {
      appLogger.w('Could not copy imported file: $e');
      return const ImportResult.failed(ImportFailure.copyFailed);
    }

    final duration =
        await ref.read(audioEditorServiceProvider).probeDuration(destinationPath);
    final sizeBytes = await FileUtils.sizeOf(destinationPath);

    final recording = RecordingEntity(
      id: FileUtils.newId(),
      title: p.basenameWithoutExtension(sourcePath),
      localPath: destinationPath,
      duration: duration,
      sizeBytes: sizeBytes,
      createdAt: DateTime.now(),
      // Imported files aren't captured by the recorder, so the recorder's
      // format/quality settings don't describe them. These fields only drive
      // export defaults, so the app's current settings are a fair stand-in.
      format: RecordingFormat.aac,
      sampleRate: AppConstants.defaultSampleRate,
      quality: RecordingQuality.high,
      mediaType: isVideoPath(destinationPath) ? MediaType.video : MediaType.audio,
      tags: const ['imported'],
    );

    final saved = await ref.read(recordingUsecasesProvider).save(recording);
    if (saved.isErr) {
      return const ImportResult.failed(ImportFailure.saveFailed);
    }
    return ImportResult.success(recording.id);
  }
}

final Provider<ImportController> importControllerProvider =
    Provider((ref) => ImportController(ref));
