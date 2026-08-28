import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/file_utils.dart';
import '../../../domain/entities/recording_entity.dart';

/// Selection range as fractions (0..1) of total duration, used by the
/// interactive waveform's drag handles.
class EditorSelection {
  final double start;
  final double end;
  const EditorSelection({this.start = 0.2, this.end = 0.8});

  EditorSelection copyWith({double? start, double? end}) {
    return EditorSelection(start: start ?? this.start, end: end ?? this.end);
  }

  Duration startDuration(Duration total) =>
      Duration(milliseconds: (total.inMilliseconds * start).round());
  Duration endDuration(Duration total) =>
      Duration(milliseconds: (total.inMilliseconds * end).round());
}

class EditorState {
  final EditorSelection selection;
  final double zoom;
  final bool isBusy;
  final String? error;
  final String? statusMessage;

  const EditorState({
    this.selection = const EditorSelection(),
    this.zoom = 1.0,
    this.isBusy = false,
    this.error,
    this.statusMessage,
  });

  EditorState copyWith({
    EditorSelection? selection,
    double? zoom,
    bool? isBusy,
    String? error,
    String? statusMessage,
  }) {
    return EditorState(
      selection: selection ?? this.selection,
      zoom: zoom ?? this.zoom,
      isBusy: isBusy ?? this.isBusy,
      error: error,
      statusMessage: statusMessage,
    );
  }
}

class EditorController extends StateNotifier<EditorState> {
  final Ref ref;
  EditorController(this.ref) : super(const EditorState());

  void setSelection(EditorSelection selection) {
    state = state.copyWith(
      selection: EditorSelection(
        start: selection.start.clamp(0.0, selection.end - 0.01),
        end: selection.end.clamp(selection.start + 0.01, 1.0),
      ),
    );
  }

  void setZoom(double zoom) => state = state.copyWith(zoom: zoom.clamp(1, 8));

  Future<void> _run(Future<void> Function() action, String successMessage) async {
    state = state.copyWith(isBusy: true, error: null, statusMessage: null);
    try {
      await action();
      state = state.copyWith(isBusy: false, statusMessage: successMessage);
    } catch (e) {
      state = state.copyWith(isBusy: false, error: e.toString());
    }
  }

  Future<void> trim(RecordingEntity recording) => _run(() async {
        final editor = ref.read(audioEditorServiceProvider);
        final output = await editor.trim(
          recording.localPath,
          start: state.selection.startDuration(recording.duration),
          end: state.selection.endDuration(recording.duration),
        );
        await _replaceInPlace(recording, output);
      }, 'Trimmed to selection.');

  Future<void> deleteSelection(RecordingEntity recording) => _run(() async {
        final editor = ref.read(audioEditorServiceProvider);
        final output = await editor.deleteSegment(
          recording.localPath,
          start: state.selection.startDuration(recording.duration),
          end: state.selection.endDuration(recording.duration),
        );
        await _replaceInPlace(recording, output);
      }, 'Selected segment deleted.');

  Future<void> fadeIn(RecordingEntity recording, Duration duration) =>
      _run(() async {
        final output = await ref
            .read(audioEditorServiceProvider)
            .fadeIn(recording.localPath, duration);
        await _replaceInPlace(recording, output);
      }, 'Fade in applied.');

  Future<void> fadeOut(RecordingEntity recording, Duration duration) =>
      _run(() async {
        final output = await ref.read(audioEditorServiceProvider).fadeOut(
              recording.localPath,
              duration,
              recording.duration,
            );
        await _replaceInPlace(recording, output);
      }, 'Fade out applied.');

  Future<void> adjustVolume(RecordingEntity recording, double gainDb) =>
      _run(() async {
        final output = await ref
            .read(audioEditorServiceProvider)
            .adjustVolume(recording.localPath, gainDb);
        await _replaceInPlace(recording, output);
      }, 'Volume adjusted.');

  Future<void> copySegmentAsNewRecording(RecordingEntity recording) =>
      _run(() async {
        final output = await ref.read(audioEditorServiceProvider).copySegment(
              recording.localPath,
              start: state.selection.startDuration(recording.duration),
              end: state.selection.endDuration(recording.duration),
            );
        await _saveAsNew(recording, output, suffix: 'copy');
      }, 'Segment copied as a new recording.');

  Future<void> splitAtSelectionStart(RecordingEntity recording) =>
      _run(() async {
        final editor = ref.read(audioEditorServiceProvider);
        final at = state.selection.startDuration(recording.duration);
        final (partA, partB) = await editor.split(recording.localPath, at);
        await _saveAsNew(recording, partA, suffix: 'part A');
        await _saveAsNew(recording, partB, suffix: 'part B');
      }, 'Split into two recordings.');

  Future<void> _replaceInPlace(RecordingEntity recording, String newPath) async {
    final editor = ref.read(audioEditorServiceProvider);
    final newDuration = await editor.probeDuration(newPath);
    final newSize = await FileUtils.sizeOf(newPath);
    final updated = recording.copyWith(
      localPath: newPath,
      duration: newDuration,
      sizeBytes: newSize,
    );
    await ref.read(recordingUsecasesProvider).save(updated);
    setSelection(const EditorSelection());
  }

  Future<void> _saveAsNew(
    RecordingEntity source,
    String newPath, {
    required String suffix,
  }) async {
    final editor = ref.read(audioEditorServiceProvider);
    final duration = await editor.probeDuration(newPath);
    final size = await FileUtils.sizeOf(newPath);
    final entity = RecordingEntity(
      id: FileUtils.newId(),
      title: '${source.title} ($suffix)',
      localPath: newPath,
      duration: duration,
      sizeBytes: size,
      createdAt: DateTime.now(),
      format: source.format,
      sampleRate: source.sampleRate,
      quality: source.quality,
    );
    await ref.read(recordingUsecasesProvider).save(entity);
  }
}

final StateNotifierProvider<EditorController, EditorState>
    editorControllerProvider =
    StateNotifierProvider<EditorController, EditorState>(
  (ref) => EditorController(ref),
);
