import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CollarModel {
  final String id;
  final LatLng latLng;

  CollarModel({required this.id, required this.latLng});

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
            snapshot["latitude"] as double, snapshot["longitude"] as double));
  }
}
