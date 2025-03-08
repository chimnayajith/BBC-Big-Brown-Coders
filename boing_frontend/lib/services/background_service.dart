
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: DarwinInitializationSettings(),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap action
      print("Notification Tapped: ${response.payload}");
    },
  );
}



Future<void> initializeBackgroundService() async {

  final service = FlutterBackgroundService();
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'fall_detection_channel',
    'Fall Detection Service',
    description: 'Monitors device motion to detect falls',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'fall_detection_channel',
      initialNotificationTitle: 'Fall Detection Service',
      initialNotificationContent: 'Running in background',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  return preferences.getBool('fall_detection_enabled') ?? false;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  double fallThreshold = 2.5;
  double impactThreshold = 15.0;
  double stillnessThreshold = 0.5;

  bool inPotentialFall = false;
  bool isProcessingFall = false;
  DateTime? lastFallDetected;
  List<double> recentAccelerations = [];

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Future<void> detectFall() async {
    lastFallDetected = DateTime.now();
    final FlutterLocalNotificationsPlugin notificationsPlugin =
        FlutterLocalNotificationsPlugin();

flutterLocalNotificationsPlugin.show(
  999,
  'Fall Detected!',
  'Tap for emergency options',
  const NotificationDetails(
    android: AndroidNotificationDetails(
      'fall_detection_channel',
      'Fall Detection Alerts',
      channelDescription: 'High priority alerts for fall detection',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true, 
      ticker: 'Fall detected alert',
    ),
  ),
);


  }

  accelerometerEvents.listen((event) async {
    if (isProcessingFall) return;

    final currentAcceleration =
        sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));

    recentAccelerations.add(currentAcceleration);
    if (recentAccelerations.length > 10) {
      recentAccelerations.removeAt(0);
    }

    service.invoke(
      'updateAcceleration',
      {'acceleration': currentAcceleration.toStringAsFixed(2)},
    );

    if (!inPotentialFall && currentAcceleration < fallThreshold) {
      inPotentialFall = true;
      Future.delayed(Duration(milliseconds: 1000), () {
        if (inPotentialFall) inPotentialFall = false;
      });
    }

    if (inPotentialFall && currentAcceleration > impactThreshold) {
      inPotentialFall = false;
      if (lastFallDetected != null &&
          DateTime.now().difference(lastFallDetected!).inSeconds < 10) return;
      isProcessingFall = true;
      Future.delayed(Duration(milliseconds: 500), () {
        double avgRecentAccel = recentAccelerations.isNotEmpty
            ? recentAccelerations.reduce((a, b) => a + b) /
                recentAccelerations.length
            : 9.8;
        if (avgRecentAccel > (stillnessThreshold - 0.1) &&
            avgRecentAccel < (9.8 + stillnessThreshold)) {
          detectFall();
        }
        Future.delayed(Duration(seconds: 3), () {
          isProcessingFall = false;
        });
      });
    }
  });
}

class FallDetectionManager {
  static Future<void> startService() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fall_detection_enabled', true);
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fall_detection_enabled', false);
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }
}