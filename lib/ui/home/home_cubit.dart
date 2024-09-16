import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elephant_collar/model/collar_model.dart';
import 'package:elephant_collar/ui/home/home_state.dart';
import 'package:elephant_collar/utils/map_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeCubit extends Cubit<HomeState> {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final FirebaseMessaging firebaseMessaging;
  final Location location;
  final AudioPlayer audioPlayer;

  HomeCubit({
    required this.firebaseAuth,
    required this.firestore,
    required this.firebaseMessaging,
    required this.location,
    required this.audioPlayer,
  }) : super(HomeState());

  Future<void> loginAnonymously() async {
    if (firebaseAuth.currentUser == null) {
      final credential = await firebaseAuth.signInAnonymously();
      final userId = credential.user?.uid;
      if (userId?.isNotEmpty == true) {
        await firestore
            .collection("Users")
            .doc(userId!)
            .set({"date_time": Timestamp.now()});
      }
    } else {
      final token = await firebaseMessaging.getToken();
      await updateUserInformation({"fcm_token": token});
    }
  }

  Future<void> requestLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever) {
      if (await Geolocator.isLocationServiceEnabled()) {
        getCurrentLocation();
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

  Future<void> getCurrentLocation() async {
    final location = await Geolocator.getCurrentPosition();
    await updateUserInformation(
        {"latlong": GeoPoint(location.latitude, location.longitude)});
    emit(state.copyWith(
        status: state.list?.isNotEmpty == true
            ? HomeStatus.onGetCurrentLocationWithCollarsLocation
            : HomeStatus.onGetCurrentLocation,
        currentLocation: LatLng(location.latitude, location.longitude)));
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
      // for (var data in list) {
      //   if (MapUtils.getDistance(state.currentLocation, data.latLng) <= 500) {
      //     playSound();
      //     break;
      //   }
      // }
    } else {
      emit(state.copyWith(status: HomeStatus.initial, list: list));
    }
  }

  Future<void> playSound() async {
    if (!state.isPlayingSound && !state.isPause) {
      emit(state.copyWith(isPlayingSound: true));
      await audioPlayer.play(AssetSource(("sound/alert_sound.mp3")));
      emit(state.copyWith(isPlayingSound: false));
      await Future.delayed(const Duration(seconds: 23), () async {
        if (!state.isPause) {
          for (var data in state.list ?? []) {
            if (MapUtils.getDistance(state.currentLocation, data.latLng) <= 500) {
              playSound();
              break;
            }
          }
        }
      });
    }
  }

  Future<void> updateUserInformation(Map<String, dynamic> data) async {
    final userId = firebaseAuth.currentUser?.uid;
    if (userId?.isNotEmpty == true) {
      await firestore
          .collection("Users")
          .doc(userId!)
          .update(data..addAll({"last_update": Timestamp.now()}));
    }
  }

  void onPause() {
    emit(state.copyWith(isPause: true));
  }
}
