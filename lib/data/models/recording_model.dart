import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/recording_entity.dart';

part 'recording_model.g.dart';

/// Hive-persisted shape of a recording. Enums are stored as their `name`
/// string (not index) so reordering the enum in [app_constants.dart] never
/// silently corrupts existing local data.
@HiveType(typeId: 0)
class RecordingModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String localPath;

  @HiveField(3)
  final int durationMs;

  @HiveField(4)
  final int sizeBytes;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final String format;

  @HiveField(7)
  final int sampleRate;

  @HiveField(8)
  final String quality;

  @HiveField(9)
  final String? denoisedPath;

  @HiveField(10)
  final Map<String, String> themeVariants;

  @HiveField(11)
  final bool synced;

  @HiveField(12)
  final String? cloudUrl;

  @HiveField(13)
  final List<String> tags;

  @HiveField(14)
  final String? enhancedPath;

  RecordingModel({
    required this.id,
    required this.title,
    required this.localPath,
    required this.durationMs,
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

  factory RecordingModel.fromEntity(RecordingEntity e) {
    return RecordingModel(
      id: e.id,
      title: e.title,
      localPath: e.localPath,
      durationMs: e.duration.inMilliseconds,
      sizeBytes: e.sizeBytes,
      createdAt: e.createdAt,
      format: e.format.name,
      sampleRate: e.sampleRate,
      quality: e.quality.name,
      denoisedPath: e.denoisedPath,
      enhancedPath: e.enhancedPath,
      themeVariants:
          e.themeVariants.map((theme, path) => MapEntry(theme.name, path)),
      synced: e.synced,
      cloudUrl: e.cloudUrl,
      tags: e.tags,
    );
  }

  RecordingEntity toEntity() {
    return RecordingEntity(
      id: id,
      title: title,
      localPath: localPath,
      duration: Duration(milliseconds: durationMs),
      sizeBytes: sizeBytes,
      createdAt: createdAt,
      format: RecordingFormat.values.byName(format),
      sampleRate: sampleRate,
      quality: RecordingQuality.values.byName(quality),
      denoisedPath: denoisedPath,
      enhancedPath: enhancedPath,
      themeVariants: themeVariants.map(
        (name, path) => MapEntry(VoiceTheme.values.byName(name), path),
      ),
      synced: synced,
      cloudUrl: cloudUrl,
      tags: tags,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'durationMs': durationMs,
      'sizeBytes': sizeBytes,
      'createdAt': createdAt.toIso8601String(),
      'format': format,
      'sampleRate': sampleRate,
      'quality': quality,
      'cloudUrl': cloudUrl,
      'tags': tags,
    };
  }

  static RecordingModel fromFirestore(
    Map<String, dynamic> data,
    String localPath,
  ) {
    return RecordingModel(
      id: data['id'] as String,
      title: data['title'] as String,
      localPath: localPath,
      durationMs: data['durationMs'] as int,
      sizeBytes: data['sizeBytes'] as int,
      createdAt: DateTime.parse(data['createdAt'] as String),
      format: data['format'] as String,
      sampleRate: data['sampleRate'] as int,
      quality: data['quality'] as String,
      cloudUrl: data['cloudUrl'] as String?,
      tags: (data['tags'] as List<dynamic>? ?? const []).cast<String>(),
      synced: true,
    );
  }
}
