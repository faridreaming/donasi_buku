import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM opsional — app tetap jalan meski FCM gagal
  try {
    await FcmService.initialize();
  } catch (e) {
    debugPrint('[FCM] Skipped: $e');
  }

  timeago.setLocaleMessages('id', timeago.IdMessages());

  runApp(const ProviderScope(child: DonasiBukuApp()));
}
