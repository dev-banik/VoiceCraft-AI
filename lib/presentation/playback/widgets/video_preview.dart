import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Shows the picture for a video entry on the playback screen.
///
/// Deliberately silent: the audio player already owns the soundtrack, so
/// letting this one play sound too would give you the take twice, slightly
/// out of step. This follows the audio position instead, which keeps the
/// existing transport, speed and version-switching controls in charge.
class VideoPreview extends StatefulWidget {
  final String path;
  final Duration position;
  final bool isPlaying;

  const VideoPreview({
    super.key,
    required this.path,
    required this.position,
    required this.isPlaying,
  });

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(VideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _controller?.dispose();
      _controller = null;
      _open();
      return;
    }
    _follow();
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.file(File(widget.path));
    try {
      await controller.initialize();
      await controller.setVolume(0);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      _follow();
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _error = 'This video cannot be previewed here.');
    }
  }

  /// Keeps the picture with the audio. Only corrects when they have drifted
  /// noticeably, since seeking on every frame would stutter.
  Future<void> _follow() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final drift =
        (controller.value.position - widget.position).inMilliseconds.abs();
    if (drift > 300) await controller.seekTo(widget.position);

    if (widget.isPlaying && !controller.value.isPlaying) {
      await controller.play();
    } else if (!widget.isPlaying && controller.value.isPlaying) {
      await controller.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(_error!, style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }
}
