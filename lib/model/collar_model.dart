import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CollarModel {
  final String id;
  final LatLng latLng;
  final double currentProduced;
  final double currentUsed;
  final double voltageProduced;
  final double voltageUsed;
  final Timestamp? dateTime;

  CollarModel(
      {required this.id,
      required this.latLng,
      required this.currentProduced,
      required this.currentUsed,
      required this.voltageProduced,
      required this.voltageUsed,
      this.dateTime});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "latLng": latLng,
    };
  }

  factory CollarModel.fromSnapshot(
      String id, DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return CollarModel(
        id: id,
        latLng: LatLng(
            snapshot["latitude"] as double, snapshot["longitude"] as double),
        currentProduced: _getNumberValue(snapshot["current_produced"]),
        currentUsed: _getNumberValue(snapshot["current_used"]),
        voltageProduced: _getNumberValue(snapshot["voltage_produced"]),
        voltageUsed: _getNumberValue(snapshot["voltage_used"]),
        dateTime: snapshot["date_time"] as Timestamp?);
  }
}

double _getNumberValue(dynamic value) {
  if (value is int?) {
    return (value)?.toDouble() ?? 0.00;
  } else {
    return value as double? ?? 0.00;
  }
}
