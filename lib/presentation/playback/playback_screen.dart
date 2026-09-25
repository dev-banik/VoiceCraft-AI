import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../core/router/route_names.dart';
import '../../core/utils/formatters.dart';
import '../../services/ai/processed_media.dart';
import '../shared/widgets/static_waveform.dart';
import 'widgets/video_preview.dart';
import 'controller/playback_controller.dart';

const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

class PlaybackScreen extends ConsumerStatefulWidget {
  final String recordingId;
  const PlaybackScreen({super.key, required this.recordingId});

  @override
  ConsumerState<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends ConsumerState<PlaybackScreen> {
  double _speed = 1.0;
  bool _loop = false;
  PlaybackSource _source = const OriginalSource();
  String? _loadedPath;

  /// Duration as the player reports it, which governs the seek bar. Null
  /// until the source has actually loaded.
  Duration? _playerDuration;
  String? _loadError;

  /// For a video, this controller *is* the player — it produces the sound as
  /// well as the picture, and the transport below drives it instead of the
  /// audio engine. Null whenever the active source is plain audio.
  VideoPlayerController? _video;

  bool get _isVideoActive => _video != null;

  @override
  void dispose() {
    // The audio player is a long-lived singleton shared with the denoise and
    // theme screens, so leaving this screen never stopped it — the recording
    // kept playing over the dashboard with no way to stop it.
    ref.read(audioPlayerServiceProvider).stop();
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    super.dispose();
  }

  void _onVideoTick() {
    // The video controller has no position stream, so the screen repaints
    // from its listener to keep the seek bar and play icon honest.
    if (mounted) setState(() {});
  }

  Future<void> _load(String path, {required bool isVideo}) async {
    await _disposeVideo();
    try {
      if (isVideo) {
        final controller = VideoPlayerController.file(File(path));
        await controller.initialize();
        if (!mounted) {
          await controller.dispose();
          return;
        }
        await controller.setVolume(1);
        controller.addListener(_onVideoTick);
        setState(() {
          _video = controller;
          _playerDuration = controller.value.duration;
          _loadError = null;
        });
        return;
      }

      final duration = await ref.read(playbackControllerProvider).load(path);
      if (!mounted) return;
      setState(() {
        _playerDuration = duration;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Surfacing this beats the old behaviour, where a failed load left a
      // transport that silently ignored play and seek.
      setState(() => _loadError = e.toString());
    }
  }

  Future<void> _disposeVideo() async {
    final controller = _video;
    if (controller == null) return;
    controller.removeListener(_onVideoTick);
    _video = null;
    await controller.dispose();
  }

  // --- Transport, routed to whichever engine owns the active source -------

  Future<void> _togglePlay(bool isPlaying) async {
    final video = _video;
    if (video != null) {
      isPlaying ? await video.pause() : await video.play();
      return;
    }
    await ref.read(playbackControllerProvider).playPause(isPlaying);
  }

  Future<void> _seek(Duration position) async {
    final video = _video;
    if (video != null) return video.seekTo(position);
    return ref.read(playbackControllerProvider).seek(position);
  }

  Future<void> _setSpeed(double speed) async {
    final video = _video;
    if (video != null) return video.setPlaybackSpeed(speed);
    return ref.read(playbackControllerProvider).setSpeed(speed);
  }

  Future<void> _setLoop(bool loop) async {
    final video = _video;
    if (video != null) return video.setLooping(loop);
    return ref.read(playbackControllerProvider).setLoop(loop);
  }

  /// Opens one of the processing tools and, when it saved a new version,
  /// switches playback onto it. The tools pop the [PlaybackSource] they
  /// produced; a null result means nothing was saved, so the current
  /// selection stands.
  Future<void> _openTool(String path) async {
    final saved = await context.push<PlaybackSource>(path);
    if (!mounted || saved == null) return;
    setState(() => _source = saved);
  }

  @override
  Widget build(BuildContext context) {
    final recordingAsync = ref.watch(recordingByIdProvider(widget.recordingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Playback')),
      body: recordingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load recording: $e')),
        data: (recording) {
          if (recording == null) {
            return const Center(child: Text('Recording not found.'));
          }

          final activePath = switch (_source) {
            OriginalSource() => recording.localPath,
            DenoisedSource() => recording.denoisedPath ?? recording.localPath,
            EnhancedSource() => recording.enhancedPath ?? recording.localPath,
            ThemeSource(theme: final t) =>
              recording.themeVariants[t] ?? recording.localPath,
          };

          // Decided per file, not per recording: a video's extracted
          // soundtrack is a plain audio derivative of a video entry.
          final activeIsVideo = isVideoPath(activePath);

          if (_loadedPath != activePath) {
            _loadedPath = activePath;
            _playerDuration = null;
            _loadError = null;
            Future.microtask(
              () => _load(activePath, isVideo: activeIsVideo),
            );
          }

          final positionAsync = ref.watch(playbackPositionProvider);
          final stateAsync = ref.watch(playbackStateProvider);

          final video = _video;
          final position = video != null
              ? video.value.position
              : (positionAsync.valueOrNull ?? Duration.zero);
          final isPlaying = video != null
              ? video.value.isPlaying
              : (stateAsync.valueOrNull?.playing ?? false);
          final duration = _playerDuration ?? recording.duration;
          final progress = duration.inMilliseconds == 0
              ? 0.0
              : (position.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0);

          return SafeArea(
            // Scrollable, not a bare Column. Adding the video preview pushed
            // the transport and the Denoise/Themes/Edit row off the bottom
            // with no way to reach them — and on a short screen the audio
            // layout was already close to the edge.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.dateTime(recording.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_loadError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _loadError!,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onErrorContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                _load(activePath, isVideo: activeIsVideo),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (activeIsVideo)
                    VideoPreview(controller: _video, error: _loadError)
                  // The picture already shows what is playing, and pulling a
                  // waveform out of a video container mostly fails anyway.
                  else
                    ref.watch(waveformSamplesProvider(activePath)).when(
                    loading: () => const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox(height: 100),
                    data: (samples) => StaticWaveform(
                      samples: samples,
                      progress: progress,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Formatters.duration(position)),
                      Text(Formatters.duration(duration)),
                    ],
                  ),
                  Slider(
                    value: position.inMilliseconds
                        .clamp(0, duration.inMilliseconds)
                        .toDouble(),
                    max: duration.inMilliseconds.toDouble().clamp(1, double.infinity),
                    onChanged: (v) => _seek(Duration(milliseconds: v.round())),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _loop ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                          color: _loop
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        onPressed: () {
                          setState(() => _loop = !_loop);
                          _setLoop(_loop);
                        },
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _togglePlay(isPlaying),
                          child: SizedBox(
                            width: 72,
                            height: 72,
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<double>(
                        initialValue: _speed,
                        onSelected: (v) {
                          setState(() => _speed = v);
                          _setSpeed(v);
                        },
                        itemBuilder: (_) => _speeds
                            .map((s) => PopupMenuItem(
                                  value: s,
                                  child: Text('${s}x'),
                                ))
                            .toList(),
                        child: Chip(label: Text('${_speed}x')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Versions',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Original'),
                        selected: _source is OriginalSource,
                        onSelected: (_) =>
                            setState(() => _source = const OriginalSource()),
                      ),
                      if (recording.hasNoiseRemoval)
                        ChoiceChip(
                          label: const Text('Noise removed'),
                          selected: _source is DenoisedSource,
                          onSelected: (_) =>
                              setState(() => _source = const DenoisedSource()),
                        ),
                      if (recording.hasEnhancement)
                        ChoiceChip(
                          label: const Text('Enhanced'),
                          selected: _source is EnhancedSource,
                          onSelected: (_) =>
                              setState(() => _source = const EnhancedSource()),
                        ),
                      for (final theme in recording.themeVariants.keys)
                        ChoiceChip(
                          label: Text(theme.label),
                          selected: _source is ThemeSource &&
                              (_source as ThemeSource).theme == theme,
                          // Tapping the selected version drops back to the
                          // original rather than doing nothing.
                          onSelected: (chosen) => setState(
                            () => _source = chosen
                                ? ThemeSource(theme)
                                : const OriginalSource(),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.graphic_eq_rounded),
                          label: const Text('Denoise'),
                          onPressed: () => _openTool(
                            RoutePaths.noiseRemovalPath(recording.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Themes'),
                          onPressed: () => _openTool(
                            RoutePaths.voiceThemesPath(recording.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.content_cut_rounded),
                          label: const Text('Edit'),
                          onPressed: () => _openTool(
                            RoutePaths.editorPath(recording.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
