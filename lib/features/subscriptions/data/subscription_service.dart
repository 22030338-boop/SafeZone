import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> crearSuscripcion({
    required String planId,
    required String planName,
    required int price,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Debes iniciar sesión para continuar.');
    }

    final subscriptionsRef = _firestore.collection('subscriptions');
    final newSubscriptionRef = subscriptionsRef.doc();

    // Consultar las suscripciones anteriores del usuario.
    final previousSubscriptions = await subscriptionsRef
        .where('userId', isEqualTo: user.uid)
        .get();

    // Ejecutar las modificaciones y el nuevo registro
    // dentro de una misma transacción.
    await _firestore.runTransaction((transaction) async {
      for (final document in previousSubscriptions.docs) {
        final data = document.data();

        if (data['status'] == 'active') {
          transaction.update(document.reference, {
            'status': 'replaced',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      transaction.set(newSubscriptionRef, {
        'userId': user.uid,
        'userEmail': user.email,
        'planId': planId,
        'planName': planName,
        'price': price,
        'currency': 'MXN',
        'billingPeriod': price == 0 ? 'free' : 'monthly',
        'status': 'active',
        'paymentStatus': price == 0 ? 'not_required' : 'simulated',
        'paymentMethod': 'academic_simulation',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return newSubscriptionRef.id;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> obtenerSuscripcionesUsuario() {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Debes iniciar sesión para consultar tus suscripciones.',
      );
    }

    return _firestore
        .collection('subscriptions')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
  }
}
