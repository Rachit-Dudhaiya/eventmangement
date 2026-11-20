import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.instance.initialize();
  runApp(
    const ProviderScope(
      child: CampusEventApp(),
    ),
  );
}
