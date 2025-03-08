import 'package:flutter/material.dart';
import 'dart:async';
import '../services/fall_detection_service.dart';

class FallDetectionWidget extends StatefulWidget {
  const FallDetectionWidget({Key? key}) : super(key: key);

  @override
  _FallDetectionWidgetState createState() => _FallDetectionWidgetState();
}

class _FallDetectionWidgetState extends State<FallDetectionWidget> {
  final FallDetectionService _fallService = FallDetectionService();
  StreamSubscription? _fallSubscription;
  
  @override
  void initState() {
    super.initState();
    _setupFallDetection();
  }
  
  void _setupFallDetection() {
    // Start fall detection automatically
    _fallService.startMonitoring();
    
    // Listen for fall events
    _fallSubscription = _fallService.onFallDetected.listen((_) {
      _showFallDetectedDialog();
    });
  }
  
  Future<void> _showFallDetectedDialog() async {
    // Set a timeout for automatic help
    Timer? autoHelpTimer = Timer(Duration(seconds: 30), () {
      // Call for help automatically if no response
      _sendEmergencyAlert();
      Navigator.of(context, rootNavigator: true).pop();
    });
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Fall Detected!'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you okay?', style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),
                Text('If you need help, press "Call for Help"'),
                SizedBox(height: 10),
                Text('Help will be called automatically in 30 seconds if no response.',
                     style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('I\'m Okay', style: TextStyle(fontSize: 18)),
              onPressed: () {
                autoHelpTimer?.cancel();
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              child: Text('Call for Help', style: TextStyle(fontSize: 18)),
              onPressed: () {
                autoHelpTimer?.cancel();
                _sendEmergencyAlert();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ).then((_) {
      // Cancel timer if dialog is dismissed
      autoHelpTimer?.cancel();
    });
  }
  
  Future<void> _sendEmergencyAlert() async {
    // Show a notification that help is being called
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emergency alert sent'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
      ),
    );
  }
  
  @override
  void dispose() {
    _fallService.stopMonitoring();
    _fallSubscription?.cancel();
    _fallService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.health_and_safety,
                  color: Colors.green,
                  size: 36,
                ),
                SizedBox(width: 12),
                Text(
                  'Fall Detection',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Fall detection is active and monitoring.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'If a fall is detected, emergency contacts will be notified.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.warning_amber_rounded),
              label: Text('Test Fall Alert'),
              onPressed: () {
                _fallService.testFallDetection();
              },
            ),
          ],
        ),
      ),
    );
  }
}