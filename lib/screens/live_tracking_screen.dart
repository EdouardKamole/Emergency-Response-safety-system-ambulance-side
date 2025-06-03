import 'dart:async';
import 'package:emergency_response_safety_system_ambulance_side/utils/tracking_state.dart';
import 'package:emergency_response_safety_system_ambulance_side/widgets/bottom_nav.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  StreamSubscription<DatabaseEvent>? _patientSubscription;
  StreamSubscription<Position>? _positionSubscription;
  final MapController _mapController = MapController();
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastRouteFetch;
  Position? _currentPosition;
  bool _hasUserInteractedWithMap = false;
  double _lastZoom = 13.0;
  Map<String, dynamic>? _victimDetails;

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

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _routeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _routeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _routeController, curve: Curves.easeIn));
    _routeController.forward();

    _mapController.mapEventStream.listen((event) {
      if (event is MapEventMove) {
        _hasUserInteractedWithMap = true;
      } else if (_mapController.camera.zoom != _lastZoom) {
        _hasUserInteractedWithMap = true;
        _lastZoom = _mapController.camera.zoom;
      }
    });

    Future.microtask(() {
      if (!mounted) return;
      _requestLocationPermission();
      _listenToRescuerUpdates();
      _listenToPatientUpdates();
      _fetchVictimDetails();
    });
  }

  @override
  void dispose() {
    _rescuerSubscription?.cancel();
    _patientSubscription?.cancel();
    _positionSubscription?.cancel();
    _pulseController.dispose();
    _routeController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchVictimDetails() async {
    final database = FirebaseDatabase.instance.ref();
    final firestore = FirebaseFirestore.instance;
    try {
      // Fetch report data from Realtime Database
      final reportSnapshot =
          await database.child('reports/${widget.reportId}').get();
      if (!reportSnapshot.exists) {
        setState(() {
          _errorMessage = "No victim details found";
          _isLoading = false;
        });
        return;
      }

      final reportData = reportSnapshot.value as Map<dynamic, dynamic>;
      final reportedBy = reportData['reportedBy']?.toString();

      // Initialize victim details with report data
      Map<String, dynamic> victimDetails = {
        'type': reportData['type']?.toString() ?? 'Unknown',
        'notes': reportData['notes']?.toString() ?? 'No notes provided',
        'reportedBy': reportedBy ?? 'Unknown',
        'timestamp': reportData['timestamp']?.toString() ?? 'N/A',
        'fullName': 'Not provided',
        'address': 'Not provided',
        'phone': 'Not provided',
        'emergencyContact': 'Not provided',
        'bloodType': 'Not provided',
        'allergies': 'Not provided',
        'medicalConditions': 'Not provided',
      };

      // Fetch user data from Firestore if reportedBy is available
      if (reportedBy != null && reportedBy.isNotEmpty) {
        final userDoc =
            await firestore.collection('users').doc(reportedBy).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          victimDetails.addAll({
            'fullName': userData['fullName']?.toString() ?? 'Not provided',
            'address': userData['address']?.toString() ?? 'Not provided',
            'phone': userData['phone']?.toString() ?? 'Not provided',
            'emergencyContact':
                userData['emergencyContact']?.toString() ?? 'Not provided',
            'bloodType': userData['bloodType']?.toString() ?? 'Not provided',
            'allergies': userData['allergies']?.toString() ?? 'Not provided',
            'medicalConditions':
                userData['medicalConditions']?.toString() ?? 'Not provided',
          });
        }
      }

      setState(() {
        _victimDetails = victimDetails;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error fetching victim details: $e";
        _isLoading = false;
      });
    }
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
        distanceFilter: 10,
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
          await database
              .child('reports/${widget.reportId}/assignedRescuer/${user.uid}')
              .update(updateData);
          await database.child('activeRescuers/${user.uid}').update(updateData);
          final reportStatus =
              trackingState.getStatusStep(widget.reportId) == 0
                  ? 'accepted'
                  : trackingState.getStatusStep(widget.reportId) == 1
                  ? 'arrived'
                  : trackingState.getStatusStep(widget.reportId) == 2
                  ? 'arrived'
                  : 'completed';
          await database.child('reports/${widget.reportId}').update({
            'status': reportStatus,
          });
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
                } else if (status == 'arrived' && newStatusStep < 2) {
                  newStatusStep = 2;
                } else if (status == 'arrived' && newStatusStep < 3) {
                  newStatusStep = 3;
                }
                trackingState.updateStatus(widget.reportId, newStatusStep);

                final reportStatus =
                    newStatusStep == 0
                        ? 'accepted'
                        : newStatusStep == 1
                        ? 'arrived'
                        : newStatusStep == 2
                        ? 'arrived'
                        : 'completed';
                database.child('reports/${widget.reportId}').update({
                  'status': reportStatus,
                });

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
    final etaSeconds = (distance / 11.11).round();
    return etaSeconds.clamp(60, 900);
  }

  void _generateRoutePoints() async {
    if (_lastRouteFetch != null &&
        DateTime.now().difference(_lastRouteFetch!).inSeconds < 10) {
      return;
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
          _errorMessage = "Failed to fetch route";
        });
      }
    }
  }

  void _recenterMap() {
    final trackingState = Provider.of<TrackingState>(context, listen: false);
    final rescuerLoc = trackingState.getRescuerLocation(widget.reportId);
    if (rescuerLoc == null) return;

    final bounds = LatLngBounds.fromPoints([_patientLocation, rescuerLoc]);
    _mapController.fitBounds(
      bounds,
      options: const FitBoundsOptions(padding: EdgeInsets.all(100)),
    );
    _hasUserInteractedWithMap = false;
    _lastZoom = _mapController.camera.zoom;
  }

  Future<void> _updateStatus(int newStatusStep) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final trackingState = Provider.of<TrackingState>(context, listen: false);
    final database = FirebaseDatabase.instance.ref();
    final statusString = newStatusStep == 0 ? 'en_route' : 'arrived';
    final reportStatus =
        newStatusStep == 0
            ? 'accepted'
            : newStatusStep == 1
            ? 'arrived'
            : newStatusStep == 2
            ? 'arrived'
            : 'completed';

    try {
      await database
          .child('reports/${widget.reportId}/assignedRescuer/${user.uid}')
          .update({'status': statusString});
      await database.child('activeRescuers/${user.uid}').update({
        'status': statusString,
      });
      await database.child('reports/${widget.reportId}').update({
        'status': reportStatus,
      });
      trackingState.updateStatus(widget.reportId, newStatusStep);
      setState(() {
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error updating status: $e";
      });
    }
  }

  void _showVictimDetailsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Victim Details',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 20.sp),
                    if (_victimDetails != null) ...[
                      _buildDetailContainer(
                        'Full Name',
                        _victimDetails!['fullName'],
                      ),
                      _buildDetailContainer(
                        'Address',
                        _victimDetails!['address'],
                      ),
                      _buildDetailContainer('Phone', _victimDetails!['phone']),
                      _buildDetailContainer(
                        'Emergency Contact',
                        _victimDetails!['emergencyContact'],
                      ),
                      _buildDetailContainer(
                        'Blood Type',
                        _victimDetails!['bloodType'],
                      ),
                      _buildDetailContainer(
                        'Allergies',
                        _victimDetails!['allergies'],
                      ),
                      _buildDetailContainer(
                        'Medical Conditions',
                        _victimDetails!['medicalConditions'],
                      ),
                      _buildDetailContainer(
                        'Emergency Type',
                        _victimDetails!['type'],
                      ),
                      _buildDetailContainer('Notes', _victimDetails!['notes']),
                      _buildDetailContainer(
                        'Reported By',
                        _victimDetails!['reportedBy'],
                      ),
                      _buildDetailContainer(
                        'Reported At',
                        _victimDetails!['timestamp'],
                      ),
                    ] else
                      Text(
                        'No details available',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    SizedBox(height: 20.sp),
                    Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailContainer(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ListTile(
          title: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          subtitle: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusSelectionModal() {
    final trackingState = Provider.of<TrackingState>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Status',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20.sp),
              ..._statuses.asMap().entries.map((entry) {
                final index = entry.key;
                final status = entry.value;
                return ListTile(
                  leading: Icon(status['icon'], color: status['color']),
                  title: Text(
                    status['text'],
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color:
                          trackingState.getStatusStep(widget.reportId) == index
                              ? status['color']
                              : Colors.grey[800],
                    ),
                  ),
                  onTap: () {
                    _updateStatus(index);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              SizedBox(height: 10.h),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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
                SizedBox(width: 15.w),
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
                        fontSize: 15.sp,
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
                SizedBox(height: 10.h),
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
                          fontSize: 14.sp,
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
                              SizedBox(width: 14.sp),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _statuses[trackingState.getStatusStep(
                                        widget.reportId,
                                      )]["text"],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "Rescuer Unit #${FirebaseAuth.instance.currentUser?.uid.substring(0, 6)}",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.sp,
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
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15.h),
                          Container(
                            height: 6.h,
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
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (_victimDetails?['phone'] != null &&
                                        _victimDetails!['phone'] !=
                                            'Not provided') {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Phone call feature not implemented. Number: ${_victimDetails!['phone']}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Victim phone number not available',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.green[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.call,
                                          color: Colors.green[700],
                                          size: 20,
                                        ),
                                        SizedBox(width: 3.w),
                                        Text(
                                          "Call Victim",
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.green[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showVictimDetailsModal,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.blue[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue[700],
                                          size: 20,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          "Victim Details",
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6.w),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showStatusSelectionModal,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orange[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.update,
                                          color: Colors.orange[700],
                                          size: 20,
                                        ),
                                        SizedBox(width: 8.h),
                                        Text(
                                          "Update Status",
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.orange[700],
                                          ),
                                        ),
                                      ],
                                    ),
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
