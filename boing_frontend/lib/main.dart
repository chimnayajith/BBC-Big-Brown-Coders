import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'services/background_service.dart';
import 'fall_detection_widget.dart';

void main() async {
  // Ensure Flutter initialization is complete
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize and start the background service
  await initializeBackgroundService();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senior Care App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: const TextTheme(
          // Larger text for better readability for seniors
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _service = FlutterBackgroundService();
  bool _serviceRunning = false;
  
  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
  }
  
  Future<void> _checkServiceStatus() async {
    _serviceRunning = await _service.isRunning();
    setState(() {});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Senior Care'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Health & Safety',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 20),
              
              // Background Service Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _serviceRunning ? Icons.shield : Icons.shield_outlined,
                                color: _serviceRunning ? Colors.green : Colors.red,
                                size: 32,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Background Protection',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          Switch(
                            value: _serviceRunning,
                            onChanged: (value) async {
                              if (value) {
                                await _service.startService();
                              } else {
                                _service.invoke('stopService');
                              }
                              
                              // Wait a moment for service to start/stop
                              await Future.delayed(Duration(milliseconds: 500));
                              _checkServiceStatus();
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        _serviceRunning 
                            ? 'Fall detection is active even when app is closed'
                            : 'Fall protection is disabled in background',
                        style: TextStyle(
                          fontSize: 16,
                          color: _serviceRunning ? Colors.black : Colors.red
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Test fall detection
                          _service.invoke('testFall');
                        },
                        child: Text('Test Background Alert'),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Fall Detection Widget
              FallDetectionWidget(),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}