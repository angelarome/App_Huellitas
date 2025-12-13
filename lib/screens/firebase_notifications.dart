import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';

// Handler de background (solo móvil)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Mensaje en background: ${message.messageId}");
}

Future<void> configurarFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('Permiso: ${settings.authorizationStatus}');

  String? token;
  if (kIsWeb) {
    token = await messaging.getToken(
      vapidKey: "TU_VAPID_KEY_DEL_FIREBASE_CONSOLE",
    );
  } else {
    token = await messaging.getToken();
  }
  print("🔑 Token FCM: $token");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Mensaje foreground: ${message.notification?.title}");
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📩 App abierta desde notificación");
  });
}