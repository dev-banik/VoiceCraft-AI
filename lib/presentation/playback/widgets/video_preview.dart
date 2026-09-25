import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Draws the picture for a video entry. Purely a view: the playback screen
/// owns the controller, because for a video that controller *is* the player
/// — it produces the sound as well as the image.
///
/// An earlier version owned its own muted controller and left `just_audio`
/// to play the soundtrack out of the same .mp4. Nothing came out: the video
/// was silenced by design and the audio engine could not drive the file, so
/// the transport sat at 0:00 ignoring play and seek.
class VideoPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final String? error;

  const VideoPreview({super.key, this.controller, this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(error!, style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    final controller = this.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Capped height: a portrait clip at its natural aspect ratio fills the
    // display and buries the controls under it.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),
        ),
      ),
    );
  }
}
