import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elephant_collar/ui/home/home_cubit.dart';
import 'package:elephant_collar/ui/home/home_state.dart';
import 'package:elephant_collar/utils/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    GoogleMapController? googleMapController;
    return Scaffold(
      body: SafeArea(
        child: BlocProvider(
          create: (context) => HomeCubit(firestore: FirebaseFirestore.instance)
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
                  Expanded(
                      child: ListView.builder(
                    itemCount: state.list?.length ?? 0,
                    itemBuilder: (context, index) {
                      final collar = state.list![index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Collar ID : ${collar.id}"),
                                const SizedBox(width: 24),
                                Expanded(
                                    child: Text(
                                        "Distance: ${MapUtils.getDistance(state.currentLocation, collar.latLng)}"))
                              ],
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
