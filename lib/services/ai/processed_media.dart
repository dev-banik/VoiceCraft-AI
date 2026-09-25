import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';

/// What came out of a processing pass.
///
/// For an audio source there is one file and [audioPath] is null. For a
/// video source there are two: the video with its cleaned soundtrack muxed
/// back in, and that soundtrack on its own — useful to share or reuse
/// without carrying the picture around.
class ProcessedMedia {
  /// The result the user is primarily keeping: the video for a video
  /// source, the audio file for an audio source.
  final String path;

  /// The processed audio on its own, present only for a video source.
  final String? audioPath;

  /// The *unprocessed* soundtrack, extracted so a before/after comparison
  /// has something playable to compare against — the audio engine cannot
  /// drive an .mp4, so without this the "before" side of a video A/B is
  /// silent. Present only for a video source.
  final String? sourceAudioPath;

  const ProcessedMedia(this.path, {this.audioPath, this.sourceAudioPath});

  bool get hasSeparateAudio => audioPath != null;
}

/// Whether a path points at something with a video stream, decided by
/// extension. Probing the container would be more rigorous but costs an
/// FFmpeg round trip on every call; an unrecognised extension falls through
/// to audio-only handling, which fails safely.
bool isVideoPath(String path) {
  final extension = p.extension(path).replaceFirst('.', '').toLowerCase();
  return kVideoExtensions.contains(extension);
}
