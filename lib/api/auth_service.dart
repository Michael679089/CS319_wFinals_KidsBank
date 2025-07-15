import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/cupertino.dart';

import 'package:wfinals_kidsbank/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/user_model.dart';

class AuthService {
  final FirestoreAPI firestoreAPI = FirestoreAPI();

  // functions:

  // Create
  Future<Map<String, Object>?> createAccountToFirebaseAuth({
    required String email,
    required String password,
    required String familyName,
  }) async {
    UserCredential? userCredential;

    debugPrint("Creating an Auth Account...");
    try {
      userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      debugPrint("Auth Account created for: ${userCredential.user?.email}");
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      return null;
    }

    // ✅ At this point, we know userCredential is non-null
    final String userId = userCredential.user!.uid;
    final newUser = UserModel(
      userId: userId,
      familyName: familyName,
      email: email,
    );

    debugPrint("Check if email is legit");
    verifyEmail(userCredential.user);

    return {"status": "success", "user": newUser};
  }

  Future<void> verifyEmail(User? user) async {
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      debugPrint("Verification email sent to ${user.email}");
    }
  }

  /// Google Sign-In and saving to Firestore
  Future<UserCredential?> signInWithGoogle() async {
    debugPrint("sign-in with Google is called!");
    debugPrint("Attempting Google Sign-In...");

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        debugPrint("Google Sign-In canceled.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        debugPrint("Google user is null after sign-in.");
        return null;
      }

      // Use displayName as familyName fallback
      final newUser = UserModel(
        userId: user.uid,
        familyName: user.displayName ?? 'Unknown',
      );

      await firestoreAPI.addAuthUserToUserCollection(newUser);
      debugPrint("Google user saved to Firestore.");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Exception (Google): ${e.code} - ${e.message}");
      return null;
    } catch (e) {
      debugPrint("General Google Sign-In error: $e");
      return null;
    }
  }
}
