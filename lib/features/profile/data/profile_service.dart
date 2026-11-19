
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  // Crear o actualizar el perfil del usuario autenticado.
  Future<void> createOrUpdateProfile(User user) async {
    final document = _users.doc(user.uid);
    final snapshot = await document.get();

    final profileData = <String, dynamic>{
      'name': user.displayName ?? 'Usuario SafeZone',
      'email': user.email ?? '',
      'photoUrl': user.photoURL,
      'provider': user.providerData.isNotEmpty
          ? user.providerData.first.providerId
          : 'password',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snapshot.exists) {
      profileData['createdAt'] = FieldValue.serverTimestamp();
    }

    await document.set(
      profileData,
      SetOptions(merge: true),
    );
  }

  // Obtener el perfil del usuario.
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();

    if (!snapshot.exists) return null;

    return snapshot.data();
  }

  // Actualizar el nombre.
  Future<void> updateName(String name) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      throw Exception('El nombre no puede estar vacío.');
    }

    await user.updateDisplayName(cleanName);

    await _users.doc(user.uid).update({
      'name': cleanName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Actualizar la fotografía.
  Future<void> updatePhoto(String photoUrl) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No hay una sesión activa.');
    }

    await user.updatePhotoURL(photoUrl);

    await _users.doc(user.uid).update({
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
