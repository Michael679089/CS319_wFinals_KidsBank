import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/cupertino.dart';

import 'package:wfinals_kidsbank/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/user_model.dart';

class AuthService {
  final FirestoreAPI firestoreAPI = FirestoreAPI();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // FUNCTIONS:

  // Create Auth Account:
  Future<Map<String, Object>?> createAccountToFirebaseAuth({
    required String email,
    required String password,
    required String familyName,
  }) async {
    debugPrint("createAccountToFirebaseAuth is called");

    try {
      firestoreAPI.db.collection("users");

      // Step 1: Check if email exists in Firestore
      final querySnapshot = await firestoreAPI.db
          .collection("users")
          .where("email", isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        debugPrint(
          {
            "status": "error",
            "message": "Email already registered.",
          }.toString(),
        );
        return {"status": "error", "message": "Email already registered."};
      }

      // Step 2: Create account in Firebase Auth & Send Email
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.sendEmailVerification();
      debugPrint("createAuthAcc: Sent email verification.");
      var user = userCredential.user;

      if (user == null) {
        return {
          "status": "error",
          "message": "User creation failed in Firebase Auth.",
        };
      }

      // Step 3: Create a UserModel instance & Save to Firestore (users collection) using toMap:
      final myUserModel = UserModel(
        userId: user.uid,
        familyName: familyName,
        email: email,
        createdAt: "",
      );
      await firestoreAPI.db.collection("users").doc(user.uid).set({
        ...myUserModel.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("✅ User created successfully.");
      return {
        "status": "success",
        "message":
            "${myUserModel.email} is now registered. Please verify email.",
      };
    } catch (e) {
      debugPrint("❌ Exception: $e");
      return {"status": "error", "message": e.toString()};
    }
  }

  // Put a function here that checks if there's a user currently logged in.
  Future<Map<String, Object?>> checkLoggedInUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"isLoggedIn": false, "user": null};
    } else {
      return {"isLoggedIn": true, "user": user};
    }
  }

  Future<UserCredential?> signInTemporary(String email, String password) async {
    try {
      final userCred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCred;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteUserAccount(String userUid) async {
    try {
      // Step 1: Delete from Firestore
      await firestoreAPI.db.collection("users").doc(userUid).delete();
      debugPrint("Deleted user from Firestore: $userUid");

      // Step 2: Delete from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == userUid) {
        await currentUser.delete();
        debugPrint("Deleted user from Firebase Auth: $userUid");
      } else {
        debugPrint(
          "Cannot delete from Firebase Auth — user not signed in or UID mismatch.",
        );
      }

      return true;
    } catch (e) {
      debugPrint("Error deleting user account: $e");
      return false;
    }
  }

  Future<Map<String, Object>> loginAccountWithEmailAndPass(
    String email,
    String password,
  ) async {
    try {
      final UserCredential loginResult = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (!loginResult.user!.emailVerified) {
        debugPrint("unverified email users can't log in");
        await loginResult.user!.sendEmailVerification();
        return {
          "status": "unverified",
          "message": "Verification email re-sent. Please check your inbox.",
        };
      }
      return {"status": "success", "userCredential": loginResult};
    } on FirebaseAuthException catch (e) {
      return {
        "status": "error",
        "code": e.code,
        "message": e.message ?? "Login failed",
      };
    } catch (e) {
      return {"status": "error", "message": "Unexpected error occurred: $e"};
    }
  }

  Future<Map<String, Object>> logoutAccount() async {
    try {
      await _firebaseAuth.signOut();
      debugPrint("✅ User signed out successfully.");
      return {"status": "success", "message": "signout successful"};
    } catch (e) {
      debugPrint("❌ Error signing out: $e");
      return {"status": "failed", "message": "signout ${e}"};
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
        email: userCredential.user!.email as String,
        createdAt: "",
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
