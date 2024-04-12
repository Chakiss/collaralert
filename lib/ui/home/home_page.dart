import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elephant_collar/ui/home/home_cubit.dart';
import 'package:elephant_collar/ui/home/home_state.dart';
import 'package:elephant_collar/utils/map_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    GoogleMapController? googleMapController;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Collar Alert"),
      ),
      body: SafeArea(
        bottom: false,
        child: BlocProvider(
          create: (context) => HomeCubit(
              firestore: FirebaseFirestore.instance, location: Location())
            ..requestLocationPermission()
            ..getCollarsLocation(),
          child: BlocConsumer<HomeCubit, HomeState>(
            listener: (context, state) {
              switch (state.status) {
                case HomeStatus.initial:
                  break;
                case HomeStatus.onGetCurrentLocation:
                  googleMapController?.moveCamera(
                      CameraUpdate.newLatLng(state.currentLocation));
                  break;
                case HomeStatus.onGetCurrentLocationWithCollarsLocation:
                  googleMapController?.moveCamera(CameraUpdate.newLatLngBounds(
                      MapUtils.boundsFromLatLngList(
                          state.list!.map((e) => e.latLng).toList()
                            ..add(state.currentLocation)),
                      20));
                  break;
              }
            },
            builder: (BuildContext context, state) {
              return Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: GoogleMap(
                        onMapCreated: (controller) {
                          googleMapController = controller;
                        },
                        initialCameraPosition: CameraPosition(
                          target: state.currentLocation,
                          zoom: 11.0,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        compassEnabled: true,
                        markers: (state.list ?? [])
                            .map((e) => Marker(
                                markerId: MarkerId(e.id), position: e.latLng))
                            .toSet(),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Expanded(
                      child: ListView.builder(
                    itemCount: state.list?.length ?? 0,
                    itemBuilder: (context, index) {
                      final collar = state.list![index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: Text("Collar ID : ${collar.id}")),
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                const Text("Distance: "),
                                Expanded(
                                  child: Text(
                                    "${MapUtils.getDistance(state.currentLocation, collar.latLng).toStringAsFixed(2)} KM",
                                    style: TextStyle(
                                        color: _getTextColorByDistance(
                                            MapUtils.getDistance(
                                                state.currentLocation,
                                                collar.latLng))),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        "Current Produced: ${collar.currentProduced}"))
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        "Current Used: ${collar.currentUsed}"))
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        "Voltage Produced: ${collar.voltageProduced}"))
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        "Voltage Produced: ${collar.voltageUsed}"))
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        "Last Update: ${collar.dateTime?.toDate() != null ? timeAgo.format(collar.dateTime!.toDate()) : ""}"))
                              ],
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Container(
                              width: double.infinity,
                              height: 0.5,
                              color: Colors.black.withOpacity(0.5),
                            )
                          ],
                        ),
                      );
                    },
                  ))
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Color? _getTextColorByDistance(double distance) {
  if (distance >= 801 && distance <= 999) {
    return Colors.green;
  }
  if (distance >= 501 && distance <= 800) {
    return Colors.yellow;
  }
  if (distance >= 251 && distance <= 500) {
    return Colors.red;
  }
  if (distance >= 0 && distance <= 500) {
    return Colors.red;
  }
  return null;
}
