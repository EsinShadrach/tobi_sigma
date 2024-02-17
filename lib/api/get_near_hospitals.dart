import 'dart:convert';
import 'dart:developer' as developer;
import 'package:async/async.dart';
import 'package:http/http.dart' as http;

import 'package:location/location.dart';
import 'package:tobi_sigma/constants/g_map_api_key.dart';

class NearByHospital {
  final Location location = Location();
  List<Hospital> hospitals = [];
  static final _memoizer = AsyncMemoizer();

  Future<List<Hospital>?> _getNearByHospitals() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    try {
      final LocationData locationResult = await location.getLocation();
      developer.log('app.location: $locationResult');
      // Fetch nearby hospitals using Google Places API
      const String apiKey = Constants.googleMapKey;
      const String baseUrl =
          "https://maps.googleapis.com/maps/api/place/nearbysearch/json";

      final response = await http.get(
        Uri.parse(
          '$baseUrl?location=${locationResult.latitude},${locationResult.longitude}&radius=1500&type=hospital&key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          developer.log(
            "Okay!",
            name: "app.hospital",
          );
          // Process the data as needed
          List<dynamic> results = data['results'];
          for (var result in results) {
            hospitals.add(Hospital.fromJson(result));
            developer.log(
              "Hospital Name: $result",
              name: "app.hospital",
            );
          }
        } else {
          developer.log(
            "Error: ${data['status']}",
            name: "app.hospital",
          );
        }
      } else {
        developer.log(
          "Error: ${response.statusCode}",
          name: "app.hospital",
        );
      }
    } catch (e) {
      developer.log('Error: $e');
    }
    return hospitals;
  }

  Future<List<Hospital>> getNearByHospitals() async {
    return await _memoizer.runOnce(
      () async => await _getNearByHospitals(),
    );
  }
}

class Hospital {
  final String name;
  final double latitude;
  final double longitude;
  final String address;

  Hospital({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      name: json['name'] ?? '',
      latitude: json['geometry']['location']['lat'] ?? 0.0,
      longitude: json['geometry']['location']['lng'] ?? 0.0,
      address: json['vicinity'] ?? 'N/A',
    );
  }
}
