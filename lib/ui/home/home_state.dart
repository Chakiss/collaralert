import 'package:elephant_collar/model/collar_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeState {
  final HomeStatus status;
  final List<CollarModel>? list;
  final LatLng currentLocation;

  HomeState({
    this.status = HomeStatus.initial,
    this.list,
    this.currentLocation = const LatLng(0.000, 0.000),
  });

  HomeState copyWith({
    HomeStatus? status,
    List<CollarModel>? list,
    LatLng? currentLocation,
  }) {
    return HomeState(
        status: status ?? this.status,
        list: list ?? this.list,
        currentLocation: currentLocation ?? this.currentLocation);
  }
}

enum HomeStatus {
  initial,
  onGetCurrentLocation,
  onGetCurrentLocationWithCollarsLocation
}
