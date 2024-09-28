import 'package:elephant_collar/ui/home/home_cubit.dart';
import 'package:elephant_collar/ui/home/home_state.dart';
import 'package:elephant_collar/utils/map_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as time_ago;

class HomePage extends StatefulWidget with WidgetsBindingObserver {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final decimalFormat = NumberFormat("#,###.##");
    GoogleMapController? googleMapController;
    context.read<HomeCubit>()
      ..loginAnonymously()
      ..requestLocationPermission()
      ..getCollarsLocation();
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        Fluttertoast.showToast(
            msg: "ระบบกำลังบันทึกตัวแหน่งล่าสุดของท่านและออกจากแอพพลิเคชั่น",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 2,
            backgroundColor: Colors.black,
            textColor: Colors.white,
            fontSize: 16.0);
        context.read<HomeCubit>().getCurrentLocation().then((value) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          });
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Collar Alert"),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.refresh_outlined,
                color: Colors.black,
              ),
              onPressed: () {
                final cubit = context.read<HomeCubit>();
                cubit
                    .getCurrentLocation()
                    .then((value) => cubit.getCollarsLocation());
              },
            )
          ],
        ),
        body: SafeArea(
          bottom: false,
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
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                          text: 'Collar ID: ', // Normal text
                                        ),
                                        TextSpan(
                                          text: '${collar.id}', // Bold text
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
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
                                    // Check the distance and format accordingly
                                    () {
                                      final distance = MapUtils.getDistance(
                                          state.currentLocation, collar.latLng);
                                      if (distance < 1000) {
                                        return "${decimalFormat.format(distance)} M."; // Display in meters
                                      } else {
                                        return "${decimalFormat.format(distance / 1000)} KM."; // Display in kilometers
                                      }
                                    }(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getTextColorByDistance(
                                        MapUtils.getDistance(
                                            state.currentLocation,
                                            collar.latLng),
                                      ),
                                    ),
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
                                        "Latitude: ${state.currentLocation.latitude}"))
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        "Longitude:  ${state.currentLocation.longitude}"))
                              ],
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            // Row(
                            //   children: [
                            //     Expanded(
                            //         child: Text(
                            //             "Voltage Produced: ${collar.voltageProduced}"))
                            //   ],
                            // ),
                            // const SizedBox(
                            //   height: 4,
                            // ),
                            // Row(
                            //   children: [
                            //     Expanded(
                            //         child: Text(
                            //             "Voltage Produced: ${collar.voltageUsed}"))
                            //   ],
                            // ),
                            // const SizedBox(
                            //   height: 4,
                            // ),
                            Row(
                              children: [
                                Expanded(
                                    child: Text(
                                        "Last Update: ${collar.dateTime?.toDate() != null ? time_ago.format(collar.dateTime!.toDate()) : ""}"))
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

  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        context.read<HomeCubit>().onPause();
        break;
      case AppLifecycleState.detached:
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }
}

Color? _getTextColorByDistance(double distance) {
  if (distance >= 801) {
    return Colors.green;
  }
  if (distance >= 501 && distance <= 800) {
    return Colors.yellow;
  }
  if (distance >= 251 && distance <= 500) {
    return Colors.orange;
  }
  if (distance >= 0 && distance <= 500) {
    return Colors.red;
  }
  return null;
}
