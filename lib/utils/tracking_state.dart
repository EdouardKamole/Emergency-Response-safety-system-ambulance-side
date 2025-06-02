import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TrackingState extends ChangeNotifier {
  final Map<String, Map<String, dynamic>> _trackingData = {};

  void updateRescuerLocation(String reportId, LatLng location) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['rescuerLocation'] = location;
    notifyListeners();
  }

  void updateVictimLocation(String reportId, LatLng location) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['victimLocation'] = location;
    notifyListeners();
  }

  void updateRoutePoints(String reportId, List<LatLng> routePoints) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['routePoints'] = routePoints;
    notifyListeners();
  }

  void updateEta(String reportId, int etaSeconds) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['etaSeconds'] = etaSeconds;
    notifyListeners();
  }

  void updateStatus(String reportId, int statusStep) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['statusStep'] = statusStep;
    notifyListeners();
  }

  LatLng? getRescuerLocation(String reportId) {
    return _trackingData[reportId]?['rescuerLocation'] as LatLng?;
  }

  LatLng? getVictimLocation(String reportId) {
    return _trackingData[reportId]?['victimLocation'] as LatLng?;
  }

  List<LatLng> getRoutePoints(String reportId) {
    return (_trackingData[reportId]?['routePoints'] as List<LatLng>?) ?? [];
  }

  int getEtaSeconds(String reportId) {
    return (_trackingData[reportId]?['etaSeconds'] as int?) ?? 300;
  }

  int getStatusStep(String reportId) {
    return (_trackingData[reportId]?['statusStep'] as int?) ?? 0;
  }
}
