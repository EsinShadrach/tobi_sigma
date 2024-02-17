import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:tobi_sigma/constants/g_map_api_key.dart';
import 'package:tobi_sigma/extensions/on_context.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.destination,
    required this.address,
    this.showBottom,
  });

  final LatLng destination;
  final String address;
  final bool? showBottom;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  double distanceInMeters = 0.0;
  double initialDistanceCapture = 0.0;

  // Get Delivery location from api
  late final LatLng destination;
  LocationData? currentLocation;
  List<LatLng> polylineCoordinates = [];

  void _updateDistance() {
    if (currentLocation != null) {
      distanceInMeters = calculateDistance(
        currentLocation!.latitude!,
        currentLocation!.longitude!,
        destination.latitude,
        destination.longitude,
      );
      debugPrint("Distance: $distanceInMeters meters");
    }
  }

  /// Calculate distance between two points Via Haversine formula
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const double earthRadius = 6371000.0; // Earth's radius in meters
    double dLat = radians(endLatitude - startLatitude);
    double dLon = radians(endLongitude - startLongitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(radians(startLatitude)) *
            cos(radians(endLatitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double distance = earthRadius * c;
    return distance;
  }

  double radians(double degrees) {
    return degrees * (pi / 180);
  }

  _getLocation() async {
    Location location = Location();
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    try {
      var locationData = await location.getLocation();
      setState(() {
        currentLocation = locationData;
        initialDistanceCapture = calculateDistance(
          currentLocation!.latitude!,
          currentLocation!.longitude!,
          destination.latitude,
          destination.longitude,
        );
      });
      debugPrint("Location: $currentLocation");
      GoogleMapController googleMapController = await _controller.future;
      location.onLocationChanged.listen((LocationData currLocation) {
        googleMapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                currLocation.latitude!,
                currLocation.longitude!,
              ),
              zoom: 14.4746,
            ),
          ),
        );

        setState(() {
          currentLocation = currLocation;
          _getPolyPoints();
          _updateDistance();
        });
      });
    } catch (e) {
      developer.log(
        "$e",
        name: "main.app.map",
        error: e,
        level: 200,
      );
    }
  }

  void _getPolyPoints() async {
    List<LatLng> pCordinates = [];
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      Constants.googleMapKey,
      PointLatLng(currentLocation!.latitude!, currentLocation!.longitude!),
      PointLatLng(destination.latitude, destination.longitude),
    );

    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        pCordinates.add(LatLng(point.latitude, point.longitude));
      }
    }
    setState(() {
      polylineCoordinates = pCordinates;
    });
  }

  @override
  void initState() {
    destination = widget.destination;
    _getLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double progressPercentage = ((initialDistanceCapture - distanceInMeters) /
            initialDistanceCapture *
            100)
        .clamp(0.0, 100.0);
    return CupertinoPageScaffold(
      child: currentLocation == null
          ? const Center(
              child: CircularProgressIndicator.adaptive(),
            )
          : Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('polyLineId'),
                        color: context.colorScheme.primary,
                        width: 9,
                        points: polylineCoordinates,
                      ),
                    },
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        currentLocation!.latitude!,
                        currentLocation!.longitude!,
                      ),
                      zoom: 14.4746,
                    ),
                    markers: {
                      Marker(
                        markerId: const MarkerId('currentLocation'),
                        position: LatLng(
                          currentLocation?.latitude ?? 0,
                          currentLocation?.longitude ?? 0,
                        ),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueBlue,
                        ),
                        flat: true,
                        infoWindow: InfoWindow(
                          title: "Your Location",
                          snippet:
                              "Distance: ${distanceInMeters.toStringAsFixed(2)} meters",
                        ),
                        rotation: currentLocation?.heading ?? 0,
                      ),
                      Marker(
                        markerId: const MarkerId('destinationPin'),
                        position: destination,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          BitmapDescriptor.hueGreen,
                        ),
                      ),
                    },
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                  ),
                ),
                widget.showBottom == true
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: SafeArea(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.all(10),
                            constraints: const BoxConstraints(
                              maxWidth: 470,
                            ),
                            decoration: BoxDecoration(
                              color: context.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // This Translate Based on the percentage of the distance
                                Transform.translate(
                                  offset: Offset(
                                      (progressPercentage / 100) *
                                          MediaQuery.of(context).size.width,
                                      0.0),
                                  child: const RotatedBox(
                                    quarterTurns: 1,
                                    child: Icon(Icons.car_rental),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  // Value is the percentage of the distance
                                  value: (progressPercentage / 100).clamp(0, 1),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    context.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "Destination",
                                  style:
                                      context.textTheme.titleMedium!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  widget.address,
                                  style: context.textTheme.bodyLarge,
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  "Approximately: ${distanceInMeters.toStringAsFixed(2)} meters",
                                  // Text Color should change based on the percentage of the distance
                                  style: context.textTheme.bodyMedium!.copyWith(
                                    color: const Color(0xFF3BB54A),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
    );
  }
}
