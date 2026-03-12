import 'dart:io';

import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'Kineo Coach';

  static String get apiBaseUrl {
    const configuredValue = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (configuredValue.isNotEmpty) {
      return configuredValue;
    }

    if (!kIsWeb && Platform.isAndroid && kDebugMode) {
      // Physical Android devices connect to the backend through the host LAN IP.
      return 'http://192.168.128.11:8010';
    }

    return 'http://localhost:8000';
  }
}
