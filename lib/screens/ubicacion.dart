import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UbicacionMascota extends StatefulWidget {
  final int idMascota;
  const UbicacionMascota({super.key, required this.idMascota});

  @override
  State<UbicacionMascota> createState() => _UbicacionMascotaState();
}

class _UbicacionMascotaState extends State<UbicacionMascota> {
  late GoogleMapController mapController;

  // Ubicación simulada inicial
  LatLng mascotaPosicion = const LatLng(4.60971, -74.08175); // Bogotá centro

  void actualizarUbicacion() {
    setState(() {
      // Cambia a una ubicación aleatoria simulada
      mascotaPosicion = LatLng(
        mascotaPosicion.latitude + 0.0005,
        mascotaPosicion.longitude + 0.0005,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ubicación de mi mascota")),
      body: GoogleMap(
        onMapCreated: (controller) => mapController = controller,
        initialCameraPosition: CameraPosition(
          target: mascotaPosicion,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("mascota"),
            position: mascotaPosicion,
            infoWindow: const InfoWindow(title: "Mi mascota"),
          )
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: actualizarUbicacion,
        child: const Icon(Icons.location_searching),
      ),
    );
  }
}
