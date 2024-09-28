import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapUtils {
  static double getDistance(
    LatLng location1,
    LatLng location2,
  ) {
    var earthRadiusKm = 6371.0;

    var dLat = (location2.latitude - location1.latitude) * math.pi / 180.0;
    var dLon = (location2.longitude - location1.longitude) * math.pi / 180.0;

    var lat1 = (location1.latitude) * math.pi / 180.0;
    var lat2 = (location2.latitude) * math.pi / 180.0;

    var a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    var c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return (earthRadiusKm * c) * 1000; // return distance in meters
  }

  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;

    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }

    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }
}
