import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/utils/formatters.dart';
import '../shared/widgets/static_waveform.dart';
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

          if (_loadedPath != activePath) {
            _loadedPath = activePath;
            Future.microtask(
              () => ref.read(playbackControllerProvider).load(activePath),
            );
          }

          final waveformAsync = ref.watch(waveformSamplesProvider(activePath));
          final positionAsync = ref.watch(playbackPositionProvider);
          final stateAsync = ref.watch(playbackStateProvider);
          final position = positionAsync.valueOrNull ?? Duration.zero;
          final isPlaying = stateAsync.valueOrNull?.playing ?? false;
          final duration = recording.duration;
          final progress = duration.inMilliseconds == 0
              ? 0.0
              : (position.inMilliseconds / duration.inMilliseconds)
                  .clamp(0.0, 1.0);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 24),
                  waveformAsync.when(
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
                    onChanged: (v) => ref
                        .read(playbackControllerProvider)
                        .seek(Duration(milliseconds: v.round())),
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
                          ref.read(playbackControllerProvider).setLoop(_loop);
                        },
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Theme.of(context).colorScheme.primary,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => ref
                              .read(playbackControllerProvider)
                              .playPause(isPlaying),
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
                          ref.read(playbackControllerProvider).setSpeed(v);
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
                          selected:
                              _source is ThemeSource && (_source as ThemeSource).theme == theme,
                          onSelected: (_) =>
                              setState(() => _source = ThemeSource(theme)),
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
                          onPressed: () => context.push(
                            RoutePaths.noiseRemovalPath(recording.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Themes'),
                          onPressed: () => context.push(
                            RoutePaths.voiceThemesPath(recording.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.content_cut_rounded),
                          label: const Text('Edit'),
                          onPressed: () => context.push(
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
