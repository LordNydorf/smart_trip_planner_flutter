import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authControllerProvider = StateNotifierProvider<AuthController, User?>((
  ref,
) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<User?> {
  final Ref _ref;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  AuthController(this._ref) : super(null) {
    _ref.read(firebaseAuthProvider).authStateChanges().listen((user) {
      state = user;
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _ref
          .read(firebaseAuthProvider)
          .signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await _ref
          .read(firebaseAuthProvider)
          .createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _ref.read(firebaseAuthProvider).signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _ref
          .read(firebaseAuthProvider)
          .sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Failed to send password reset email: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await _ref.read(firebaseAuthProvider).signInWithCredential(credential);
    } on Exception catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  Future<void> signUpWithGoogle() async {
    await signInWithGoogle();
  }
}
