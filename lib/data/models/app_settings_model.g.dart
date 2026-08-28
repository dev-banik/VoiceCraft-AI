// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-authored to match hive_generator output; see recording_model.g.dart
// for context on why this is checked in rather than generated.

part of 'app_settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppSettingsModelAdapter extends TypeAdapter<AppSettingsModel> {
  @override
  final int typeId = 1;

  @override
  AppSettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettingsModel(
      recordingFormat: fields[0] as String,
      sampleRate: fields[1] as int,
      recordingQuality: fields[2] as String,
      themeMode: fields[3] as String,
      autoBackupEnabled: fields[4] as bool,
      backupOnWifiOnly: fields[5] as bool,
      languageCode: fields[6] as String,
      defaultVoiceTheme: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettingsModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.recordingFormat)
      ..writeByte(1)
      ..write(obj.sampleRate)
      ..writeByte(2)
      ..write(obj.recordingQuality)
      ..writeByte(3)
      ..write(obj.themeMode)
      ..writeByte(4)
      ..write(obj.autoBackupEnabled)
      ..writeByte(5)
      ..write(obj.backupOnWifiOnly)
      ..writeByte(6)
      ..write(obj.languageCode)
      ..writeByte(7)
      ..write(obj.defaultVoiceTheme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
