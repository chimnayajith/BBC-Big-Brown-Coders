// Add to pubspec.yaml:
// dependencies:
//   flutter_background_service: ^2.5.0
//   flutter_background_service_android: ^3.0.3
//   flutter_background_service_ios: ^2.4.0
//   flutter_local_notifications: ^9.1.5
//   sensors_plus: ^latest_version
//   http: ^latest_version

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:boing_frontend/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

// Initialize background service
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'fall_detection_channel',
    'Fall Detection Service',
    description: 'Monitors device motion to detect falls',
    importance: Importance.high,
  );
  
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
      
  await flutterLocalNotificationsPlugin
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
  
  // Start the service
  service.startService();
}

// For iOS background processing
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  // iOS background tasks have limited time, so do minimal work
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.reload();
  final isFallDetectionEnabled = preferences.getBool('fall_detection_enabled') ?? false;
  
  return isFallDetectionEnabled;
}

// Main background service function
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  
  // Initialize notifications early
  await NotificationService.initialize();
  
  print('BACKGROUND SERVICE: Started');
  
  // Fall detection parameters
  double fallThreshold = 2.5;
  double impactThreshold = 15.0;
  double stillnessThreshold = 0.5;
  
  // State variables
  bool inPotentialFall = false;
  bool isProcessingFall = false;
  DateTime? lastFallDetected;
  List<double> recentAccelerations = [];
  
  // Setup for periodic logging to keep service alive
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  
  service.on('stopService').listen((event) {
    service.stopSelf();
  });
  
  // Test function for verification
  service.on('testFall').listen((event) async {
    print('BACKGROUND SERVICE: Testing fall alert notification');
    await NotificationService.showFallAlert();
  });
  
  // Function to handle fall detection
  Future<void> detectFall() async {
    lastFallDetected = DateTime.now();
    print('BACKGROUND SERVICE: FALL DETECTED! Showing notification');
    
    // Use the standalone notification service
    await NotificationService.showFallAlert();
  }
  
  // Set up accelerometer subscription
  accelerometerEvents.listen((AccelerometerEvent event) async {
    if (isProcessingFall) return;
    
    // Calculate total acceleration magnitude
    final currentAcceleration = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
    
    // Keep a small history of recent acceleration values
    recentAccelerations.add(currentAcceleration);
    if (recentAccelerations.length > 10) {
      recentAccelerations.removeAt(0);
    }
    
    // Print occasionally for debugging
    if (DateTime.now().second % 10 == 0) {
      print('BACKGROUND SERVICE: Current acceleration: $currentAcceleration');
    }
    
    // Free-fall detection (acceleration significantly below normal gravity)
    if (!inPotentialFall && currentAcceleration < fallThreshold) {
      print("BACKGROUND SERVICE: Potential free-fall detected: $currentAcceleration (below threshold)");
      inPotentialFall = true;
      
      // Look for impact within the next second
      Future.delayed(Duration(milliseconds: 1000), () {
        if (inPotentialFall) {
          inPotentialFall = false;
          print("BACKGROUND SERVICE: No impact detected after potential free-fall");
        }
      });
    }
    
    // Impact detection (after potential free-fall)
    if (inPotentialFall && currentAcceleration > impactThreshold) {
      print("BACKGROUND SERVICE: Impact detected: $currentAcceleration");
      inPotentialFall = false;
      
      // Check for cooldown period
      if (lastFallDetected != null && 
          DateTime.now().difference(lastFallDetected!).inSeconds < 10) {
        print("BACKGROUND SERVICE: Within cooldown period - ignoring");
        return;
      }
      
      isProcessingFall = true;
      
      // Process the fall detection immediately
      detectFall();
      
      // Reset processing flag after a delay
      Future.delayed(Duration(seconds: 10), () {
        isProcessingFall = false;
        print("BACKGROUND SERVICE: Ready to detect falls again");
      });
    }
  });
  
  // Keep service alive with periodic updates
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Fall Detection Active",
        content: "Monitoring at: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
      );
    }
  });
}