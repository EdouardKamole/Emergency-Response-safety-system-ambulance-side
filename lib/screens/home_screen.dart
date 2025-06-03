import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onReportSelected;
  const HomeScreen({super.key, required this.onReportSelected});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _heartbeatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _heartbeatAnimation;
  List<Map<String, dynamic>> emergencyReports = [];
  Map<String, dynamic>? activeEmergency;
  bool isLoading = true;
  String? errorMessage;
  final user = FirebaseAuth.instance.currentUser;
  Position? _currentPosition;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _locationSubscription;

  @override
  void initState() {
    super.initState();

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return;
    }

    // Pulse animation for header
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Heartbeat animation for emergency indicator
    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _heartbeatAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _heartbeatController, curve: Curves.easeInOut),
    );

    // Request location permission
    _requestLocationPermission();

    // Fetch initial data
    _checkActiveEmergency();
    _fetchEmergencyReports();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _heartbeatController.dispose();
    _locationUpdateTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        _getCurrentLocation();
      } else {
        if (mounted) {
          setState(() {
            errorMessage = "Location permission denied";
          });
        }
      }
    } else if (status.isGranted) {
      _getCurrentLocation();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          errorMessage = "Location permission permanently denied";
        });
      }
      openAppSettings();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error fetching location: $e";
        });
      }
    }
  }

  Future<void> _checkActiveEmergency() async {
    if (!mounted || user == null) return;

    try {
      final database = FirebaseDatabase.instance;
      final snapshot = await database
          .ref()
          .child('reports')
          .orderByChild('status')
          .equalTo('accepted')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("Request timed out"),
          );

      if (!mounted) return;

      if (snapshot.exists && snapshot.value != null) {
        final reports = snapshot.value as Map<dynamic, dynamic>;
        Map<String, dynamic>? foundEmergency;
        reports.forEach((key, value) {
          final report = Map<String, dynamic>.from(value as Map);
          if (report['assignedRescuer'] != null &&
              report['assignedRescuer'][user!.uid] != null) {
            foundEmergency = {
              'id': key,
              'type': report['type'] ?? 'Unknown',
              'severity': _determineSeverity(report['type']),
              'time': _formatTime(report['location']?['timestamp']),
              'location': report['location']?['address'] ?? 'Unknown Location',
              'distance': _calculateDistance(
                report['location']?['latitude'],
                report['location']?['longitude'],
              ),
              'color': _getColorForType(report['type']),
              'latitude': report['location']?['latitude'],
              'longitude': report['location']?['longitude'],
            };
          }
        });
        if (mounted) {
          setState(() {
            activeEmergency = foundEmergency;
          });
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          errorMessage = "Error checking active emergency: $e";
        });
      }
      debugPrint(
        "Error checking active emergency: $e\nStackTrace: $stackTrace",
      );
    }
  }

  Future<void> _fetchEmergencyReports() async {
    if (!mounted || user == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = user == null ? "User not authenticated" : null;
        });
      }
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final database = FirebaseDatabase.instance;
      final snapshot = await database
          .ref()
          .child('reports')
          .orderByChild('status')
          .equalTo('reported')
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("Request timed out"),
          );

      if (!mounted) return;

      if (snapshot.exists && snapshot.value != null) {
        final reports = snapshot.value as Map<dynamic, dynamic>;
        List<Map<String, dynamic>> tempReports = [];
        reports.forEach((key, value) {
          try {
            final report = Map<String, dynamic>.from(value as Map);
            tempReports.add({
              'id': key,
              'type': report['type'] ?? 'Unknown',
              'severity': _determineSeverity(report['type']),
              'time': _formatTime(report['location']?['timestamp']),
              'location': report['location']?['address'] ?? 'Unknown Location',
              'distance': _calculateDistance(
                report['location']?['latitude'],
                report['location']?['longitude'],
              ),
              'color': _getColorForType(report['type']),
              'latitude': report['location']?['latitude'],
              'longitude': report['location']?['longitude'],
            });
          } catch (e) {
            debugPrint("Error processing report $key: $e");
          }
        });
        if (mounted) {
          setState(() {
            emergencyReports = tempReports;
            isLoading = false;
            errorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Reports refreshed successfully")),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            emergencyReports = [];
            isLoading = false;
            errorMessage = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No new reports available")),
          );
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage =
              e.toString().contains("timeout")
                  ? "No internet connection or server timeout"
                  : "Error fetching reports: $e";
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage!)));
      }
      debugPrint("Error fetching reports: $e\nStackTrace: $stackTrace");
    }
  }

  void _startLocationUpdates(
    String reportId,
    double emergencyLat,
    double emergencyLon,
  ) {
    _locationUpdateTimer?.cancel();
    _locationSubscription?.cancel();

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) async {
      if (!mounted || user == null) {
        _locationSubscription?.cancel();
        return;
      }

      try {
        setState(() {
          _currentPosition = position;
        });

        final database = FirebaseDatabase.instance;
        final updateData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
          'eta': _calculateETA(
            position.latitude,
            position.longitude,
            emergencyLat,
            emergencyLon,
          ),
          'status': 'en_route',
        };

        await database
            .ref()
            .child('reports/$reportId/assignedRescuer/${user!.uid}')
            .update(updateData);
        await database
            .ref()
            .child('activeRescuers/${user!.uid}')
            .update(updateData);

        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          emergencyLat,
          emergencyLon,
        );
        if (distance < 100) {
          await database
              .ref()
              .child('reports/$reportId/assignedRescuer/${user!.uid}')
              .update({'status': 'arrived'});
          await database.ref().child('activeRescuers/${user!.uid}').update({
            'status': 'arrived',
          });
          _locationSubscription?.cancel();
          _checkActiveEmergency();
        }
      } catch (e) {
        debugPrint("Error updating location: $e");
      }
    });
  }

  int _calculateETA(
    double? rescuerLat,
    double? rescuerLon,
    double emergencyLat,
    double emergencyLon,
  ) {
    if (rescuerLat == null || rescuerLon == null) {
      return 300; // Default 5 minutes
    }
    final distance = Geolocator.distanceBetween(
      rescuerLat,
      rescuerLon,
      emergencyLat,
      emergencyLon,
    );
    // Assume 40 km/h (11.11 m/s)
    final etaSeconds = (distance / 11.11).round();
    return etaSeconds.clamp(60, 900); // 1–15 minutes
  }

  Future<void> _acceptEmergency(
    String reportId,
    double? latitude,
    double? longitude,
  ) async {
    if (!mounted || user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not authenticated")));
      return;
    }

    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid emergency location")),
      );
      return;
    }

    try {
      final database = FirebaseDatabase.instance;

      final initialData = {
        'latitude': _currentPosition?.latitude ?? latitude,
        'longitude': _currentPosition?.longitude ?? longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'eta': _calculateETA(
          _currentPosition?.latitude ?? latitude,
          _currentPosition?.longitude ?? longitude,
          latitude,
          longitude,
        ),
        'status': 'en_route',
      };

      await database
          .ref()
          .child('reports/$reportId')
          .update({
            'status': 'accepted',
            'assignedRescuer': {user!.uid: initialData},
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("Request timed out"),
          );

      await database
          .ref()
          .child('activeRescuers/${user!.uid}')
          .set(initialData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception("Request timed out"),
          );

      if (!mounted) return;

      _startLocationUpdates(reportId, latitude, longitude);

      debugPrint(
        "Navigating to tracking in _acceptEmergency for report: $reportId",
      );
      widget.onReportSelected({
        'reportId': reportId,
        'latitude': latitude,
        'longitude': longitude,
      });

      await _fetchEmergencyReports();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency accepted successfully")),
      );
    } catch (e, stackTrace) {
      if (mounted) {
        final errorMsg =
            e.toString().contains("timeout")
                ? "No internet connection or server timeout"
                : "Error accepting report: $e";
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
      debugPrint("Error accepting report: $e\nStackTrace: $stackTrace");
    }
  }

  void _continueToTracking() {
    if (activeEmergency == null) {
      debugPrint("No active emergency to continue");
      return;
    }

    debugPrint(
      "Navigating to tracking in _continueToTracking for report: ${activeEmergency!['id']}",
    );
    widget.onReportSelected({
      'reportId': activeEmergency!['id'],
      'latitude': activeEmergency!['latitude'],
      'longitude': activeEmergency!['longitude'],
    });
  }

  String _determineSeverity(String? type) {
    switch (type) {
      case 'Medical':
      case 'Heart Attack':
      case 'SOS':
        return 'CRITICAL';
      case 'Accident':
      case 'Fire':
        return 'HIGH';
      case 'Hazard':
      case 'Breathing Issue':
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      final dateTime = DateTime.parse(timestamp);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else {
        return '${difference.inHours} hr ago';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }

  String _calculateDistance(double? lat, double? lon) {
    if (lat == null || lon == null || _currentPosition == null) return 'N/A';
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    );
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'Medical':
      case 'Heart Attack':
      case 'SOS':
        return const Color(0xFFEF4444);
      case 'Accident':
      case 'Fire':
        return const Color(0xFFF59E0B);
      case 'Hazard':
      case 'Breathing Issue':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    margin: EdgeInsets.all(padding),
                    padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        isSmallScreen ? 16 : 24,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Emergency Response",
                                style: GoogleFonts.poppins(
                                  fontSize: isSmallScreen ? 14.sp : 15.sp,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                "Active Reports",
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1D29),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            // Profile Avatar
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4F46E5),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  isSmallScreen ? 12 : 16,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF4F46E5,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                FontAwesomeIcons.userDoctor,
                                color: Colors.white,
                                size: isSmallScreen ? 16 : 20,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Refresh Button
                            Container(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.refresh,
                                  size: isSmallScreen ? 16 : 20,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: _fetchEmergencyReports,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Emergency Alerts Section
                  Container(
                    constraints: BoxConstraints(minHeight: screenHeight * 0.4),
                    margin: EdgeInsets.symmetric(horizontal: padding),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isSmallScreen ? 20 : 32),
                        topRight: Radius.circular(isSmallScreen ? 20 : 32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Section Header
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _heartbeatAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _heartbeatAnimation.value,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isSmallScreen ? 8 : 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEF4444),
                                            Color(0xFFDC2626),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          isSmallScreen ? 12 : 16,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        FontAwesomeIcons.heartPulse,
                                        color: Colors.white,
                                        size: isSmallScreen ? 16 : 20,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activeEmergency != null
                                          ? "Active Emergency"
                                          : "Emergency Alerts",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A1D29),
                                      ),
                                    ),
                                    Text(
                                      activeEmergency != null
                                          ? "You are responding to an emergency"
                                          : "Real-time emergency responses",
                                      style: GoogleFonts.poppins(
                                        fontSize: isSmallScreen ? 12.sp : 14.sp,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (activeEmergency == null)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 8 : 12,
                                    vertical: isSmallScreen ? 4 : 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    "${emergencyReports.length} Active",
                                    style: GoogleFonts.poppins(
                                      fontSize: isSmallScreen ? 10.sp : 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Content based on state
                        if (isLoading)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (errorMessage != null)
                          Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                            child: Text(
                              errorMessage!,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 12.sp : 14.sp,
                                color: const Color(0xFFEF4444),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else if (activeEmergency != null)
                          _buildActiveEmergencyCard(
                            activeEmergency!,
                            isSmallScreen,
                          )
                        else if (emergencyReports.isEmpty)
                          Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                            child: Text(
                              "No active emergency reports",
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 12.sp : 14.sp,
                                color: const Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 14.sp : 18.sp,
                            ),
                            itemCount: emergencyReports.length,
                            itemBuilder:
                                (context, index) =>
                                    _buildEmergencyCard(index, isSmallScreen),
                          ),
                      ],
                    ),
                  ),

                  // Bottom spacing
                  SizedBox(height: padding),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchEmergencyReports,
        backgroundColor: const Color(0xFF4F46E5),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildActiveEmergencyCard(
    Map<String, dynamic> emergency,
    bool isSmallScreen,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16.w : 24.w,
        vertical: isSmallScreen ? 12.h : 16.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            (emergency['color'] as Color).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: (emergency['color'] as Color).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (emergency['color'] as Color).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: emergency['color'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emergency['severity'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  emergency['time'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.sp),
            Text(
              emergency['type'] as String,
              style: GoogleFonts.poppins(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D29),
              ),
            ),
            SizedBox(height: 6.h),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.locationDot,
                  size: isSmallScreen ? 12 : 14,
                  color: emergency['color'] as Color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    emergency['location'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 12.sp : 14.sp,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: (emergency['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emergency['distance'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: emergency['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Container(
              height: isSmallScreen ? 40.h : 44.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    emergency['color'] as Color,
                    (emergency['color'] as Color).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton.icon(
                icon: Icon(
                  FontAwesomeIcons.mapLocationDot,
                  size: isSmallScreen ? 14 : 16,
                ),
                label: Text(
                  "Continue to Tracking",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 12.sp,
                  ),
                ),
                onPressed: _continueToTracking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(int index, bool isSmallScreen) {
    final emergency = emergencyReports[index];

    return Container(
      margin: EdgeInsets.only(bottom: isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            (emergency['color'] as Color).withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        border: Border.all(
          color: (emergency['color'] as Color).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (emergency['color'] as Color).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: emergency['color'] as Color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    emergency['severity'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 8 : 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  emergency['time'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 10.sp : 12.sp,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 8.h : 12.h),
            Text(
              emergency['type'] as String,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1D29),
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.locationDot,
                  size: isSmallScreen ? 12 : 14,
                  color: emergency['color'] as Color,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    emergency['location'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 6 : 8,
                    vertical: isSmallScreen ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: (emergency['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emergency['distance'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 10 : 12,
                      fontWeight: FontWeight.w600,
                      color: emergency['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12.h : 16.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: isSmallScreen ? 40.h : 44.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          emergency['color'] as Color,
                          (emergency['color'] as Color).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(
                        FontAwesomeIcons.check,
                        size: isSmallScreen ? 14 : 16,
                      ),
                      label: Text(
                        "Accept",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.sp,
                        ),
                      ),
                      onPressed:
                          () => _acceptEmergency(
                            emergency['id'],
                            emergency['latitude'],
                            emergency['longitude'],
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  height: isSmallScreen ? 40.h : 44.h,
                  width: isSmallScreen ? 40.w : 44.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      FontAwesomeIcons.ellipsisVertical,
                      size: isSmallScreen ? 14 : 16,
                    ),
                    color: const Color(0xFF64748B),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: Text(emergency['type']),
                              content: Text(
                                "Details: ${emergency['location']}",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
