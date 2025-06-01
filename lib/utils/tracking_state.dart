import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class TrackingState with ChangeNotifier {
  final Map<String, Map<String, dynamic>> _trackingData = {};

  LatLng? getRescuerLocation(String reportId) =>
      _trackingData[reportId]?['rescuerLocation'] as LatLng?;
  int getEtaSeconds(String reportId) =>
      _trackingData[reportId]?['etaSeconds'] as int? ?? 300;
  int getStatusStep(String reportId) =>
      _trackingData[reportId]?['statusStep'] as int? ?? 0;
  List<LatLng> getRoutePoints(String reportId) =>
      _trackingData[reportId]?['routePoints'] as List<LatLng>? ?? [];

  void updateRescuerLocation(String reportId, LatLng? location) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['rescuerLocation'] = location;
    notifyListeners();
  }

  void updateEta(String reportId, int eta) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['etaSeconds'] = eta;
    notifyListeners();
  }

  void updateStatus(String reportId, int step) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['statusStep'] = step;
    notifyListeners();
  }

  void updateRoutePoints(String reportId, List<LatLng> points) {
    _trackingData.putIfAbsent(reportId, () => {});
    _trackingData[reportId]!['routePoints'] = points;
    notifyListeners();
  }

  void clearReport(String reportId) {
    _trackingData.remove(reportId);
    notifyListeners();
  }
}
