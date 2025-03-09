import 'dart:convert';
import 'package:boing_frontend/models/user.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Register a new user
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? caregiverPhone, // Optional for elderly users only
  }) async {
    try {
      // Prepare registration data based on role
      final Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      };
      
      // If this is an elderly user and caregiver phone is provided
      if (role == 'Elderly' && caregiverPhone != null) {
        userData['caregiver_phone'] = caregiverPhone;
      }
      
      final response = await http.post(
        Uri.parse('http://$apiURL/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
  
  // Login user
// Login user
static Future<Map<String, dynamic>> login({
  required String email,
  required String password,
}) async {
  try {
    print('Attempting login for: $email');
    
    final response = await http.post(
      Uri.parse('http://$apiURL/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    print('Login response status: ${response.statusCode}');
    print('Login response body: ${response.body}');
    
    // Handle empty response
    if (response.body.isEmpty) {
      return {
        'success': false,
        'message': 'Server returned empty response',
      };
    }
    
    try {
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        // Extract token
        final token = responseData['token']?.toString() ?? '';
        
        // Normalize user data to ensure all values are strings
        Map<String, dynamic> userData;
        if (responseData['user'] != null && responseData['user'] is Map) {
          userData = Map<String, dynamic>.from(responseData['user']);
          
          // Convert any numeric values to strings to prevent type errors
          userData.forEach((key, value) {
            if (value != null) {
              userData[key] = value.toString();
            }
          });
          
          print('Normalized user data: $userData');
        } else {
          userData = {'error': 'No user data found'};
          print('Warning: No user data in response');
        }
        
        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));
        await prefs.setString('auth_token', token);
        
        return {
          'success': true,
          'data': userData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      print('JSON parsing error: $e');
      return {
        'success': false,
        'message': 'Error processing server response: $e',
      };
    }
  } catch (e) {
    print('Network or other error: $e');
    return {
      'success': false,
      'message': 'Connection error: $e',
    };
  }
}
  
  // Add an elderly user (only for caregivers)
  static Future<Map<String, dynamic>> addElderly({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? caregiverPhone, // Will be automatically set to the caregiver's phone
  }) async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');
      
      if (token == null || userData == null) {
        return {
          'success': false,
          'message': 'You must be logged in to add an elderly user',
        };
      }
      
      // Parse current user data to get phone number
      final currentUser = jsonDecode(userData);
      final currentPhone = currentUser['phone'];

      final response = await http.post(
        Uri.parse('http://$apiURL/register/'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': 'elderly',
          'emergency_contact': caregiverPhone ?? currentPhone,
        }),
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to add elderly user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
  
  // List all elderly users associated with the caregiver
  static Future<Map<String, dynamic>> getElderlyUsers() async {
    try {
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      final response = await http.get(
        Uri.parse('http://$apiURL/caregiver/elderly/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get elderly users',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: $e',
      };
    }
  }
    
  // Check if user is logged in and get current user data
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      final token = prefs.getString('auth_token');
      
      if (userData == null || token == null) {
        return {
          'success': false,
          'message': 'Not logged in',
        };
      }
      
      return {
        'success': true,
        'data': jsonDecode(userData),
        'token': token,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error retrieving user data',
      };
    }
  }
  
  // Logout user
  static Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.remove('auth_token');
      return true;
    } catch (e) {
      return false;
    }
  }

// Update elderly settings
static Future<Map<String, dynamic>> updateElderlySettings({
  required String elderlyId,
  required Map<String, dynamic> settings,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }

    // Clean up settings before sending
    final Map<String, dynamic> cleanSettings = {
      'elderly_id': elderlyId, // Add the elderly ID to the request body
    };
    
    // Only include valid fields that the API expects
    if (settings.containsKey('lowBatteryAlert')) {
      cleanSettings['low_battery_alert'] = settings['lowBatteryAlert'];
    }
    
    if (settings.containsKey('batteryThreshold')) {
      cleanSettings['battery_threshold'] = settings['batteryThreshold'].toInt();
    }
    
    if (settings.containsKey('fallDetectionEnabled')) {
      cleanSettings['fall_detection_enabled'] = settings['fallDetectionEnabled'];
    }
    
    if (settings.containsKey('cctvDetectionEnabled')) {
      cleanSettings['cctv_detection_enabled'] = settings['cctvDetectionEnabled'];
    }
    
    if (settings.containsKey('emergencyContacts')) {
      cleanSettings['emergency_contacts'] = settings['emergencyContacts'];
    }
    
    if (settings.containsKey('sosMessage')) {
      cleanSettings['sos_message'] = settings['sosMessage'];
    }
    
    print('Sending settings to API: $cleanSettings');
    
    // Create headers with auth token
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    // Use the same URL pattern as in getElderlySettings
    final response = await http.patch(
      Uri.parse('http://$apiURL/caregiver/edit-config/'),
      headers: headers,
      body: jsonEncode(cleanSettings),
    );
    
    print('Update elderly settings response status: ${response.statusCode}');
    print('Update elderly settings response body: ${response.body}');
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'data': response.body.isNotEmpty ? jsonDecode(response.body) : {},
      };
    } else {
      String errorMessage = 'Failed to update elderly settings (${response.statusCode})';
      try {
        // Try to extract a more specific error message from the response
        final responseBody = response.body;
        if (responseBody.contains('IntegrityError')) {
          errorMessage = 'Database integrity error. Please check your inputs.';
        }
      } catch (_) {}
      
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  } catch (e) {
    print('Error updating elderly settings: $e');
    return {
      'success': false,
      'message': 'Error: $e',
    };
  }
}

// Get elderly settings
static Future<Map<String, dynamic>> getElderlySettings(String elderlyId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    if (token == null) {
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }
    
    // Create headers with auth token
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    final response = await http.get(
      Uri.parse('http://$apiURL/caregiver/edit-config/?elderly_id=$elderlyId'),
      headers: headers,
    );
    
    print('Get elderly settings response status: ${response.statusCode}');
    print('Get elderly settings response body: ${response.body}');
    
    if (response.statusCode == 200) {
      // Try to parse the response
      final responseData = jsonDecode(response.body);
      
      // Convert API field names to our app's field names
      final Map<String, dynamic> settings = {
        'lowBatteryAlert': responseData['low_battery_alert'] ?? false,
        'batteryThreshold': responseData['battery_threshold'] ?? 15.0,
        'fallDetectionEnabled': responseData['fall_detection_enabled'] ?? true,
        'cctvDetectionEnabled': responseData['cctv_detection_enabled'] ?? true,
        'emergencyContacts': responseData['emergency_contacts'] ?? [elderlyId],
        'sosMessage': responseData['sos_message'] ?? 'Emergency! I need help!',
      };
      
      return {
        'success': true,
        'data': settings,
      };
    } else {
      // On error, return default settings
      return {
        'success': true,
        'data': {
          'lowBatteryAlert': false,
          'batteryThreshold': 15.0,
          'fallDetectionEnabled': true,
          'cctvDetectionEnabled': true,
          'emergencyContacts': [elderlyId],
          'sosMessage': 'Emergency! I need help!',
        },
      };
    }
  } catch (e) {
    print('Error getting elderly settings: $e');
    // Return default settings on error
    return {
      'success': true,
      'data': {
        'lowBatteryAlert': false,
        'batteryThreshold': 15.0,
        'fallDetectionEnabled': true,
        'cctvDetectionEnabled': true,
        'emergencyContacts': [elderlyId],
        'sosMessage': 'Emergency! I need help!',
      },
    };
  }
}

// Handle emergency SOS (only for elderly users)
static Future<Map<String, dynamic>> sendSOS({String? message}) async {
  // Setup Method Channel for native communication
  const MethodChannel _channel = MethodChannel('com.yourapp/sos');
  
  try {
    print("Starting SOS process");
    // Get auth token and user data
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    
    if (userData == null) {
      print("No user data found in prefs");
      return {
        'success': false,
        'message': 'Not authenticated',
      };
    }
    
    final user = jsonDecode(userData);
    print("User data retrieved: ${user.toString()}");
    
    // Check permissions for SMS and phone
    var smsPermission = await Permission.sms.request();
    var phonePermission = await Permission.phone.request();
    
    if (!smsPermission.isGranted || !phonePermission.isGranted) {
      return {
        'success': false,
        'message': 'SOS requires SMS and phone permissions',
      };
    }
    
    // Initialize emergency contacts list
    List<String> emergencyContacts = [];
    
    // IMPORTANT: Display all available fields in user data for debugging
    user.forEach((key, value) {
      print("User data field: $key = $value");
    });
    
    // Check all possible field names for emergency contact
    if (user['emergency_contact'] != null && user['emergency_contact'].toString().isNotEmpty) {
      String emergencyContact = user['emergency_contact'].toString();
      emergencyContacts.add(emergencyContact);
      print("Found emergency_contact: $emergencyContact");
    } 
    else if (user['caregiver_phone'] != null && user['caregiver_phone'].toString().isNotEmpty) {
      String caregiverPhone = user['caregiver_phone'].toString();
      emergencyContacts.add(caregiverPhone);
      print("Found caregiver_phone: $caregiverPhone");
    }
    else if (user['caregiver'] != null && user['caregiver']['phone'] != null) {
      // Try nested caregiver object
      String caregiverPhone = user['caregiver']['phone'].toString();
      emergencyContacts.add(caregiverPhone);
      print("Found nested caregiver phone: $caregiverPhone");
    }
    else {
      print("No emergency contact found in user data, checking hard-coded default");
      // For testing purposes, add a default emergency contact
      // REPLACE THIS WITH YOUR TEST PHONE NUMBER
      emergencyContacts.add("1234567890");
      print("Using hardcoded default number for testing");
    }
    
    // Get SOS message
    String sosMessage = message ?? "EMERGENCY! I need immediate help!";
    
    print('Sending SOS to ${emergencyContacts.length} contacts: $emergencyContacts');
    
    // Send SMS to emergency contacts
    bool smsSent = false;
    for (String contact in emergencyContacts) {
      if (contact == null || contact.isEmpty) {
        print("Skipping empty contact");
        continue;
      }
      
      try {
        print("Attempting to send SMS to: $contact");
        await _channel.invokeMethod('sendSMS', {
          'number': contact,
          'message': sosMessage,
        });
        smsSent = true;
        print('SMS sent to $contact');
      } catch (e) {
        print('Failed to send SMS to $contact: $e');
      }
    }
    
    // Try to make a call to the first emergency contact
    String callResult = 'No call made';
    if (emergencyContacts.isNotEmpty && emergencyContacts.first != null && emergencyContacts.first.isNotEmpty) {
      try {
        print("Attempting to call: ${emergencyContacts.first}");
        callResult = await _channel.invokeMethod('makeCall', {
          'number': emergencyContacts.first,
        });
        print('Call initiated to ${emergencyContacts.first}');
      } catch (e) {
        print('Failed to make call: $e');
        callResult = 'Call failed: $e';
      }
    } else {
      print("No valid contact to call");
    }

    return {
      'success': smsSent,
      'message': smsSent ? 'Emergency alert sent' : 'Failed to send alert',
      'call_status': callResult,
      'contacts': emergencyContacts,
    };
  } catch (e) {
    print('SOS error: $e');
    return {
      'success': false,
      'message': 'Error sending emergency alert: $e',
    };
  }
}

}