import 'dart:convert';
import 'package:http/http.dart' as http;
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
  
  // Handle emergency SOS (only for elderly users)
  static Future<Map<String, dynamic>> sendSOS({String? message}) async {
    try {
      // Get auth token and user data
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userData = prefs.getString('user_data');
      
      if (token == null || userData == null) {
        return {
          'success': false,
          'message': 'Not authenticated',
        };
      }
      
      // Create SOS data
      final sosData = {
        'message': message ?? 'Emergency SOS alert!',
        'location': {
          'latitude': 0.0, // Replace with actual location
          'longitude': 0.0, // Replace with actual location
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final response = await http.post(
        Uri.parse('http://$apiURL/sos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(sosData),
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
          'message': responseData['message'] ?? 'Failed to send SOS',
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
}