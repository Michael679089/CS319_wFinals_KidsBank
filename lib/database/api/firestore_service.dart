import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';

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

  Future<String> fetchFamilyNameOfUserID(String userId) async {
    var familyName = '';

    try {
      // Step 1: Get Selected Doc
      final selectedDocument = db.collection("users").doc(userId);

      // Step 2: Get document snapshot
      final docSnapShot = await selectedDocument.get();

      if (docSnapShot.exists) {
        familyName = docSnapShot.data()?["family_name"] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching family name: $e');
    }

    return familyName;
  }

  Future<bool> isThereMoreThanOneParentInThisAccount(String userId) async {
    var parentsList = db.collection("parents");

    // Query for documents where userId matches and count them
    final querySnapshot = await parentsList
        .where('familyUserId', isEqualTo: userId)
        .get();

    // Return true if more than one document is found
    return querySnapshot.docs.isNotEmpty;
  }

  Future<String> addParentToParentCollection(ParentModel parent) async {
    try {
      final collection = db.collection('parents');
      final docRef = collection.doc(); // Generate a new document ID
      final parentId = docRef.id;

      // Create a new ParentModel with the generated ID
      final parentWithId = ParentModel(
        parentId: parentId,
        firstName: parent.firstName,
        lastName: parent.lastName,
        avatar: parent.avatar,
        familyUserId: parent.familyUserId,
        pincode: parent.pincode,
        birthdate: parent.birthdate,
        createdAt: parent.createdAt ?? DateTime.now(),
      );

      // Save the parent data with the ID included
      await docRef.set(parentWithId.toMap());

      debugPrint(
        "FirestoreAPI - Successfully added parent: ${parent.firstName} ${parent.lastName} (ID: $parentId)",
      );
      return parentId;
    } catch (e) {
      throw Exception('ERROR: Adding parent to "parent" Collection: $e');
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

  Future<List<ParentModel>> getParentsByFamilyUserId(
    String familyUserId,
  ) async {
    if (familyUserId.isEmpty) {
      debugPrint(
        "FirestoreAPI - getParentsByFamilyUserId: Empty familyUserId provided",
      );
      throw Exception('Invalid familyUserId: Cannot be empty');
    }

    try {
      final query = await db
          .collection('parents')
          .where('familyUserId', isEqualTo: familyUserId)
          .get();

      if (query.docs.isEmpty) {
        debugPrint(
          "FirestoreAPI - getParentsByFamilyUserId: No parents found for familyUserId: $familyUserId",
        );
        return [];
      }

      return query.docs.map((doc) {
        final data = doc.data();
        return ParentModel.fromMap({
          ...data,
          'parentId': doc.id, // Include document ID as parentId
        });
      }).toList();
    } catch (e) {
      debugPrint(
        "FirestoreAPI - Error fetching parents for familyUserId $familyUserId: $e",
      );
      throw Exception('Failed to fetch parents: $e');
    }
  }

  Future<List<KidModel>> getKidsByFamilyUserId(String familyUserId) async {
    if (familyUserId.isEmpty) {
      debugPrint(
        "FirestoreAPI - getKidsByFamilyUserId: Empty familyUserId provided",
      );
      throw Exception('Invalid familyUserId: Cannot be empty');
    }

    try {
      final query = await db
          .collection('kids')
          .where('familyUserId', isEqualTo: familyUserId)
          .get();

      if (query.docs.isEmpty) {
        debugPrint(
          "FirestoreAPI - getKidsByFamilyUserId: No kids found for familyUserId: $familyUserId",
        );
        return [];
      }

      return query.docs.map((doc) {
        final data = doc.data();
        return KidModel.fromMap({
          ...data,
          'kidId': doc.id, // Include document ID as kidId
        });
      }).toList();
    } catch (e) {
      debugPrint(
        "FirestoreAPI - Error fetching kids for familyUserId $familyUserId: $e",
      );
      throw Exception('Failed to fetch kids: $e');
    }
  }

  Future<String?> getFamilyPaymentCardNumber(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('family_payment_info')
        .where('user_id', isEqualTo: userId)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['card_number'] as String?;
  }
}
