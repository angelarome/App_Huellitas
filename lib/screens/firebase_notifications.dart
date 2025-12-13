import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


// Handler para notificaciones en background (móvil)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Mensaje en background: ${message.messageId}");
}

Future<void> configurarFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  if (!kIsWeb) {
    // Registrar handler de background solo en móvil
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // Solicitar permisos
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  print('Permiso de notificaciones: ${settings.authorizationStatus}');

  // Obtener token
  String? token;
  if (kIsWeb) {
    token = await messaging.getToken(
      vapidKey: "TU_VAPID_KEY_DEL_FIREBASE_CONSOLE",
    );
  } else {
    token = await messaging.getToken();
  }
  print("🔑 Token FCM: $token");

  // Mensajes en primer plano
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Mensaje en foreground: ${message.notification?.title}");
    if (message.notification?.body != null) {
      print("📩 Body: ${message.notification?.body}");
    }
  });

  // Cuando se abre la app desde la notificación
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📩 App abierta desde notificación");
  });
}
