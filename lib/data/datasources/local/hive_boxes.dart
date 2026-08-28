import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../models/app_settings_model.dart';
import '../../models/recording_model.dart';

/// Opens/registers all Hive boxes and type adapters. Called once from
/// `main.dart` before `runApp`.
class HiveBoxes {
  HiveBoxes._();

  static late Box<RecordingModel> recordings;
  static late Box<AppSettingsModel> settings;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RecordingModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsModelAdapter());
    }

    recordings = await Hive.openBox<RecordingModel>(
      AppConstants.recordingsBox,
    );
    settings = await Hive.openBox<AppSettingsModel>(
      AppConstants.settingsBox,
    );
  }
}
