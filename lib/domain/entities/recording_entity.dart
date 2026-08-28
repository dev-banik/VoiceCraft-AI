import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

/// Pure domain representation of a single recording. This is what the
/// presentation layer works with; [data/models/recording_model.dart] is the
/// Hive-persisted shape and maps to/from this entity at the repository
/// boundary so storage concerns never leak into the UI.
class RecordingEntity extends Equatable {
  final String id;
  final String title;
  final String localPath;
  final Duration duration;
  final int sizeBytes;
  final DateTime createdAt;
  final RecordingFormat format;
  final int sampleRate;
  final RecordingQuality quality;

  /// Path to the noise-removed derivative, if one has been generated.
  final String? denoisedPath;

  /// Path to the clarity-enhanced derivative, if one has been generated.
  final String? enhancedPath;

  /// Voice-theme derivatives generated from this recording, keyed by theme.
  final Map<VoiceTheme, String> themeVariants;

  final bool synced;
  final String? cloudUrl;
  final List<String> tags;

  const RecordingEntity({
    required this.id,
    required this.title,
    required this.localPath,
    required this.duration,
    required this.sizeBytes,
    required this.createdAt,
    required this.format,
    required this.sampleRate,
    required this.quality,
    this.denoisedPath,
    this.enhancedPath,
    this.themeVariants = const {},
    this.synced = false,
    this.cloudUrl,
    this.tags = const [],
  });

  bool get hasNoiseRemoval => denoisedPath != null;
  bool get hasEnhancement => enhancedPath != null;
  bool get hasThemeApplied => themeVariants.isNotEmpty;
  bool get isLocalOnly => !synced;

  RecordingEntity copyWith({
    String? id,
    String? title,
    String? localPath,
    Duration? duration,
    int? sizeBytes,
    DateTime? createdAt,
    RecordingFormat? format,
    int? sampleRate,
    RecordingQuality? quality,
    String? denoisedPath,
    String? enhancedPath,
    Map<VoiceTheme, String>? themeVariants,
    bool? synced,
    String? cloudUrl,
    List<String>? tags,
  }) {
    return RecordingEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      localPath: localPath ?? this.localPath,
      duration: duration ?? this.duration,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      createdAt: createdAt ?? this.createdAt,
      format: format ?? this.format,
      sampleRate: sampleRate ?? this.sampleRate,
      quality: quality ?? this.quality,
      denoisedPath: denoisedPath ?? this.denoisedPath,
      enhancedPath: enhancedPath ?? this.enhancedPath,
      themeVariants: themeVariants ?? this.themeVariants,
      synced: synced ?? this.synced,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      tags: tags ?? this.tags,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        localPath,
        duration,
        sizeBytes,
        createdAt,
        format,
        sampleRate,
        quality,
        denoisedPath,
        enhancedPath,
        themeVariants,
        synced,
        cloudUrl,
        tags,
      ];
}
