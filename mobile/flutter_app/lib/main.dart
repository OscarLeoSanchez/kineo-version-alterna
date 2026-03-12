import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/services/local_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationService.instance.initialize();
  runApp(const KineoCoachApp());
}
