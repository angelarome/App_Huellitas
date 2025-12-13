import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📩 Background: ${message.messageId}");
}

Future<void> configurarFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );
  }

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint('🔔 Permiso FCM: ${settings.authorizationStatus}');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('📩 Foreground: ${message.notification?.title}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    debugPrint('📩 App abierta desde notificación');
  });
}

Future<void> guardarTokenUsuario({
  required String idUsuario,
  required String rol,
}) async {
  final token = await FirebaseMessaging.instance.getToken();

  if (token == null) return;

  await FirebaseFirestore.instance
      .collection('usuarios')
      .doc('$rol-$idUsuario') // ejemplo: dueno-15
      .set({
    'idUsuario': idUsuario,
    'rol': rol,
    'fcmToken': token,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
