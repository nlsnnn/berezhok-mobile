import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:berezhok/app.dart';
import 'package:berezhok/features/notifications/providers/push_notification_providers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background push notification received: ${message.data}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  var firebaseMessagingInitialized = false;
  if (dotenv.get('ENABLE_PUSH_NOTIFICATIONS', fallback: 'false') == 'true') {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      firebaseMessagingInitialized = true;
    } catch (error) {
      debugPrint('Failed to initialize Firebase Messaging: $error');
    }
  }

  // Initialize intl locale data for Russian date formatting
  await initializeDateFormatting('ru', null);

  // Lock to portrait mode
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        firebaseMessagingInitializedProvider.overrideWithValue(
          firebaseMessagingInitialized,
        ),
      ],
      child: const BerezhokApp(),
    ),
  );
}
