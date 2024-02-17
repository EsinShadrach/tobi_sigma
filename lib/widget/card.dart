import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tobi_sigma/api/get_near_hospitals.dart';
import 'package:tobi_sigma/screens/map_screen.dart';

class LocationCard extends StatelessWidget {
  const LocationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: NearByHospital().getNearByHospitals(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error: ${snapshot.error}",
            ),
          );
        }

        if (snapshot.hasData) {
          return GridView.builder(
            itemCount: snapshot.data!.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
            ),
            itemBuilder: (context, index) {
              var hospital = snapshot.data![index];

              return Card(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 420,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Center(
                          child: Text("Render Map here"),
                        ),
                      ),
                      Text(hospital.name),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextButton(
                          style: ButtonStyle(
                            minimumSize: MaterialStateProperty.all(
                              const Size(double.infinity, 50),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              CupertinoPageRoute(
                                builder: (context) => CupertinoPageScaffold(
                                  child: MapScreen(
                                    address: hospital.address,
                                    showBottom: true,
                                    destination: LatLng(
                                      hospital.latitude,
                                      hospital.longitude,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text("View full Map"),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const Text("NO DATA");
      },
    );
  }
}
