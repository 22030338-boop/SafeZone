import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../providers/map_provider.dart';
import '../../incidents/providers/incident_provider.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationAsync = ref.watch(currentLocationProvider);
    final incidentsAsync = ref.watch(incidentsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de seguridad'),
      ),
      body: locationAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_off,
                  size: 55,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    ref.invalidate(currentLocationProvider);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (position) {
          final currentPosition = LatLng(
            position.latitude,
            position.longitude,
          );

          // Marcador de la ubicación actual.
          final markers = <Marker>{
            Marker(
              markerId: const MarkerId('current_location'),
              position: currentPosition,
              infoWindow: const InfoWindow(
                title: 'Tu ubicación',
                snippet: 'Estás aquí',
              ),
            ),
          };

          // Agregar los incidentes recibidos desde Firestore.
          incidentsAsync.whenData((snapshot) {
            for (final document in snapshot.docs) {
              final data = document.data();

              final latitude = data['latitude'];
              final longitude = data['longitude'];

              if (latitude is! num || longitude is! num) {
                continue;
              }

              final incidentPosition = LatLng(
                latitude.toDouble(),
                longitude.toDouble(),
              );

              final title =
                  data['title']?.toString() ?? 'Incidente reportado';

              final category =
                  data['category']?.toString() ?? 'Sin categoría';

              final status =
                  data['status']?.toString() ?? 'Sin estado';

              markers.add(
                Marker(
                  markerId: MarkerId(document.id),
                  position: incidentPosition,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange,
                  ),
                  infoWindow: InfoWindow(
                    title: title,
                    snippet: '$category • Estado: $status',
                  ),
                ),
              );
            }
          });

          return GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentPosition,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: markers,
          );
        },
      ),
    );
  }
}
