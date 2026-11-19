import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class IncidentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getIncidentsStream() {
    return _firestore
        .collection('incidents')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<Map<String, double>> _getLocation() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Activa el GPS de tu dispositivo.');
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('No se concedió el permiso de ubicación.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  Future<String> createIncident({
    required String title,
    required String description,
    required String category,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    if (title.trim().isEmpty || description.trim().isEmpty) {
      throw Exception('Completa todos los campos obligatorios.');
    }

    final location = await _getLocation();

    final document =
        await _firestore.collection('incidents').add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Usuario SafeZone',
      'userEmail': user.email,
      'title': title.trim(),
      'description': description.trim(),
      'category': category,
      'photoUrl': photoUrl,
      'latitude': location['latitude'],
      'longitude': location['longitude'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }
}
