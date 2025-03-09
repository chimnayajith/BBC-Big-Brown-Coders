import 'package:boing_frontend/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'services/background_service.dart';
import 'services/notification_service.dart';
import 'routes/app_routes.dart';
import 'models/user.dart';
import 'services/auth_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure Flutter initialization is complete
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeNotifications();
  await requestPermissions();
  
  // Initialize and start the background service
  await initializeBackgroundService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Senior Care App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      routes: AppRoutes.routes,
      initialRoute: AppRoutes.home,
    );
  }
}