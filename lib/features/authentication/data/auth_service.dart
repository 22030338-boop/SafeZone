import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static Future<void>? _googleInitialization;

  // Obtener el usuario actualmente autenticado.
  User? get currentUser => _auth.currentUser;

  // Escuchar cambios en el estado de autenticación.
  Stream<User?> get authStateChanges => _auth.userChanges();


  Future<UserCredential> signInWithGoogle() async {
    // Inicializar Google Sign-In una sola vez.
    _googleInitialization ??= GoogleSignIn.instance.initialize();

    await _googleInitialization;

    // Abrir selector de cuentas de Google.
    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    // Obtener el token de autenticación.
    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('No se pudo obtener el token de Google.');
    }

    // Crear credencial compatible con Firebase.
    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    // Autenticar al usuario en Firebase.
    final userCredential = await _auth.signInWithCredential(
      credential,
    );

    return userCredential;
  }


  // Registrar usuario con correo y contraseña.
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user?.updateDisplayName(name.trim());

    await credential.user?.sendEmailVerification();

    return credential;
  }

  // Iniciar sesión.
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Cerrar sesión.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Reenviar correo de verificación.
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No hay ningún usuario autenticado.');
    }

    if (user.emailVerified) {
      throw Exception('El correo ya está verificado.');
    }

    await user.sendEmailVerification();
  }

  // Enviar recuperación de contraseña.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  // Actualizar nombre del usuario.
  Future<void> updateName(String name) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No hay ningún usuario autenticado.');
    }

    await user.updateDisplayName(name.trim());
    await user.reload();
  }

  // Actualizar fotografía de perfil.
  Future<void> updatePhoto(String photoUrl) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No hay ningún usuario autenticado.');
    }

    await user.updatePhotoURL(photoUrl);
    await user.reload();
  }
}
