import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:wfinals_kidsbank/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/user_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';

class AuthService {
  final FirestoreAPI firestoreAPI = FirestoreAPI();

  // functions: 

  // Create
  Future<UserCredential?> createAccountToFirebaseAuth({
    required String email,
    required String password,
    required String familyName,
  }) async {
    UserCredential? userCredential;

    debugPrint("Creating an Auth Account...");
    try {
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
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

    // Create user and parent objects
    final newUser = UserModel(
      userId: userId,
      familyName: familyName,
    );

    // save the NEW user to user collection -> firestore api
    debugPrint("Saving the auth created to user collecton and parent collection");
    await firestoreAPI.addAuthUserToUserCollection(newUser);

    return userCredential;
  }
}
