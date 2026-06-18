import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<void> requestAppPermissions() async {
    if (kIsWeb) return;

    await [
      Permission.camera,
      Permission.contacts,
      Permission.microphone,
      Permission.location,
    ].request();
  }
}
