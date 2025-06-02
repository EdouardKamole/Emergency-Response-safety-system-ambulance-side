import 'dart:async';
import 'package:emergency_response_safety_system_ambulance_side/utils/tracking_state.dart';
import 'package:emergency_response_safety_system_ambulance_side/widgets/bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:provider/provider.dart';

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
  late AnimationController _pulseController;
  late AnimationController _routeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _routeAnimation;
  StreamSubscription<DatabaseEvent>? _rescuerSubscription;
  StreamSubscription<DatabaseEvent>?
  _patientSubscription; // New: For victim location
  StreamSubscription<Position>? _positionSubscription;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastRouteFetch;
  Position? _currentPosition;
  bool _hasUserInteractedWithMap = false; // New: Track user interaction
  double _lastZoom = 13.0; // New: Track zoom level

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

    // Pulse animation for patient marker
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Route animation for polyline
    _routeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _routeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _routeController, curve: Curves.easeIn));
    _routeController.forward();

    // Listen for map interactions
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove) {
        _hasUserInteractedWithMap = true;
      } else if (_mapController.camera.zoom != _lastZoom) {
        _hasUserInteractedWithMap = true;
        _lastZoom = _mapController.camera.zoom;
      }
    });

    // Initialize location services and Firebase listeners
    Future.microtask(() {
      if (!mounted) return;
      _requestLocationPermission();
      _listenToRescuerUpdates();
      _listenToPatientUpdates(); // New: Listen for victim location
    });
  }

  @override
  void dispose() {
    _rescuerSubscription?.cancel();
    _patientSubscription?.cancel(); // New: Cancel victim subscription
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _routeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        _startLocationUpdates();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Location permission denied";
            _isLoading = false;
          });
        }
      }
    } else if (status.isGranted) {
      _startLocationUpdates();
    } else if (status.isPermanentlyDenied) {
      if (mounted) {
        setState(() {
          _errorMessage = "Location permission permanently denied";
          _isLoading = false;
        });
      }
      openAppSettings();
    }
  }

  void _startLocationUpdates() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) async {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final trackingState = Provider.of<TrackingState>(
          context,
          listen: false,
        );
        final rescuerLoc = LatLng(position.latitude, position.longitude);
        trackingState.updateRescuerLocation(widget.reportId, rescuerLoc);

        final database = FirebaseDatabase.instance.ref();
        final updateData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
          'eta': _calculateETA(position.latitude, position.longitude),
          'status':
              trackingState.getStatusStep(widget.reportId) == 0
                  ? 'en_route'
                  : 'arrived',
        };

        try {
          // Update Firebase
          await database
              .child('reports/${widget.reportId}/assignedRescuer/${user.uid}')
              .update(updateData);
          await database.child('activeRescuers/${user.uid}').update(updateData);
          if (!_hasUserInteractedWithMap) {
            _generateRoutePoints();
            _recenterMap();
          }
        } catch (e) {
          debugPrint("Error updating location: $e");
          if (mounted) {
            setState(() {
              _errorMessage = "Error updating location: $e";
            });
          }
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            _errorMessage = "Error fetching location: $e";
            _isLoading = false;
          });
        }
      },
    );
  }

  void _listenToPatientUpdates() {
    final database = FirebaseDatabase.instance.ref();
    _patientSubscription = database
        .child('reports/${widget.reportId}/location')
        .onValue
        .listen(
          (event) {
            if (!mounted) return;
            final data = event.snapshot.value as Map<dynamic, dynamic>?;
            if (data != null) {
              final double? latitude = data['latitude']?.toDouble();
              final double? longitude = data['longitude']?.toDouble();
              if (latitude != null && longitude != null) {
                final newPatientLocation = LatLng(latitude, longitude);
                setState(() {
                  _patientLocation = newPatientLocation;
                  _isLoading = false;
                  _errorMessage = null;
                });
                final trackingState = Provider.of<TrackingState>(
                  context,
                  listen: false,
                );
                trackingState.updateVictimLocation(
                  widget.reportId,
                  newPatientLocation,
                );
                if (!_hasUserInteractedWithMap) {
                  _generateRoutePoints();
                  _recenterMap();
                }
              } else {
                setState(() {
                  _isLoading = false;
                  _errorMessage = "Invalid patient location data";
                });
              }
            } else {
              setState(() {
                _isLoading = false;
                _errorMessage = "No patient location data found";
              });
            }
          },
          onError: (error, stackTrace) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = "Error fetching patient location: $error";
              });
              debugPrint("Firebase error: $error\nStackTrace: $stackTrace");
            }
          },
        );
  }

  void _listenToRescuerUpdates() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "User not authenticated";
        });
      }
      return;
    }

    final database = FirebaseDatabase.instance.ref();
    final path = 'reports/${widget.reportId}/assignedRescuer/${user.uid}';
    _rescuerSubscription = database
        .child(path)
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value as Map<dynamic, dynamic>?;
            if (!mounted) return;

            final trackingState = Provider.of<TrackingState>(
              context,
              listen: false,
            );
            if (data != null) {
              final double? latitude = data['latitude']?.toDouble();
              final double? longitude = data['longitude']?.toDouble();
              final int? eta = data['eta']?.toInt();
              final String? status = data['status']?.toString();

              if (latitude != null && longitude != null) {
                trackingState.updateRescuerLocation(
                  widget.reportId,
                  LatLng(latitude, longitude),
                );
                trackingState.updateEta(
                  widget.reportId,
                  eta ?? _calculateETA(latitude, longitude),
                );

                // Update status based on distance and Firebase data
                final distance = Geolocator.distanceBetween(
                  latitude,
                  longitude,
                  _patientLocation.latitude,
                  _patientLocation.longitude,
                );
                int newStatusStep = trackingState.getStatusStep(
                  widget.reportId,
                );
                if (distance < 100 && newStatusStep < 1) {
                  newStatusStep = 1; // At Scene
                } else if (newStatusStep == 1 && distance > 100) {
                  newStatusStep = 2; // Transporting Patient
                } else if (newStatusStep == 2 && distance > 1000) {
                  newStatusStep = 3; // Arrived at Hospital
                } else if (status == 'arrived' && newStatusStep < 1) {
                  newStatusStep = 1;
                }
                trackingState.updateStatus(widget.reportId, newStatusStep);

                setState(() {
                  _isLoading = false;
                  _errorMessage = null;
                });
                if (!_hasUserInteractedWithMap) {
                  _generateRoutePoints();
                  _recenterMap();
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
                _errorMessage = "No rescuer data found at $path";
              });
            }
          },
          onError: (error, stackTrace) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = "Error fetching rescuer data: $error";
              });
              debugPrint("Firebase error: $error\nStackTrace: $stackTrace");
            }
          },
        );
  }

  int _calculateETA(double rescuerLat, double rescuerLon) {
    final distance = Geolocator.distanceBetween(
      rescuerLat,
      rescuerLon,
      _patientLocation.latitude,
      _patientLocation.longitude,
    );
    // Assume average speed of 40 km/h (11.11 m/s) for urban ambulance travel
    final etaSeconds = (distance / 11.11).round();
    return etaSeconds.clamp(60, 900); // 1–15 minutes
  }

  void _generateRoutePoints() async {
    if (_lastRouteFetch != null &&
        DateTime.now().difference(_lastRouteFetch!).inSeconds < 10) {
      return; // Throttle route requests
    }
    _lastRouteFetch = DateTime.now();

    final trackingState = Provider.of<TrackingState>(context, listen: false);
    final rescuerLoc =
        _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : trackingState.getRescuerLocation(widget.reportId);
    if (rescuerLoc == null) {
      if (mounted) {
        setState(() {
          _errorMessage = "Rescuer location unavailable";
          _isLoading = false;
        });
      }
      return;
    }

    const String apiKey =
        '5b3ce3597851110001cf624862ba9d9ce4314f088c7a3b8fec0f957e';
    const String profile = 'driving-car';
    const String orsUrl =
        'https://api.openrouteservice.org/v2/directions/$profile/geojson';

    final Map<String, dynamic> body = {
      'coordinates': [
        [rescuerLoc.longitude, rescuerLoc.latitude],
        [_patientLocation.longitude, _patientLocation.latitude],
      ],
      'units': 'm',
      'geometry': true,
    };

    try {
      final response = await http
          .post(
            Uri.parse(orsUrl),
            headers: {
              'Authorization': apiKey,
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final features = data['features'] as List<dynamic>;
        final geometry = features[0]['geometry'] as Map<String, dynamic>;
        final coordinates = geometry['coordinates'] as List<dynamic>;
        final properties = features[0]['properties'] as Map<String, dynamic>;
        final segments = properties['segments'] as List<dynamic>;
        final duration = segments[0]['duration'] as num;

        final List<LatLng> newRoutePoints =
            coordinates
                .map(
                  (coord) => LatLng(coord[1].toDouble(), coord[0].toDouble()),
                )
                .toList();

        trackingState.updateRoutePoints(widget.reportId, newRoutePoints);
        trackingState.updateEta(widget.reportId, duration.round());
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        // Fallback to straight line
        trackingState.updateRoutePoints(widget.reportId, [
          rescuerLoc,
          _patientLocation,
        ]);
        trackingState.updateEta(
          widget.reportId,
          _calculateETA(rescuerLoc.latitude, rescuerLoc.longitude),
        );
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to fetch route, using direct path";
        });
      }
    } catch (e) {
      trackingState.updateRoutePoints(widget.reportId, [
        rescuerLoc,
        _patientLocation,
      ]);
      trackingState.updateEta(
        widget.reportId,
        _calculateETA(rescuerLoc.latitude, rescuerLoc.longitude),
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error fetching route, using direct path";
        });
      }
    }
  }

  void _recenterMap() {
    final trackingState = Provider.of<TrackingState>(context, listen: false);
    final rescuerLoc = trackingState.getRescuerLocation(widget.reportId);
    if (rescuerLoc == null) return;

    final bounds = LatLngBounds.fromPoints([_patientLocation, rescuerLoc]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)),
    );
    _hasUserInteractedWithMap = false; // Reset interaction flag
    _lastZoom = _mapController.camera.zoom; // Update zoom level
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

  @override
  Widget build(BuildContext context) {
    final trackingState = Provider.of<TrackingState>(context);
    return Scaffold(
      body: Stack(
        children: [
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
              PolylineLayer(
                polylines: [
                  if (trackingState.getRoutePoints(widget.reportId).length > 1)
                    Polyline(
                      points: trackingState.getRoutePoints(widget.reportId),
                      color: Colors.blue.withOpacity(0.8),
                      strokeWidth: 4.0,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
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
                  if (trackingState.getRescuerLocation(widget.reportId) != null)
                    Marker(
                      width: 45.0,
                      height: 45.0,
                      point: trackingState.getRescuerLocation(widget.reportId)!,
                      child: _buildCustomMarker(
                        icon: Icons.local_hospital,
                        color:
                            _statuses[trackingState.getStatusStep(
                              widget.reportId,
                            )]["color"],
                        size: 45,
                      ),
                    ),
                ],
              ),
            ],
          ),
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              children: [
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BottomNavWrapper(),
                        ),
                      ),
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
                      "Live Tracking",
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
          Positioned(
            right: 20,
            bottom: 230,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "recenter",
                  onPressed: _recenterMap,
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.redAccent),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoomIn",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  mini: true,
                  backgroundColor: Colors.white,
                  onPressed: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
              ],
            ),
          ),
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
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _statuses[trackingState.getStatusStep(
                                        widget.reportId,
                                      )]["color"]
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _statuses[trackingState.getStatusStep(
                                    widget.reportId,
                                  )]["icon"],
                                  color:
                                      _statuses[trackingState.getStatusStep(
                                        widget.reportId,
                                      )]["color"],
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _statuses[trackingState.getStatusStep(
                                        widget.reportId,
                                      )]["text"],
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
                              Container(
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
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "ETA: ${(trackingState.getEtaSeconds(widget.reportId) ~/ 60).clamp(1, 15)} mins",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              widthFactor:
                                  (trackingState.getStatusStep(
                                        widget.reportId,
                                      ) +
                                      1) /
                                  _statuses.length,
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
                          ),
                          const SizedBox(height: 10),
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
                                        "Call Victim",
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
