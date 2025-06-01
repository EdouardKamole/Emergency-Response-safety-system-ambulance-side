import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/live_tracking_screen.dart';
import '../screens/patient_care_screen.dart';
import '../screens/profile_screen.dart';

class BottomNavWrapper extends StatefulWidget {
  const BottomNavWrapper({super.key});

  @override
  State<BottomNavWrapper> createState() => _BottomNavWrapperState();
}

class _BottomNavWrapperState extends State<BottomNavWrapper> {
  int _currentIndex = 0;
  Map<String, dynamic>? _selectedReport;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _updateSelectedReport(Map<String, dynamic> report) {
    debugPrint("Updating selected report: $report");
    setState(() {
      _selectedReport = report;
      _currentIndex = 1;
    });
    debugPrint(
      "After setState: currentIndex=$_currentIndex, selectedReport=$_selectedReport",
    );
    // Fallback navigation if tab switch fails
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentIndex != 1) {
        debugPrint("Fallback: Pushing LiveTrackingScreen directly");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => LiveTrackingScreen(
                  reportId: report['reportId'] as String,
                  emergencyLat: (report['latitude'] as num?)?.toDouble() ?? 0.0,
                  emergencyLon:
                      (report['longitude'] as num?)?.toDouble() ?? 0.0,
                ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Fallback navigation used: Tab switch failed"),
          ),
        );
      }
    });
  }

  Widget _getTrackingScreen() {
    debugPrint("getTrackingScreen called, selectedReport: $_selectedReport");
    if (_selectedReport == null) {
      return const Center(
        child: Text(
          'Select an emergency report from Home to start tracking',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }
    debugPrint("Rendering LiveTrackingScreen with report: $_selectedReport");
    return LiveTrackingScreen(
      reportId: _selectedReport!['reportId'] as String,
      emergencyLat: (_selectedReport!['latitude'] as num?)?.toDouble() ?? 0.0,
      emergencyLon: (_selectedReport!['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Building BottomNavWrapper, currentIndex: $_currentIndex");
    final screens = [
      HomeScreen(onReportSelected: _updateSelectedReport),
      _getTrackingScreen(),
      const PatientCareScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      key: _scaffoldKey,
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.redAccent,
          unselectedItemColor: Colors.grey[500],
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          onTap: (index) {
            debugPrint("BottomNavigationBar tapped: index $index");
            setState(() => _currentIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Track',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services_outlined),
              activeIcon: Icon(Icons.medical_services),
              label: 'Care',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
