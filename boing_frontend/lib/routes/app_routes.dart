import 'package:boing_frontend/screens/add_elderly_screen.dart';
import 'package:boing_frontend/screens/home_page.dart';
import 'package:boing_frontend/screens/login_screen.dart';
import 'package:flutter/material.dart';
import '../screens/caregiver_registration_screen.dart';
// Import your other screens here

class AppRoutes {
  static const String home = '/';
  static const String register = '/register';
  static const String login = '/login';
  static const String addElderly = '/addElderly';
  static const String elderlyDetail = '/elderly-detail';
  
  static Map<String, WidgetBuilder> routes = {
    home: (context) => const HomePage(),
    register: (context) => const CaregiverRegistrationScreen(),
    login: (context) => const LoginScreen(),
    addElderly: (context) => const AddElderlyScreen()
    // Add other routes here
  };
}