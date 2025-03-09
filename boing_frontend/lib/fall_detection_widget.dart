import 'package:flutter/material.dart';
import 'dart:async';
import '../services/auth_service.dart';

class FallDetectionDialog extends StatefulWidget {
  const FallDetectionDialog({Key? key}) : super(key: key);

  @override
  State<FallDetectionDialog> createState() => _FallDetectionDialogState();
}

class _FallDetectionDialogState extends State<FallDetectionDialog> {
  int _countdown = 30;
  Timer? _timer;
  bool _sosSent = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          if (!_sosSent) {
            _sendSOS();
          }
        }
      });
    });
  }

  Future<void> _sendSOS() async {
    if (_sosSent) return;
    
    setState(() => _sosSent = true);
    
    try {
      final result = await AuthService.sendSOS(
        message: "EMERGENCY! A fall was detected. This is an automatic alert.",
      );
      
      if (result['success']) {
        print("Auto-SOS sent successfully");
      } else {
        print("Failed to send auto-SOS: ${result['message']}");
      }
    } catch (e) {
      print("Error sending auto-SOS: $e");
    }
    
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
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
              '$_countdown seconds',
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
              _timer?.cancel();
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Send SOS Now', style: TextStyle(fontSize: 18)),
            onPressed: () => _sendSOS(),
          ),
        ],
      ),
    );
  }
}

// Show dialog function to call from anywhere
void showFallDetectionDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => FallDetectionDialog(),
  );
}