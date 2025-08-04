import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/family_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class AuthService {
  static final FirestoreService _firestoreAPI = FirestoreService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // my private functions
  static void _invokeErrorSnackBar(
    ScaffoldMessengerState messengerState,
    String err,
  ) {
    messengerState.showSnackBar(
      SnackBar(
        content: Text(err),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _invokeSuccessSnackBar(
    ScaffoldMessengerState messengerState,
    String successMessage,
  ) {
    messengerState.showSnackBar(
      SnackBar(
        content: Text(successMessage),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // My PUBLIC actions:

  static User? getCurrentUser() {
    if (_auth.currentUser != null) {
      return _auth.currentUser;
    } else {
      return null;
    }
  }

  // Create Firebase Auth account and send verification email
  static Future<Map<String, String>>
  registerEmailAndPasswordWithEmailVerification(
    String email,
    String password,
    BuildContext context,
  ) async {
    debugPrint("createAccountToFirebaseAuth is called");

    // Step 1: Check if email exists in Firestore
    var doesFamilyCollectionExist =
        (await FirestoreService.doesFirestoreCollectionExist("family"));

    if (doesFamilyCollectionExist == false) {
      // Step 1: check if email exist in fire_auth
      var doesEmailExistInFireAuth = false;
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        doesEmailExistInFireAuth = true;
      }

      if (doesEmailExistInFireAuth == true) {
        debugPrint("no family connection, but have fireauth account");
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        var user = AuthService.getCurrentUser();
        if (user != null) {
          user.sendEmailVerification();
          debugPrint("user is logged in-but not verified");
          return {
            "status": "no-family-collection-and-unverified",
            "message": "user must redo register and verify email page",
          };
        } else {
          debugPrint("error connection 1");
          return {
            "status": "connection-error",
            "message": "user needs better connection",
          };
        }
      } else {
        debugPrint("no family collection and no fireauth account");
        await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        var user = AuthService.getCurrentUser();
        if (user != null) {
          user.sendEmailVerification();
          debugPrint("user is logged in-but not verified");
          return {
            "status": "no-family-collection-and-no-acount",
            "message":
                "user needs to finish register page and go to verify email page",
          };
        } else {
          debugPrint("error connection 2");
          return {
            "status": "connection-error",
            "message": "user needs better connection",
          };
        }
      }
    } else {
      debugPrint("family collection exist");
      // Step 1: find the email inside firestore
      var emailHasBeenFound =
          await FirestoreService.does_family_account_exist_in_firestore(email);

      if (emailHasBeenFound) {
        debugPrint(
          "account already verified, can't register with that account anymore",
        );
        return {
          "status": "account-already-verified",
          "message":
              "account already verified, can't register with that account anymore",
        };
      } else {
        debugPrint("no family collection 3");
        debugPrint("no email found in firestore, continue with registration");

        // Step 1: Sign up on fireAuth, if failed, return email-unverified;
        try {
          await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
          var user = getCurrentUser();
          if (user != null) {
            user.sendEmailVerification();
            debugPrint("email verification sent");
            return {
              "status": "success",
              "message": "successfully register and email send verification",
            };
          } else {
            debugPrint("error conncetion");
            return {
              "status": "connection-error",
              "message": "user needs better connection",
            };
          }
        } catch (e) {
          debugPrint("an error occured $e");
          return {
            "status": "email-unverified",
            "message": "email is unverified, proceed with registration",
          };
        }
      }
    }
  }

  static Future<Map<String, Object>> loginAccount(
    String email,
    String password,
  ) async {
    try {
      final UserCredential loginResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

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

  static Future<Map<String, Object>> logoutAccount() async {
    try {
      await _auth.signOut();
      debugPrint("✅ User signed out successfully.");
      return {"status": "success", "message": "signout successful"};
    } catch (e) {
      debugPrint("❌ Error signing out: $e");
      return {"status": "failed", "message": "ERROR: signout ${e}"};
    }
  }

  static Future<bool> sendEmailVerification() async {
    var was_email_verification_sending_successful = false;

    try {
      final user = AuthService.getCurrentUser();
      await user?.sendEmailVerification();
      was_email_verification_sending_successful = true;
    } catch (e) {
      debugPrint("ERROR: sending email verification: ${e.toString()}");
    }

    return was_email_verification_sending_successful;
  }

  static Future<void> sendPasswordResetEmail(String emailText) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailText.trim(),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-not-found':
          errorMessage = 'No account found for this email';
          break;
        default:
          errorMessage = 'Error sending password reset email: ${e.message}';
      }
      throw FirebaseAuthException(code: e.code, message: errorMessage);
    } catch (e) {
      throw Exception('Unexpected error sending password reset email: $e');
    }
  }
}
