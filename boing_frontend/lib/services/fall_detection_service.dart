import 'dart:async';
import 'dart:math';
import 'package:boing_frontend/fall_detection_widget.dart';
import 'package:boing_frontend/services/auth_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FallDetectionService {
  // Lower thresholds for testing with phone drops
  double _fallThreshold = 2.5;       // Lower for detecting free-fall
  double _impactThreshold = 15.0;    // For detecting impact
  double _stillnessThreshold = 0.5;  // For detecting post-fall stillness
  
  // Streaming subscriptions
  StreamSubscription? _accelerometerSubscription;
  
  // State variables
  bool _isMonitoring = false;
  bool _isProcessingFall = false;
  bool _inPotentialFall = false;
  DateTime? _lastFallDetected;
  
  // Debug stream controller
  final _debugStreamController = StreamController<String>.broadcast();
  Stream<String> get debugStream => _debugStreamController.stream;
  
  // Fall detection stream controller
  final _fallDetectedController = StreamController<void>.broadcast();
  Stream<void> get onFallDetected => _fallDetectedController.stream;
  
  // Motion data
  double _currentAcceleration = 0.0;
  List<double> _recentAccelerations = [];
  
  // Navigation key for accessing the current context
  final GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();
  
  // Notification plugin
  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  // Global SOS timer that can be canceled from anywhere
  Timer? _sosTimer;

  // Constructor
  FallDetectionService() {
    _initializeNotifications();
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    // Define the notification details
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    // Initialize with callback when notification is tapped
    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap - show the dialog
        if (details.payload == 'fall_detected') {
          _showFallDialogFromNotification();
        }
      },
    );
    
    // Create high importance notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'fall_detection_channel',
      'Fall Detection',
      description: 'For fall detection alerts',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    );
    
    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Start monitoring for falls
  void startMonitoring() {
    if (_isMonitoring) return;
    
    try {
      _isMonitoring = true;
      _logDebug("Fall detection monitoring started");
      
      // Use regular accelerometerEvents to include gravity for better fall detection
      _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
        if (_isProcessingFall) return;
        
        // Calculate total acceleration magnitude
        _currentAcceleration = sqrt(pow(event.x, 2) + pow(event.y, 2) + pow(event.z, 2));
        
        // Keep a small history of recent acceleration values
        _recentAccelerations.add(_currentAcceleration);
        if (_recentAccelerations.length > 10) {
          _recentAccelerations.removeAt(0);
        }
        
        // Free-fall detection (acceleration significantly below normal gravity)
        if (!_inPotentialFall && _currentAcceleration < _fallThreshold) {
          _logDebug("Potential free-fall detected: $_currentAcceleration (below threshold)");
          _inPotentialFall = true;
          
          // Look for impact within the next second
          Future.delayed(Duration(milliseconds: 1000), () {
            if (_inPotentialFall) {
              _inPotentialFall = false;
              _logDebug("No impact detected after potential free-fall");
            }
          });
        }
        
        // Impact detection (after potential free-fall)
        if (_inPotentialFall && _currentAcceleration > _impactThreshold) {
          _logDebug("Impact detected: $_currentAcceleration");
          _inPotentialFall = false;
          
          // Check for cooldown period
          if (_lastFallDetected != null && 
              DateTime.now().difference(_lastFallDetected!).inSeconds < 10) {
            _logDebug("Within cooldown period - ignoring");
            return;
          }
          
          _isProcessingFall = true;
          
          // Wait a moment and check for post-impact stillness
          Future.delayed(Duration(milliseconds: 500), () {
            _confirmFall();
          });
        }
      });
    } catch (e) {
      _isMonitoring = false;
      _logDebug("Error starting monitoring: $e");
    }
  }
  
  // Confirm fall by checking for post-impact stillness
  void _confirmFall() {
    // Calculate average recent acceleration
    double avgRecentAccel = _recentAccelerations.isNotEmpty 
        ? _recentAccelerations.reduce((a, b) => a + b) / _recentAccelerations.length 
        : 9.8;
    
    _logDebug("Confirming fall. Recent average acceleration: $avgRecentAccel");
    
    // If device is relatively still after impact, confirm as fall
    if (avgRecentAccel > (_stillnessThreshold - 0.1) && avgRecentAccel < (9.8 + _stillnessThreshold)) {
      _detectFall();
    } else {
      _logDebug("False alarm - no consistent stillness after impact");
    }
    
    // Reset processing flag after a delay
    Future.delayed(Duration(seconds: 3), () {
      _isProcessingFall = false;
    });
  }
  
  // Log debug messages
  void _logDebug(String message) {
    print("FallDetection: $message");
    _debugStreamController.add(message);
  }
  
  // Stop monitoring
  void stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _sosTimer?.cancel();
    _isMonitoring = false;
    _logDebug("Fall detection monitoring stopped");
  }
  
  // Show a high priority notification when a fall is detected
  Future<void> _showFallNotification() async {
    // Cancel any existing notification first
    await notificationsPlugin.cancel(0);
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'fall_detection_channel',
      'Fall Detection',
      channelDescription: 'For fall detection alerts',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ticker: 'Fall detected!',
      category: AndroidNotificationCategory.alarm,
      autoCancel: false,
      ongoing: true,
    );

    await notificationsPlugin.show(
      0,
      'Fall Detected!',
      'Tap to respond or SOS will be sent in 30 seconds',
      const NotificationDetails(android: androidDetails),
      payload: 'fall_detected',
    );
  }
  
  // Handle fall detection
  Future<void> _detectFall() async {
    _lastFallDetected = DateTime.now();
    _logDebug("FALL DETECTED!");
    
    // Start the SOS timer first (will be canceled if user responds)
    startSOSTimer();
    
    // Try to show dialog if app is in foreground
    BuildContext? contextToUse = navigationKey.currentContext;
    
    if (contextToUse != null && Navigator.of(contextToUse).canPop()) {
      _logDebug("App in foreground, showing dialog");
      await notificationsPlugin.cancel(0); // Cancel any existing notification
      _showFallDialog(contextToUse);
    } else {
      _logDebug("App not in foreground, showing notification");
      await _showFallNotification();
    }
    
    // Notify listeners about the fall
    _fallDetectedController.add(null);
    
    // Also report fall to server for logging purposes
    _reportFallToServer();
  }
  
  // Start the timer for automatic SOS
  void startSOSTimer() {
    // Cancel any existing timer first
    _sosTimer?.cancel();
    
    _sosTimer = Timer(Duration(seconds: 30), () {
      _sendAutomaticSOS();
    });
    
    _logDebug("SOS timer started - 30 seconds until automatic SOS");
  }
  
  // Cancel the SOS timer
  void cancelSOSTimer() {
    if (_sosTimer != null && _sosTimer!.isActive) {
      _sosTimer!.cancel();
      _sosTimer = null;
      _logDebug("SOS timer canceled");
    }
  }
  
  // Show fall dialog when notification is tapped
  void _showFallDialogFromNotification() {
    BuildContext? contextToUse = navigationKey.currentContext;
    
    if (contextToUse != null) {
      _logDebug("Showing fall dialog from notification tap");
      // Cancel the notification when showing dialog
      notificationsPlugin.cancel(0);
      _showFallDialog(contextToUse);
    } else {
      _logDebug("No context available after notification tap");
      // If we still can't get context, make sure the SOS timer is running
      if (_sosTimer == null || !_sosTimer!.isActive) {
        _logDebug("Restarting SOS timer from notification tap");
        startSOSTimer();
      }
    }
  }
  
  // Show the fall detection dialog
  void _showFallDialog(BuildContext context) {
    // Cancel any existing notification
    notificationsPlugin.cancel(0);
    
    // Create a stateful dialog with countdown
    int countdown = 30;
    
    // If SOS timer is already running, restart it to ensure sync with dialog
    startSOSTimer();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Create a timer that updates the UI
            Timer? countdownTimer;
            countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
              setState(() {
                if (countdown > 0) {
                  countdown--;
                } else {
                  timer.cancel();
                  // Time's up - send SOS
                  _sendAutomaticSOS();
                  Navigator.of(dialogContext).pop();
                }
              });
            });
            
            return WillPopScope(
              onWillPop: () async => false, // Prevent back button dismiss
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                    SizedBox(width: 10),
                    Text('Fall Detected!'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Are you okay?',
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'SOS will be sent automatically in:',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '$countdown seconds',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: Text("I'm Okay", style: TextStyle(fontSize: 18)),
                    onPressed: () {
                      countdownTimer?.cancel();
                      cancelSOSTimer();
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text('Send SOS Now', style: TextStyle(fontSize: 18)),
                    onPressed: () {
                      countdownTimer?.cancel();
                      cancelSOSTimer();
                      _sendManualSOS();
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      // Clean up when dialog is dismissed
      cancelSOSTimer();
    });
  }
  
  // Send SOS automatically (after timeout)
  Future<void> _sendAutomaticSOS() async {
    _logDebug("Sending automatic SOS after fall detection timeout");
    
    try {
      final result = await AuthService.sendSOS(
        message: "EMERGENCY! A fall was detected. This is an automatic alert."
      );
      
      if (result['success']) {
        _logDebug("Automatic SOS sent successfully");
      } else {
        _logDebug("Failed to send automatic SOS: ${result['message']}");
      }
    } catch (e) {
      _logDebug("Error sending automatic SOS: $e");
    }
  }
  
  // Send SOS manually (user pressed button)
  Future<void> _sendManualSOS() async {
    _logDebug("Sending manual SOS after fall detection");
    
    try {
      final result = await AuthService.sendSOS(
        message: "EMERGENCY! A fall was detected. I need help!"
      );
      
      if (result['success']) {
        _logDebug("Manual SOS sent successfully");
      } else {
        _logDebug("Failed to send manual SOS: ${result['message']}");
      }
    } catch (e) {
      _logDebug("Error sending manual SOS: $e");
    }
  }

  // Report fall to server
  Future<void> _reportFallToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');
      
      if (token == null || userData == null) {
        _logDebug("Cannot report fall: Not authenticated");
        return;
      }
      
      final user = jsonDecode(userData);
      
      final response = await http.post(
        Uri.parse('http://$apiURL/fall-detection/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': user['id'],
          'timestamp': DateTime.now().toIso8601String(),
          'acceleration': _currentAcceleration,
          'location': 'Unknown', // Add location tracking if available
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _logDebug("Fall reported successfully to server");
      } else {
        _logDebug("Failed to report fall: ${response.statusCode}");
      }
    } catch (e) {
      _logDebug("Error reporting fall: $e");
    }
  }
  
  // For testing - force a fall detection
  void testFallDetection() {
    _logDebug("SIMULATING FALL DETECTION");
    _detectFall();
  }
  
  // Expose current acceleration value for debugging
  double get currentAcceleration => _currentAcceleration;
  
  // Check if currently monitoring
  bool get isMonitoring => _isMonitoring;
  
  // Dispose resources
  void dispose() {
    stopMonitoring();
    _sosTimer?.cancel();
    _debugStreamController.close();
    _fallDetectedController.close();
  }
}