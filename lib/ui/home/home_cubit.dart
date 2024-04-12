import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elephant_collar/model/collar_model.dart';
import 'package:elephant_collar/ui/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeCubit extends Cubit<HomeState> {
  final FirebaseFirestore firestore;
  final Location location;

  HomeCubit({required this.firestore, required this.location})
      : super(HomeState());

  Future<void> requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever) {
      if (await Geolocator.isLocationServiceEnabled()) {
        final location = await Geolocator.getCurrentPosition();
        emit(state.copyWith(
            status: state.list?.isNotEmpty == true
                ? HomeStatus.onGetCurrentLocationWithCollarsLocation
                : HomeStatus.onGetCurrentLocation,
            currentLocation: LatLng(location.latitude, location.longitude)));
      } else {
        final enable = await location.requestService();
        if (enable) {
          await requestLocationPermission();
        }
      }
    } else {
      await Geolocator.requestPermission();
      await requestLocationPermission();
    }
  }

  Future<void> getCollarsLocation() async {
    final List<CollarModel> list = [];
    final collars = await firestore.collection("Collars").get();
    await Future.forEach(collars.docs, (element) async {
      final snapshot = await element.reference
          .collection("latest_location")
          .doc("current")
          .get();
      if (snapshot.exists) {
        final latitude = snapshot["latitude"] as double?;
        final longitude = snapshot["longitude"] as double?;
        if (latitude != null && longitude != null) {
          list.add(CollarModel.fromSnapshot(element.id, snapshot));
        }
      }
    });
    if (state.currentLocation.latitude != 0.000 &&
        state.currentLocation.longitude != 0.000) {
      emit(state.copyWith(
          status: HomeStatus.onGetCurrentLocationWithCollarsLocation,
          list: list));
    } else {
      emit(state.copyWith(status: HomeStatus.initial, list: list));
    }
  }
}
