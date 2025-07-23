import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Models:
import 'package:wfinals_kidsbank/database/models/user_model.dart';

class FirestoreAPI {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  Future<void> addAuthUserToUserCollection(UserModel user) async {
    debugPrint("addAuthUserToUserCollection called!");

    final CollectionReference userCollection = db.collection("users");
    final DocumentReference userRef = userCollection.doc(user.userId);

    try {
      await userRef.set({
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(), // Set server timestamp here
      });

      debugPrint("✅ User created:");
      debugPrint(
        "userId: ${user.userId}; familyName: ${user.familyName}; email: ${user.email};",
      );
    } catch (e) {
      debugPrint("❌ ERROR: Failed to create user! $e");
    }
  }

  Future<void> initializeTheDatabase() async {
    debugPrint("initializeTheDatabase is called!");

    // Dummy Data Creation:
    try {
      // Create a placeholder "users" document (e.g., a template or default admin)
      final userCollection = db.collection('users');
      final parentCollection = db.collection('parents');

      // Check if a default admin exists (optional)
      final adminDoc = await userCollection.doc('admin_template').get();
      if (!adminDoc.exists) {
        await userCollection.doc('admin_template').set({
          'userId': 'admin_template',
          'familyName': 'Administrator',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint(
          'initializeTheDatabase: Default admin_template user created.',
        );
      }

      // Optional: initialize a sample parent document
      final parentDoc = await parentCollection.doc('parent_template').get();
      if (!parentDoc.exists) {
        await parentCollection.doc('parent_template').set({
          'parentId': 'parent_template',
          'firstName': 'Parent',
          'lastName': 'Template',
          'pincode': 00000000,
          'userId': 'admin_template',
          'dateOfBirth': DateTime(1970, 1, 1).toIso8601String(),
        });
        debugPrint('initializeTheDatabase: Default parent_template created.');
      }
    } catch (e) {
      debugPrint('ERROR: Failed to initialize database: $e');
    }
  }

  Future<bool> doesEmailExist(String email) async {
    final querySnapshot = await db
        .collection('users')
        .where('email', isEqualTo: email)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Future<void> addUserToFirestore({
    required String uid,
    required String email,
    required String familyName,
  }) async {
    await db.collection('users').doc(uid).set({
      'email': email,
      'familyName': familyName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addCardPaymentInfo(
    String userId,
    String cardName,
    String cardNumber,
    String expirationDate,
    String ccv,
  ) async {
    FirebaseFirestore.instance.collection('family_payment_info').add({
      'user_id': userId,
      'card_name': cardName,
      'card_number': cardNumber,
      'exp': expirationDate,
      'ccv': ccv,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
