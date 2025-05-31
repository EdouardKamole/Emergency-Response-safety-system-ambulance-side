import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class LiveTrackingScreen extends StatefulWidget {
  final String reportId;
  final double emergencyLat;
  final double emergencyLon;

  const LiveTrackingScreen({
    super.key,
    required this.reportId,
    required this.emergencyLat,
    required this.emergencyLon,
  });

  @override
  _LiveTrackingScreenState createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  late LatLng _patientLocation;
  final _rescuerLocation = ValueNotifier<LatLng?>(null);
  final _etaSeconds = ValueNotifier<int>(300); // Default ETA: 5 minutes
  final _statusStep = ValueNotifier<int>(0);
  final _routePoints = ValueNotifier<List<LatLng>>([]);
  late AnimationController _pulseController;
  late AnimationController _routeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _routeAnimation;
  late StreamSubscription<DatabaseEvent> _rescuerSubscription;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String? _errorMessage;

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

  @override
  void initState() {
    super.initState();
    _patientLocation = LatLng(widget.emergencyLat, widget.emergencyLon);
    _rescuerLocation.value = LatLng(
      widget.emergencyLat + 0.01,
      widget.emergencyLon + 0.01,
    ); // Initial rescuer position
    _generateRoutePoints();

    // Animation controllers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _routeController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _routeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _routeController, curve: Curves.easeInOut),
    );
    _routeController.forward();

    // Fetch rescuer updates from Firebase
    _listenToRescuerUpdates();

    // Center map initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_rescuerLocation.value!, 14.0);
    });
  }

  void _listenToRescuerUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "User not authenticated";
      });
      return;
    }

    final database = FirebaseDatabase.instance.ref();
    _rescuerSubscription = database
        .child('reports/${widget.reportId}/assignedRescuer/${user.uid}')
        .onValue
        .listen(
          (event) async {
            final data = event.snapshot.value as Map<dynamic, dynamic>?;
            if (data != null && mounted) {
              final double? latitude = data['latitude']?.toDouble();
              final double? longitude = data['longitude']?.toDouble();
              final int? eta = data['eta']?.toInt();

              if (latitude != null && longitude != null) {
                _rescuerLocation.value = LatLng(latitude, longitude);
                _etaSeconds.value = eta ?? _etaSeconds.value;
                _generateRoutePoints();

                // Update status based on distance
                double distance = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  _patientLocation.latitude,
                  _patientLocation.longitude,
                );
                if (distance < 100 && _statusStep.value < 1) {
                  _statusStep.value = 1; // At Scene
                } else if (_statusStep.value == 1 && distance > 100) {
                  _statusStep.value = 2; // Transporting Patient
                } else if (_statusStep.value == 2 && distance > 1000) {
                  _statusStep.value = 3; // Arrived at Hospital
                }

                // Update loading state only on first valid data
                if (_isLoading) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              } else {
                setState(() {
                  _isLoading = false;
                  _errorMessage = "Invalid rescuer location data";
                });
              }
            } else {
              setState(() {
                _isLoading = false;
                _errorMessage = "No rescuer data found";
              });
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = "Error fetching rescuer data: $error";
              });
            }
          },
        );
  }

  void _generateRoutePoints() {
    final rescuerLoc = _rescuerLocation.value;
    if (rescuerLoc == null) return;

    final double latDiff = _patientLocation.latitude - rescuerLoc.latitude;
    final double lngDiff = _patientLocation.longitude - rescuerLoc.longitude;
    final List<LatLng> newRoutePoints = [];
    for (int i = 0; i <= 20; i++) {
      double t = i / 20.0;
      double curveFactor = sin(t * pi) * 0.002;
      LatLng point = LatLng(
        rescuerLoc.latitude + (latDiff * t) + curveFactor,
        rescuerLoc.longitude + (lngDiff * t) - curveFactor,
      );
      newRoutePoints.add(point);
    }
    _routePoints.value = newRoutePoints;
  }

  @override
  void dispose() {
    _rescuerSubscription.cancel();
    _pulseController.dispose();
    _routeController.dispose();
    _rescuerLocation.dispose();
    _etaSeconds.dispose();
    _statusStep.dispose();
    _routePoints.dispose();
    super.dispose();
  }

  Widget _buildCustomMarker({
    required IconData icon,
    required Color color,
    required double size,
    bool isPulsing = false,
  }) {
    return AnimatedBuilder(
      animation:
          isPulsing ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
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

  void _recenterMap() {
    final bounds = LatLngBounds.fromPoints([
      _patientLocation,
      _rescuerLocation.value ?? _patientLocation,
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
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
              initialCenter: _patientLocation,
              initialZoom: 13.0,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
              ),
              ValueListenableBuilder<List<LatLng>>(
                valueListenable: _routePoints,
                builder: (context, routePoints, _) {
                  return AnimatedBuilder(
                    animation: _routeAnimation,
                    builder: (context, child) {
                      int visiblePoints =
                          (routePoints.length * _routeAnimation.value).round();
                      List<LatLng> visibleRoute =
                          routePoints.take(visiblePoints).toList();
                      return PolylineLayer(
                        polylines: [
                          if (visibleRoute.length > 1)
                            Polyline(
                              points: visibleRoute,
                              color: Colors.redAccent.withOpacity(0.8),
                              strokeWidth: 4.0,
                              isDotted: true,
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
              ValueListenableBuilder<LatLng?>(
                valueListenable: _rescuerLocation,
                builder: (context, rescuerLoc, _) {
                  return MarkerLayer(
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
                      // Rescuer marker
                      if (rescuerLoc != null)
                        Marker(
                          width: 45.0,
                          height: 45.0,
                          point: rescuerLoc,
                          child: ValueListenableBuilder<int>(
                            valueListenable: _statusStep,
                            builder: (context, statusStep, _) {
                              return _buildCustomMarker(
                                icon: Icons.local_hospital,
                                color: _statuses[statusStep]["color"],
                                size: 45,
                              );
                            },
                          ),
                        ),
                    ],
                  );
                },
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
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
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
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
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
                      "Live Rescuer Tracking",
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

          // Recenter Button
          Positioned(
            right: 20,
            bottom: 230,
            child: FloatingActionButton(
              onPressed: _recenterMap,
              mini: true,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.redAccent),
            ),
          ),

          // Status Card
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            spreadRadius: 5,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Status indicator
                          ValueListenableBuilder<int>(
                            valueListenable: _statusStep,
                            builder: (context, statusStep, _) {
                              return Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _statuses[statusStep]["color"]
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _statuses[statusStep]["icon"],
                                      color: _statuses[statusStep]["color"],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _statuses[statusStep]["text"],
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Rescuer Unit #${FirebaseAuth.instance.currentUser?.uid.substring(0, 6)}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ValueListenableBuilder<int>(
                                    valueListenable: _etaSeconds,
                                    builder: (context, eta, _) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.redAccent,
                                              Colors.red[700]!,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          "ETA: ${(eta ~/ 60).clamp(1, 15)} mins",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                          // Progress bar
                          ValueListenableBuilder<int>(
                            valueListenable: _statusStep,
                            builder: (context, statusStep, _) {
                              return Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor:
                                      (statusStep + 1) / _statuses.length,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.redAccent,
                                          Colors.red[700]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          // Contact buttons (placeholders)
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.call,
                                        color: Colors.green[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Call Rescuer",
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
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.blue[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.message,
                                        color: Colors.blue[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
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
