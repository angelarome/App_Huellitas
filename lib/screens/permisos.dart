import 'package:permission_handler/permission_handler.dart';

Future<void> solicitarPermisoNotificaciones() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}
