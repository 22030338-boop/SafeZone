import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class EmergencyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> sendEmergencyAlert() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    // Comprobar que el GPS esté habilitado.
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Activa el GPS de tu dispositivo.');
    }

    // Comprobar permisos de ubicación.
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('No se concedió el permiso de ubicación.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'El permiso de ubicación está bloqueado. '
        'Actívalo desde los ajustes del dispositivo.',
      );
    }

    // Obtener la ubicación actual.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // Crear el registro de emergencia.
    final document = await _firestore
        .collection('emergency_alerts')
        .add({
      'userId': user.uid,
      'userEmail': user.email,
      'userName': user.displayName ?? 'Usuario SafeZone',
      'latitude': position.latitude,
      'longitude': position.longitude,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }
}
