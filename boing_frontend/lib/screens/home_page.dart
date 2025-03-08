import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../routes/app_routes.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _service = FlutterBackgroundService();
  bool _serviceRunning = false;
  User? currentUser;
  List<User> elderlyUsers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkServiceStatus();
    _loadUserData();
  }

  Future<void> _checkServiceStatus() async {
    _serviceRunning = await _service.isRunning();
    if (mounted) setState(() {});
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await AuthService.getCurrentUser();
      
      if (!result['success']) {
        // Not logged in, redirect to login
        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }

      // Parse user data
      currentUser = User.fromJson(result['data']);
      print(currentUser); 
      // If user is caregiver, fetch their elderly users
      if (currentUser!.isCaregiver()) {
        final elderlyResult = await AuthService.getElderlyUsers();
        if (elderlyResult['success']) {
          elderlyUsers = (elderlyResult['data'] as List)
              .map((json) => User.fromJson(json))
              .toList();
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load user data: $e';
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $errorMessage', style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _loadUserData,
                child: Text('Retry'),
              ),
              TextButton(
                onPressed: _logout,
                child: Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUser!.isCaregiver() ? 'Caregiver Dashboard' : 'Senior Care'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: currentUser!.isCaregiver() 
          ? _buildCaregiverView() 
          : _buildElderlyView(),
      floatingActionButton: currentUser!.isCaregiver() 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addElderly)
                    .then((value) {
                  if (value == true) {
                    _loadUserData(); // Refresh data if elderly was added
                  }
                });
              },
              child: Icon(Icons.person_add),
              tooltip: 'Add Elderly User',
            )
          : null,
    );
  }

  Widget _buildCaregiverView() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Caregiver welcome section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${currentUser!.name}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text('You are registered as a caregiver.'),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 24),
        
        // Elderly users section
        Text(
          'Elderly Users',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 8),
        
        elderlyUsers.isEmpty
            ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.groups, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No elderly users added yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Use the + button to add an elderly person to monitor',
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRoutes.addElderly)
                              .then((value) {
                            if (value == true) {
                              _loadUserData(); // Refresh data if elderly was added
                            }
                          });
                        },
                        icon: Icon(Icons.person_add),
                        label: Text('Add Elderly User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: elderlyUsers.length,
                itemBuilder: (context, index) {
                  final elderly = elderlyUsers[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Icon(Icons.person, color: Colors.blue),
                      ),
                      title: Text(elderly.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Phone: ${elderly.phone}'),
                          Text('Email: ${elderly.email}'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: Icon(Icons.call, color: Colors.green),
                        onPressed: () {
                          // Launch phone call to elderly
                          // Uri.parse('tel:${elderly.phone}')
                        },
                      ),
                      onTap: () {
                        // Show detailed view or options for this elderly user
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => Container(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: Text(elderly.name, style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Elderly User'),
                                ),
                                Divider(),
                                ListTile(
                                  leading: Icon(Icons.call),
                                  title: Text('Call'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Launch call
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.message),
                                  title: Text('Send Message'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Open messaging
                                  },
                                ),
                                ListTile(
                                  leading: Icon(Icons.health_and_safety),
                                  title: Text('View Health Status'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    // Navigate to health status page
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        
        SizedBox(height: 24),
        
        // Information card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Caregiver Responsibilities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 8),
                ListTile(
                  leading: Icon(Icons.notifications_active, color: Colors.red),
                  title: Text('Emergency Alerts'),
                  subtitle: Text('You will receive alerts when falls are detected or when SOS is triggered'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.monitor_heart, color: Colors.blue),
                  title: Text('Health Monitoring'),
                  subtitle: Text('Check in regularly with your elderly users'),
                  dense: true,
                ),
                ListTile(
                  leading: Icon(Icons.support_agent, color: Colors.green),
                  title: Text('Support'),
                  subtitle: Text('Provide assistance when needed'),
                  dense: true,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildElderlyView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elderly welcome section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${currentUser!.name}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  SizedBox(height: 8),
                  Text('Your caregiver can monitor your activity and respond to emergencies.'),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // SOS button
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Emergency SOS',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Show confirmation dialog
                      bool confirm = await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Send SOS Alert?'),
                          content: Text(
                            'This will send an emergency alert to your caregiver. Continue?'
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              child: Text('Send SOS'),
                            ),
                          ],
                        ),
                      ) ?? false;
                      
                      if (confirm) {
                        final result = await AuthService.sendSOS();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(result['success'] 
                              ? 'SOS alert sent successfully!' 
                              : 'Failed to send SOS: ${result['message']}'),
                          backgroundColor: result['success'] ? Colors.green : Colors.red,
                        ));
                      }
                    },
                    icon: Icon(Icons.emergency, size: 28),
                    label: Text('SEND SOS ALERT', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      minimumSize: Size(double.infinity, 60),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Background service status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fall Detection',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Switch(
                        value: _serviceRunning,
                        onChanged: (value) async {
                          if (value) {
                            await _service.startService();
                          } else {
                            _service.invoke('stopService');
                          }
                          await Future.delayed(Duration(milliseconds: 500));
                          _checkServiceStatus();
                        },
                      ),
                    ],
                  ),
                  Text(_serviceRunning 
                      ? 'Fall detection is active and will alert your caregiver automatically if a fall is detected'
                      : 'Fall detection is disabled'),
                  
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _service.invoke('testFall');
                      },
                      child: Text('Test Fall Alert'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Caregiver info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Caregiver',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        currentUser!.caregiverPhone ?? 'No caregiver assigned',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}