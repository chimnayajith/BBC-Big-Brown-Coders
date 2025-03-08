import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

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
    _isMonitoring = false;
    _logDebug("Fall detection monitoring stopped");
  }
  
  // Handle fall detection
  Future<void> _detectFall() async {
    _lastFallDetected = DateTime.now();
    _logDebug("FALL DETECTED!");
    
    // Notify listeners about the fall
    _fallDetectedController.add(null);
    
    // Report fall to server if needed (uncomment when server is ready)
    // try {
    //   final response = await http.post(
    //     Uri.parse('http://$apiURL$fallDetectionEndpoint'),
    //     body: {
    //       'timestamp': DateTime.now().toIso8601String(),
    //       'acceleration': _currentAcceleration.toString(),
    //     },
    //   );
      
    //   if (response.statusCode == 200) {
    //     _logDebug("Fall reported successfully to server");
    //   } else {
    //     _logDebug("Failed to report fall: ${response.statusCode}");
    //   }
    // } catch (e) {
    //   _logDebug("Error reporting fall: $e");
    // }
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
    _debugStreamController.close();
    _fallDetectedController.close();
  }
}