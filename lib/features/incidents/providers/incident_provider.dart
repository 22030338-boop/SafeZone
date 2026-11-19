import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/incident_service.dart';

final incidentServiceProvider = Provider<IncidentService>((ref) {
  return IncidentService();
});

final incidentsStreamProvider = StreamProvider((ref) {
  return ref.watch(incidentServiceProvider).getIncidentsStream();
});