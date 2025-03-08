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
  
  // Function to handle fall detection
  Future<void> detectFall() async {
    lastFallDetected = DateTime.now();
    
    // Show notification
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
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
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
    
    // Send data to server if needed
    // try {
    //   final response = await http.post(
    //     Uri.parse('http://$apiURL$fallDetectionEndpoint'),
    //     body: {
    //       'timestamp': DateTime.now().toIso8601String(),
    //       'event_type': 'fall_detected',
    //     },
    //   );
      
    //   if (response.statusCode == 200) {
    //     print("Fall reported successfully to server");
    //   } else {
    //     print("Failed to report fall: ${response.statusCode}");
    //   }
    // } catch (e) {
    //   print("Error reporting fall: $e");
    // }
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
    
    // Update service with current data
    service.invoke(
      'updateAcceleration',
      {'acceleration': currentAcceleration.toStringAsFixed(2)},
    );
    
    // Free-fall detection (acceleration significantly below normal gravity)
    if (!inPotentialFall && currentAcceleration < fallThreshold) {
      print("Potential free-fall detected: $currentAcceleration (below threshold)");
      inPotentialFall = true;
      
      // Look for impact within the next second
      Future.delayed(Duration(milliseconds: 1000), () {
        if (inPotentialFall) {
          inPotentialFall = false;
          print("No impact detected after potential free-fall");
        }
      });
    }
    
    // Impact detection (after potential free-fall)
    if (inPotentialFall && currentAcceleration > impactThreshold) {
      print("Impact detected: $currentAcceleration");
      inPotentialFall = false;
      
      // Check for cooldown period
      if (lastFallDetected != null && 
          DateTime.now().difference(lastFallDetected!).inSeconds < 10) {
        print("Within cooldown period - ignoring");
        return;
      }
      
      isProcessingFall = true;
      
      // Wait a moment and check for post-impact stillness
      Future.delayed(Duration(milliseconds: 500), () {
        // Calculate average recent acceleration
        double avgRecentAccel = recentAccelerations.isNotEmpty 
            ? recentAccelerations.reduce((a, b) => a + b) / recentAccelerations.length 
            : 9.8;
        
        print("Confirming fall. Recent average acceleration: $avgRecentAccel");
        
        // If device is relatively still after impact, confirm as fall
        if (avgRecentAccel > (stillnessThreshold - 0.1) && avgRecentAccel < (9.8 + stillnessThreshold)) {
          detectFall();
        } else {
          print("False alarm - no consistent stillness after impact");
        }
        
        // Reset processing flag after a delay
        Future.delayed(Duration(seconds: 3), () {
          isProcessingFall = false;
        });
      });
    }
  });
  
  // Keep service alive with periodic updates
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "Fall Detection Active",
          content: "Monitoring for falls",
        );
      }
    }
    
    // Check if service should be running
    SharedPreferences preferences = await SharedPreferences.getInstance();
    final isEnabled = preferences.getBool('fall_detection_enabled') ?? true;
    
    if (!isEnabled) {
      timer.cancel();
      service.stopSelf();
    }
    
    // Publish current status
    service.invoke(
      'update',
      {
        'monitoring': true,
        'lastCheck': DateTime.now().toIso8601String(),
      },
    );
  });
}

// To be called from your main.dart
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