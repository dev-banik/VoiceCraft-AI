// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-authored to match the output of `build_runner build` with
// hive_generator, since this environment cannot execute build_runner.
// If you run `flutter pub run build_runner build --delete-conflicting-outputs`
// locally it is safe to let it overwrite this file.

part of 'recording_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecordingModelAdapter extends TypeAdapter<RecordingModel> {
  @override
  final int typeId = 0;

  @override
  RecordingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecordingModel(
      id: fields[0] as String,
      title: fields[1] as String,
      localPath: fields[2] as String,
      durationMs: fields[3] as int,
      sizeBytes: fields[4] as int,
      createdAt: fields[5] as DateTime,
      format: fields[6] as String,
      sampleRate: fields[7] as int,
      quality: fields[8] as String,
      denoisedPath: fields[9] as String?,
      themeVariants: (fields[10] as Map).cast<String, String>(),
      synced: fields[11] as bool,
      cloudUrl: fields[12] as String?,
      tags: (fields[13] as List).cast<String>(),
      enhancedPath: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RecordingModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.localPath)
      ..writeByte(3)
      ..write(obj.durationMs)
      ..writeByte(4)
      ..write(obj.sizeBytes)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.format)
      ..writeByte(7)
      ..write(obj.sampleRate)
      ..writeByte(8)
      ..write(obj.quality)
      ..writeByte(9)
      ..write(obj.denoisedPath)
      ..writeByte(10)
      ..write(obj.themeVariants)
      ..writeByte(11)
      ..write(obj.synced)
      ..writeByte(12)
      ..write(obj.cloudUrl)
      ..writeByte(13)
      ..write(obj.tags)
      ..writeByte(14)
      ..write(obj.enhancedPath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
