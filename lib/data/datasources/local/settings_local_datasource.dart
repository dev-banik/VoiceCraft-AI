import '../../models/app_settings_model.dart';
import 'hive_boxes.dart';

const String _settingsKey = 'settings';

/// Direct Hive access for the single [AppSettingsModel] record.
class SettingsLocalDatasource {
  const SettingsLocalDatasource();

  AppSettingsModel get() {
    return HiveBoxes.settings.get(_settingsKey) ?? AppSettingsModel();
  }

  Future<void> save(AppSettingsModel settings) async {
    await HiveBoxes.settings.put(_settingsKey, settings);
  }
}
