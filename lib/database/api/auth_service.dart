import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/user_model.dart';

class AuthService {
  final FirestoreAPI _firestoreAPI = FirestoreAPI();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // my private functions
  void _invokeErrorSnackBar(ScaffoldMessengerState messengerState, String err) {
    messengerState.showSnackBar(
      SnackBar(
        content: Text(err),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _invokeSuccessSnackBar(
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

  User? getCurrentUser() {
    if (_auth.currentUser != null) {
      return _auth.currentUser;
    } else {
      return null;
    }
  }

  // Create Firebase Auth account and send verification email
  Future<Map<String, String>> createAccountToFirebaseAuth({
    required UserModel myUserModel,
    required BuildContext context,
  }) async {
    debugPrint("createAccountToFirebaseAuth is called");

    final messenger = ScaffoldMessenger.of(context);
    var email = myUserModel.email;
    var password = myUserModel.password;

    // Step 1: Check if email exists in Firestore
    try {
      final emailExists = await _firestoreAPI.doesEmailExist(email);
      if (emailExists) {
        debugPrint('Error: Email already registered in Firestore: $email');
        _invokeErrorSnackBar(messenger, "Email Already Registered");
        return {'status': 'error', 'message': 'Email already registered.'};
      }
    } catch (e) {
      debugPrint('Error checking email in Firestore: $e');
      _invokeErrorSnackBar(messenger, e.toString());
      return {'status': 'error', 'message': 'Failed to check email: $e'};
    }

    // Step 2: Create account in Firebase Auth and send verification email
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      User? user = userCredential.user;

      if (user == null) {
        debugPrint('Error: User creation failed in Firebase Auth');
        _invokeErrorSnackBar(messenger, "User creation failed");
        return {'status': 'error', 'message': 'User creation failed.'};
      }

      // Send verification email - It looks like user is already logged in.
      await user.sendEmailVerification();
      debugPrint('Sent email verification to $email');
      _invokeSuccessSnackBar(
        messenger,
        'Verification email sent. Please check your inbox.',
      );
      return {
        'status': 'success',
        'message': 'Account created successfully for $email.',
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        debugPrint("ERROR: Registering email - already in use: $email");

        // check it's verification status
        try {
          UserCredential signInCredential = await _auth
              .signInWithEmailAndPassword(email: email, password: password);
          User? user = signInCredential.user;

          if (user != null) {
            // user is logged in
            var isEmailVerified = user.emailVerified;
            if (!isEmailVerified) {
              await user.sendEmailVerification();
              debugPrint('Resent verification email to $email');
              if (!context.mounted) {
                return {
                  'status': 'email-not-verified',
                  'message': 'Verification email resent for $email.',
                };
              }
              _invokeSuccessSnackBar(
                messenger,
                'Verification email resent. Please check your inbox.',
              );
              return {
                'status': 'email-not-verified',
                'message': 'Verification email resent for $email.',
              };
            } else {
              // Verified account: prompt to log in
              debugPrint('Email is verified, please log in: $email');
              if (!context.mounted) {
                return {
                  'status': 'email-verified',
                  'message': 'Email is already verified. Please log in.',
                };
              }
              _invokeErrorSnackBar(
                messenger,
                'Email is already verified. Please log in.',
              );
              return {
                'status': 'email-verified',
                'message': 'Email is already verified. Please log in.',
              };
            }
          }
        } on FirebaseAuthException catch (signInErr) {
          debugPrint(
            "ERROR: Signing in to check verification status: $signInErr",
          );
          _invokeErrorSnackBar(messenger, '$signInErr');
          return {
            'status': 'error',
            'message': 'Failed to sign in: $signInErr',
          };
        }
      }
      _invokeErrorSnackBar(messenger, 'Failed to create FireAuth Account: $e');
      return {
        'status': 'error',
        'message': 'Failed to create FireAuth Account: $e',
      };
    }
  }

  // Put a function here that checks if there's a user currently logged in.
  Future<Map<String, Object?>> checkLoggedInUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return {"isLoggedIn": false, "user": null};
    } else {
      return {"isLoggedIn": true, "user": user};
    }
  }

  Future<Map<String, Object>> loginAccountWithEmailAndPass(
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

  Future<Map<String, Object>> logoutAccount() async {
    try {
      await _auth.signOut();
      debugPrint("✅ User signed out successfully.");
      return {"status": "success", "message": "signout successful"};
    } catch (e) {
      debugPrint("❌ Error signing out: $e");
      return {"status": "failed", "message": "signout ${e}"};
    }
  }
}
