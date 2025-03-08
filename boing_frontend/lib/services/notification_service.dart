import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Create notification channels
    const AndroidNotificationChannel fallChannel = AndroidNotificationChannel(
      'fall_alert_channel',
      'Fall Alert Notifications',
      description: 'Urgent alerts when falls are detected',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    
    // Initialize platform settings
    const AndroidInitializationSettings initAndroid = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initSettings = 
        InitializationSettings(android: initAndroid);
    
    // Create the notification channel
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(fallChannel);
    
    // Request notification permission (Android 13+)
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    // Initialize
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        print('NOTIFICATION: User responded to notification: ${details.payload}');
      },
    );
    
    _initialized = true;
  }
  
  // Show a fall detection notification
  static Future<void> showFallAlert() async {
    await initialize();
    
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'fall_alert_channel',
        'Fall Alert Notifications',
        channelDescription: 'Urgent alerts when falls are detected',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'FALL DETECTED',
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        ongoing: true,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      );
      
      const NotificationDetails notificationDetails = 
          NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        999, // Unique ID
        'FALL DETECTED - EMERGENCY',
        'Open app immediately or call for help',
        notificationDetails,
      );
      
      print('NOTIFICATION: Fall alert shown successfully');
    } catch (e) {
      print('NOTIFICATION ERROR: Failed to show notification: $e');
    }
  }
}