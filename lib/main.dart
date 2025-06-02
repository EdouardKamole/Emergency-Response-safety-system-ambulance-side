import 'package:emergency_response_safety_system_ambulance_side/screens/login_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/utils/tracking_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/history_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/profile_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/settings_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/screens/live_tracking_screen.dart';
import 'package:emergency_response_safety_system_ambulance_side/widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const EmergencyApp());
}

class EmergencyApp extends StatelessWidget {
  const EmergencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TrackingState(),
      child: ScreenUtilInit(
        designSize: const Size(408, 883),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          debugPrint('ScreenUtilInit completed');
          return MaterialApp(
            title: 'Ambulance Side - Emergency Response',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.red,
              fontFamily: GoogleFonts.poppins().fontFamily,
              scaffoldBackgroundColor: Colors.white,
              textTheme: TextTheme(
                bodyLarge: GoogleFonts.poppins(fontSize: 16.sp),
                bodyMedium: GoogleFonts.poppins(fontSize: 14.sp),
                titleLarge: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            home: const AuthWrapper(),
            routes: {
              '/history': (context) => const HistoryScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/login': (context) => const LoginScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/tracking') {
                final args = settings.arguments as Map<String, dynamic>?;
                if (args != null &&
                    args.containsKey('reportId') &&
                    args.containsKey('emergencyLat') &&
                    args.containsKey('emergencyLon')) {
                  return MaterialPageRoute(
                    builder:
                        (context) => LiveTrackingScreen(
                          reportId: args['reportId'],
                          emergencyLat: args['emergencyLat'],
                          emergencyLon: args['emergencyLon'],
                        ),
                  );
                } else {
                  debugPrint("Warning: Invalid tracking arguments: $args");
                  return MaterialPageRoute(
                    builder:
                        (context) => const LiveTrackingScreen(
                          reportId: 'dummy',
                          emergencyLat: 0.0,
                          emergencyLon: 0.0,
                        ),
                  );
                }
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          debugPrint("User authenticated, navigating to BottomNavWrapper");
          return const BottomNavWrapper();
        }
        debugPrint("No user authenticated, navigating to LoginScreen");
        return const LoginScreen();
      },
    );
  }
}
