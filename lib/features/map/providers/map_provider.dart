import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/map_service.dart';

final mapServiceProvider = Provider<MapService>((ref) {
  return MapService();
});

final currentLocationProvider = FutureProvider<Position>((ref) {
  return ref.watch(mapServiceProvider).getCurrentLocation();
});
