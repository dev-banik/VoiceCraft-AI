import 'package:permission_handler/permission_handler.dart';

/// Centralizes runtime permission requests so every feature (recording,
/// media library access) asks in a consistent, testable way.
class PermissionUtils {
  PermissionUtils._();

  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  static Future<bool> hasMicrophone() async {
    return Permission.microphone.status.then((s) => s.isGranted);
  }

  static Future<bool> requestNotifications() async {
    final status = await Permission.notification.request();
    return status.isGranted || status.isLimited;
  }
}
