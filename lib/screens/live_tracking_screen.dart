import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  _LiveTrackingScreenState createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  final LatLng _patientLocation = LatLng(
    5.6037,
    -0.1870,
  ); // Patient location (Accra)
  late LatLng _ambulanceLocation;
  late Timer _movementTimer;
  late Timer _statusTimer;
  late AnimationController _pulseController;
  late AnimationController _routeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _routeAnimation;

  int _statusStep = 0;
  final List<Map<String, dynamic>> _statuses = [
    {
      "text": "En Route to Patient",
      "icon": Icons.directions_car,
      "color": Colors.orange,
    },
    {"text": "At Scene", "icon": Icons.location_on, "color": Colors.blue},
    {
      "text": "Transporting Patient",
      "icon": Icons.local_hospital,
      "color": Colors.green,
    },
    {
      "text": "Arrived at Hospital",
      "icon": Icons.local_hospital,
      "color": Colors.red,
    },
  ];

  List<LatLng> _routePoints = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Start ambulance at a different location from patient
    _ambulanceLocation = LatLng(5.5900, -0.2000);
    _generateRoutePoints();

    // Animation controllers
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _routeController = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _routeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _routeController, curve: Curves.easeInOut),
    );

    _routeController.forward();

    // Simulate ambulance movement along route
    _movementTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      setState(() {
        _moveAmbulanceAlongRoute();
      });
    });

    // Status updates
    _statusTimer = Timer.periodic(Duration(seconds: 8), (timer) {
      setState(() {
        if (_statusStep < _statuses.length - 1) {
          _statusStep++;
        }
      });
    });
  }

  void _generateRoutePoints() {
    // Generate a curved route from ambulance to patient
    final double latDiff =
        _patientLocation.latitude - _ambulanceLocation.latitude;
    final double lngDiff =
        _patientLocation.longitude - _ambulanceLocation.longitude;

    _routePoints.clear();
    for (int i = 0; i <= 20; i++) {
      double t = i / 20.0;
      // Add some curve to make it look more realistic
      double curveFactor = sin(t * pi) * 0.002;

      LatLng point = LatLng(
        _ambulanceLocation.latitude + (latDiff * t) + curveFactor,
        _ambulanceLocation.longitude + (lngDiff * t) - curveFactor,
      );
      _routePoints.add(point);
    }
  }

  void _moveAmbulanceAlongRoute() {
    if (_routePoints.isNotEmpty && _statusStep < 2) {
      int currentIndex = (_routePoints.length * _statusStep / 4).round();
      if (currentIndex < _routePoints.length) {
        _ambulanceLocation = _routePoints[currentIndex];

        // Auto-center map on ambulance
        _mapController.move(_ambulanceLocation, 14.0);
      }
    }
  }

  @override
  void dispose() {
    _movementTimer.cancel();
    _statusTimer.cancel();
    _pulseController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Widget _buildCustomMarker({
    required IconData icon,
    required Color color,
    required double size,
    bool isPulsing = false,
  }) {
    return AnimatedBuilder(
      animation: isPulsing ? _pulseAnimation : AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: isPulsing ? _pulseAnimation.value : 1.0,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: isPulsing ? 5 : 2,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: size * 0.6),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _ambulanceLocation,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
              ),

              // Route line
              AnimatedBuilder(
                animation: _routeAnimation,
                builder: (context, child) {
                  int visiblePoints =
                      (_routePoints.length * _routeAnimation.value).round();
                  List<LatLng> visibleRoute =
                      _routePoints.take(visiblePoints).toList();

                  return PolylineLayer(
                    polylines: [
                      if (visibleRoute.length > 1)
                        Polyline(
                          points: visibleRoute,
                          color: Colors.redAccent.withOpacity(0.8),
                          strokeWidth: 4.0,
                          // Remove the pattern line entirely or use this alternative:
                          isDotted: true, // This creates a dotted line effect
                        ),
                    ],
                  );
                },
              ),

              // Markers
              MarkerLayer(
                markers: [
                  // Patient marker
                  Marker(
                    width: 50.0,
                    height: 50.0,
                    point: _patientLocation,
                    child: _buildCustomMarker(
                      icon: Icons.person_pin_circle,
                      color: Colors.blue,
                      size: 50,
                      isPulsing: true,
                    ),
                  ),

                  // Ambulance marker
                  Marker(
                    width: 45.0,
                    height: 45.0,
                    point: _ambulanceLocation,
                    child: _buildCustomMarker(
                      icon: Icons.local_hospital,
                      color: _statuses[_statusStep]["color"],
                      size: 45,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Gradient overlay at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
              ),
            ),
          ),

          // Custom App Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back, color: Colors.redAccent),
                ),
                SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      "Live Ambulance Tracking",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status indicator
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _statuses[_statusStep]["color"].withOpacity(
                            0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _statuses[_statusStep]["icon"],
                          color: _statuses[_statusStep]["color"],
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statuses[_statusStep]["text"],
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Ambulance Unit #AM-001",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.redAccent, Colors.red[700]!],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "ETA: ${(15 - _statusStep * 3).clamp(2, 15)} mins",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 15),

                  // Progress bar
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: (_statusStep + 1) / _statuses.length,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.redAccent, Colors.red[700]!],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  // Contact buttons
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.call,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Call Driver",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[300]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.message,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Message",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
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
