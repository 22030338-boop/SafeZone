import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/router/app_navigator.dart';
import '../../incidents/screens/incidents_screen.dart';
import '../../map/screens/map_screen.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String generalTopic = 'safezone_general';
  static const String incidentsTopic = 'safezone_incidents';
  static const String emergencyTopic = 'safezone_emergency';

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'safezone_notifications',
    'Notificaciones de SafeZone',
    description: 'Alertas e información importante de SafeZone.',
    importance: Importance.high,
  );

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  RemoteMessage? _initialMessage;

  Future<void> initialize() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      'Permiso de notificaciones: ${settings.authorizationStatus}',
    );

    final token = await _messaging.getToken();
    debugPrint('Token FCM: $token');

    await subscribeToDefaultTopics();

    // Mensajes recibidos con la aplicación abierta.
    _foregroundSubscription ??=
        FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );

    // Mensajes abiertos desde segundo plano.
    _openedSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen(
      (message) {
        _navigateFromData(message.data);
      },
    );

    // Mensaje que abrió la aplicación desde estado terminado.
    _initialMessage = await _messaging.getInitialMessage();
  }

  // Procesar el mensaje inicial cuando la interfaz ya esté lista.
  void handleInitialMessage() {
    final message = _initialMessage;
    _initialMessage = null;

    if (message != null) {
      _navigateFromData(message.data);
    }
  }

  // Mostrar notificaciones locales en primer plano.
  Future<void> _showForegroundNotification(
    RemoteMessage message,
  ) async {
    final notification = message.notification;

    if (notification == null) return;

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'safezone_notifications',
        'Notificaciones de SafeZone',
        channelDescription:
            'Alertas e información importante de SafeZone.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title ?? 'SafeZone',
      body: notification.body ?? 'Tienes una nueva notificación.',
      notificationDetails: notificationDetails,
      payload: jsonEncode(message.data),
    );
  }

  // Procesar el toque de una notificación local.
  void _onLocalNotificationTap(
    NotificationResponse response,
  ) {
    final payload = response.payload;

    if (payload == null || payload.isEmpty) {
      _navigateFromData({});
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (error) {
      debugPrint('Error al procesar notificación local: $error');
      _navigateFromData({});
    }
  }

  // Navegar según el tipo de notificación.
  void _navigateFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString();

    final Widget destination;

    if (type == 'emergency') {
      destination = const MapScreen();
    } else {
      // General, incidentes o tipo desconocido.
      destination = const IncidentsScreen();
    }

    final navigator = appNavigatorKey.currentState;

    if (navigator == null) {
      debugPrint('Navegador todavía no disponible.');
      return;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => destination,
      ),
    );
  }

  // Suscripción a los temas principales.
  Future<void> subscribeToDefaultTopics() async {
    await subscribeToTopic(generalTopic);
    await subscribeToTopic(incidentsTopic);
    await subscribeToTopic(emergencyTopic);

    debugPrint('Suscripciones a temas de SafeZone completadas.');
  }

  Future<String?> getDeviceToken() async {
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Suscrito al tema: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Cancelada suscripción al tema: $topic');
  }

  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();

    _foregroundSubscription = null;
    _openedSubscription = null;
  }
}
