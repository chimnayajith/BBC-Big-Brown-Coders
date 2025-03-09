import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ElderlyDetailPage extends StatefulWidget {
  final User elderly;
  
  const ElderlyDetailPage({
    Key? key,
    required this.elderly,
  }) : super(key: key);

  @override
  State<ElderlyDetailPage> createState() => _ElderlyDetailPageState();
}

class _ElderlyDetailPageState extends State<ElderlyDetailPage> {
  // Setup Method Channel for native communication
  static const MethodChannel _channel = MethodChannel('com.yourapp/sos');
  
  bool isLoading = false;
  String? errorMessage;
  
  // Settings
  bool lowBatteryAlert = false;
  double batteryThreshold = 15.0;
  bool fallDetectionEnabled = true;
  bool cctvDetectionEnabled = true;
  
  // SOS Message and contacts
  final TextEditingController _sosMessageController = TextEditingController(text: 'Emergency SOS alert!');
  final TextEditingController _newEmergencyNumberController = TextEditingController();
  List<String> emergencyContacts = [];
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    // Initialize with elderly's phone as the first emergency contact
    emergencyContacts.add(widget.elderly.phone);
  }
  
  @override
  void dispose() {
    _sosMessageController.dispose();
    _newEmergencyNumberController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Use AuthService to get elderly settings
      final settingsResult = await AuthService.getElderlySettings(widget.elderly.id);
      
      if (settingsResult['success']) {
        final settings = settingsResult['data'];
        setState(() {
          lowBatteryAlert = settings['lowBatteryAlert'] ?? false;
          batteryThreshold = settings['batteryThreshold'] ?? 15.0;
          fallDetectionEnabled = settings['fallDetectionEnabled'] ?? true;
          cctvDetectionEnabled = settings['cctvDetectionEnabled'] ?? true;
          
          // Load emergency contacts if available
          if (settings['emergencyContacts'] != null) {
            emergencyContacts = List<String>.from(settings['emergencyContacts']);
          } else if (!emergencyContacts.contains(widget.elderly.phone)) {
            // Ensure elderly's phone is in emergency contacts
            emergencyContacts.add(widget.elderly.phone);
          }
          
          // Load SOS message if available
          if (settings['sosMessage'] != null) {
            _sosMessageController.text = settings['sosMessage'];
          }
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _saveSettings() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Prepare settings map
      final settingsMap = {
        'lowBatteryAlert': lowBatteryAlert,
        'batteryThreshold': batteryThreshold,
        'fallDetectionEnabled': fallDetectionEnabled,
        'cctvDetectionEnabled': cctvDetectionEnabled,
        'emergencyContacts': emergencyContacts,
        'sosMessage': _sosMessageController.text,
      };
      
      // Use AuthService to update settings
      final result = await AuthService.updateElderlySettings(
        elderlyId: widget.elderly.id,
        settings: settingsMap,
      );
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  // Handle emergency call
  Future<void> _makePhoneCall() async {
    final phoneNumber = widget.elderly.phone;
    
    // Request phone call permission
    var status = await Permission.phone.request();
    if (status.isGranted) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initiating call to $phoneNumber...')),
        );
        
        // Call native method through channel
        final result = await _channel.invokeMethod(
          'makeCall', 
          {'number': phoneNumber}
        );
        
        print("Call result: $result");
      } catch (e) {
        print("Failed to make call: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to make call: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print("Phone permission denied");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission to make phone calls was denied'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }
  
  // Handle SMS sending
  Future<void> _sendSms() async {
    final phoneNumber = widget.elderly.phone;
    
    // Request SMS permission
    var status = await Permission.sms.request();
    if (status.isGranted) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sending message to $phoneNumber...')),
        );
        
        // Call native method through channel
        final result = await _channel.invokeMethod(
          'sendSMS', 
          {
            'number': phoneNumber,
            'message': 'Hello from the Boing caregiver app. How are you doing today?'
          }
        );
        
        print("SMS result: $result");
      } catch (e) {
        print("Failed to send SMS: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print("SMS permission denied");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Permission to send SMS was denied'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    }
  }
  
  // Add new emergency contact
  void _addEmergencyContact() {
    final number = _newEmergencyNumberController.text.trim();
    if (number.isNotEmpty && !emergencyContacts.contains(number)) {
      setState(() {
        emergencyContacts.add(number);
        _newEmergencyNumberController.clear();
      });
    }
  }
  
  // Remove emergency contact
  void _removeEmergencyContact(String number) {
    setState(() {
      emergencyContacts.remove(number);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.elderly.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.person, size: 40, color: Colors.blue),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.elderly.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.phone, size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(widget.elderly.phone),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.email, size: 16, color: Colors.grey),
                                    SizedBox(width: 8),
                                    Text(widget.elderly.email),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Contact buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.call),
                          label: Text('Call'),
                          onPressed: _makePhoneCall,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.message),
                          label: Text('Text'),
                          onPressed: _sendSms,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Alert Settings section
                  Text(
                    'Alert Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  
                  // Battery alert settings
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Low Battery Alert',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    Text(
                                      'Send alert when battery is low',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: lowBatteryAlert,
                                onChanged: (value) {
                                  setState(() {
                                    lowBatteryAlert = value;
                                  });
                                },
                              ),
                            ],
                          ),
                          
                          if (lowBatteryAlert) ...[
                            SizedBox(height: 16),
                            Text('Battery Threshold: ${batteryThreshold.toInt()}%'),
                            Slider(
                              value: batteryThreshold,
                              min: 5,
                              max: 50,
                              divisions: 9,
                              label: '${batteryThreshold.toInt()}%',
                              onChanged: (value) {
                                setState(() {
                                  batteryThreshold = value;
                                });
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // Fall detection setting
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone Fall Detection',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Send alert when phone detects a fall',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: fallDetectionEnabled,
                            onChanged: (value) {
                              setState(() {
                                fallDetectionEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // CCTV fall detection setting
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Camera Fall Detection',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                Text(
                                  'Send alert when camera detects a fall',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: cctvDetectionEnabled,
                            onChanged: (value) {
                              setState(() {
                                cctvDetectionEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Health metrics (placeholder)
                  Text(
                    'Health Metrics',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.favorite, color: Colors.red),
                            title: Text('Heart Rate'),
                            trailing: Text('72 BPM'),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.directions_walk, color: Colors.green),
                            title: Text('Steps Today'),
                            trailing: Text('3,241'),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.battery_full, color: Colors.blue),
                            title: Text('Phone Battery'),
                            trailing: Text('78%'),
                          ),
                          Divider(),
                          ListTile(
                            leading: Icon(Icons.access_time, color: Colors.orange),
                            title: Text('Last Activity'),
                            trailing: Text('12 min ago'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}