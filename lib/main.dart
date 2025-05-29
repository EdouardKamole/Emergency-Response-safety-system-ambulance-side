import 'package:flutter/material.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/emergency_detail_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/patient_care_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/home_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/history_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/profile_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/settings_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/live_tracking_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/widgets/bottom_nav.dart';

void main() {
  runApp(const EmergencyAmbulanceApp());
}

class EmergencyAmbulanceApp extends StatelessWidget {
  const EmergencyAmbulanceApp({super.key}); //

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ambulance Side - Emergency Response',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: BottomNavWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/details': (context) => const EmergencyDetailScreen(),
        '/tracking': (context) => LiveTrackingScreen(),
        '/care': (context) => PatientCareScreen(),
        '/history': (context) => HistoryScreen(),
        '/profile': (context) => ProfileScreen(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}
