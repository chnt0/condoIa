import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/constants/api_constants.dart';
import '../../shared/services/api_client.dart';

// Handler para mensajes en background (debe ser top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Firebase muestra la notificación automáticamente en background/killed
}

class FirebaseService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Inicializar notificaciones locales (cuando la app está en primer plano)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    // Crear canal de notificaciones Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'condos_channel',
      'Condos Notificaciones',
      description: 'Notificaciones del sistema de condominios',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handler para mensajes en background
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Mostrar notificación local cuando la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'condos_channel',
              'Condos Notificaciones',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  static Future<void> registrarToken(ApiClient apiClient) async {
    try {
      // Pedir permiso (iOS lo requiere, Android lo otorga automáticamente)
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      final plataforma = Platform.isIOS ? 'IOS' : 'ANDROID';

      await apiClient.post(ApiConstants.deviceTokens, {
        'token': token,
        'plataforma': plataforma,
      });
    } catch (e) {
      // No interrumpir el login si falla el registro del token
    }
  }
}
