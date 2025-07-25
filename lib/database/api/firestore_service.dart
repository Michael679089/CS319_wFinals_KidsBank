import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';
import 'package:wfinals_kidsbank/database/models/family_payment_info_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_payment_info.dart';
import 'package:wfinals_kidsbank/database/models/notifications_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';

// Models:
import 'package:wfinals_kidsbank/database/models/family_model.dart';

class FirestoreService {
  final FirebaseFirestore db = FirebaseFirestore.instance;

  // Adding Items to Firestore:

  // adding family model

  Future<String> addAuthUserToFamilyCollection(FamilyModel family) async {
    debugPrint("addAuthUserToFamilyCollection called!");

    try {
      final collection = db.collection('family');
      final theDocumentId = collection.doc().id;

      // Add initial document with server timestamp
      await collection.doc(theDocumentId).set({
        ...family.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Fetch the document to get the resolved timestamp
      final snapshot = await collection.doc(theDocumentId).get();

      final Timestamp? serverTimestamp = snapshot.data()?['createdAt'];
      if (serverTimestamp != null) {
        final DateTime serverTime = serverTimestamp.toDate();
        final String formatted = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(serverTime);

        // Update with the string version of the timestamp
        await collection.doc(theDocumentId).update({'createdAt': formatted});
      }

      debugPrint(
        "FirestoreAPI - Successfully added family: ${family.familyName} (ID: $theDocumentId)",
      );

      return theDocumentId;
    } catch (e) {
      throw Exception('ERROR: Adding family to "family" collection: $e');
    }
  }

  Future<String> addKidPaymentInfoToKidPaymentInfoCollection(
    KidsPaymentInfoModel kidPaymentInfo,
  ) async {
    debugPrint("adding kidPaymentInfo called!");

    try {
      final collection = db.collection('kidPaymentInfo');
      final theDocumentId = collection.doc().id;

      // Add initial document with server timestamp
      await collection.doc(theDocumentId).set({
        ...kidPaymentInfo.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'kidPaymentInfoId': theDocumentId,
      });

      // Fetch the document to get the resolved timestamp
      final snapshot = await collection.doc(theDocumentId).get();

      List<String> targets = ["createdAt", "lastUpdated"];

      for (var target in targets) {
        final Timestamp? serverTimestamp = snapshot.data()?[target];
        if (serverTimestamp != null) {
          final DateTime serverTime = serverTimestamp.toDate();
          final String formatted = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(serverTime);

          // Update with the string version of the timestamp
          await collection.doc(theDocumentId).update({target: formatted});
        }
      }

      debugPrint(
        "FirestoreAPI - Successfully added kid payment information: (kidPaymentInfoId: $theDocumentId)",
      );

      return theDocumentId;
    } catch (e) {
      throw Exception('ERROR: Adding family to "family" collection: $e');
    }
  }

  Future<String> addChoreToChoresCollection(ChoreModel chore) async {
    debugPrint("adding addChoreToChoresCollection called!");

    try {
      final collection = db.collection('chores');
      final theDocumentId = collection.doc().id;

      // Add initial document with server timestamp
      await collection.doc(theDocumentId).set({
        ...chore.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'choreId': theDocumentId,
      });

      // Fetch the document to get the resolved timestamp
      final snapshot = await collection.doc(theDocumentId).get();

      final Timestamp? serverTimestamp = snapshot.data()?['createdAt'];
      if (serverTimestamp != null) {
        final DateTime serverTime = serverTimestamp.toDate();
        final String formatted = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(serverTime);

        // Update with the string version of the timestamp
        await collection.doc(theDocumentId).update({'createdAt': formatted});
      }

      debugPrint(
        "FirestoreAPI - Successfully added kid chore information: (choreId: $theDocumentId)",
      );

      return theDocumentId;
    } catch (e) {
      throw Exception('ERROR: Adding family to "chore" collection: $e');
    }
  }

  Future<String> addKidToKidsCollection(KidModel kid) async {
    debugPrint("adding addKidToKidsCollection called!");

    try {
      final collection = db.collection('kids');
      final theDocumentId = collection.doc().id;

      // Add initial document with server timestamp
      await collection.doc(theDocumentId).set({
        ...kid.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'kidId': theDocumentId,
      });

      // Fetch the document to get the resolved timestamp
      final snapshot = await collection.doc(theDocumentId).get();

      final Timestamp? serverTimestamp = snapshot.data()?['createdAt'];
      if (serverTimestamp != null) {
        final DateTime serverTime = serverTimestamp.toDate();
        final String formatted = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(serverTime);

        // Update with the string version of the timestamp
        await collection.doc(theDocumentId).update({'createdAt': formatted});
      }

      debugPrint(
        "FirestoreAPI - Successfully added kid payment information: (kidId: $theDocumentId)",
      );

      return theDocumentId;
    } catch (e) {
      throw Exception('ERROR: Adding family to "family" collection: $e');
    }
  }

  // adding parent model
  Future<String> addParentToParentCollection(ParentModel parent) async {
    try {
      debugPrint("Adding Parent");
      final collection = db.collection('parents');

      // Create a new ParentModel with the generated ID
      final theDocumentId = collection.doc().id;
      // Add initial document with server timestamp
      await collection.doc(theDocumentId).set({
        ...parent.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Fetch the document to get the resolved timestamp
      final snapshot = await collection.doc(theDocumentId).get();

      final Timestamp? serverTimestamp = snapshot.data()?['createdAt'];
      if (serverTimestamp != null) {
        final DateTime serverTime = serverTimestamp.toDate();
        final String formatted = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(serverTime);

        // Update with the string version of the timestamp
        await collection.doc(theDocumentId).update({'createdAt': formatted});
      }

      debugPrint(
        "FirestoreAPI - Successfully added parent: ${parent.firstName} ${parent.lastName} (ID: $theDocumentId)",
      );
      return theDocumentId;
    } catch (e) {
      throw Exception('ERROR: Adding parent to "parent" Collection: $e');
    }
  }

  Future<String> addNotificationToNotificationCollections(
    NotificationsModel notification,
  ) async {
    try {
      debugPrint("Adding Notification");
      final collection = db.collection('notifications');

      // Create a new ParentModel with the generated ID
      final theDocumentId = collection.doc().id;
      // Add initial document with server timestamp
      notification.notificationId = theDocumentId;
      await collection.doc(theDocumentId).set({
        ...notification.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Fetch the document to get the resolved timestamp
      final snapshot = await collection.doc(theDocumentId).get();

      final Timestamp? serverTimestamp = snapshot.data()?['createdAt'];
      if (serverTimestamp != null) {
        final DateTime serverTime = serverTimestamp.toDate();
        final String formatted = DateFormat(
          'yyyy-MM-dd HH:mm:ss',
        ).format(serverTime);

        // Update with the string version of the timestamp
        await collection.doc(theDocumentId).update({'createdAt': formatted});
      }

      debugPrint(
        "FirestoreAPI - Successfully added notification: ${notification.title} ${notification.message} (ID: $theDocumentId)",
      );
      return theDocumentId;
    } catch (e) {
      throw Exception('ERROR: Adding parent to "parent" Collection: $e');
    }
  }

  Future<bool> checkIfTableCollectionExist(String collectionName) async {
    final db = FirebaseFirestore.instance;

    try {
      final snapshot = await db.collection(collectionName).limit(1).get();

      if (snapshot.docs.isNotEmpty) {
        debugPrint(
          "✅ Collection '$collectionName' exists (has at least one document).",
        );
        return true;
      } else {
        debugPrint(
          "⚠️ Collection '$collectionName' does NOT exist or is empty.",
        );
        return false;
      }
    } catch (e) {
      debugPrint("❌ Error checking collection '$collectionName': $e");
      return false;
    }
  }

  Future<String> fetchFamilyNameOfUserID(String userId) async {
    var familyName = '';

    try {
      // Step 1: Get Selected Doc
      final selectedDocument = db.collection("collection").doc(userId);

      // Step 2: Get document snapshot
      final docSnapShot = await selectedDocument.get();

      if (docSnapShot.exists) {
        familyName = docSnapShot.data()?["familyName"] as String? ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching family name: $e');
    }

    return familyName;
  }

  Future<bool> isThereMoreThanOneParentInThisAccount(String familyId) async {
    var parentsList = db.collection("parents");

    // Query for documents where userId matches and count them
    final querySnapshot = await parentsList
        .where('familyId', isEqualTo: familyId)
        .get();

    // Return true if more than one document is found
    return querySnapshot.docs.isNotEmpty;
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
    FamilyPaymentInfoModel myPamentInfoModel,
  ) async {
    final collection = db.collection('familyPaymentInfo');

    // Create a new ParentModel with the generated ID
    final theDocumentId = collection.doc().id;
    myPamentInfoModel.familyPaymentInfoId = theDocumentId;
    collection.doc(theDocumentId).set(myPamentInfoModel.toMap());
  }

  Future<List<ParentModel>> getParentByFamilyUserId(String familyId) async {
    List<ParentModel> myList = [];

    try {
      final querySnapshot = await db
          .collection('parents')
          .where('familyId', isEqualTo: familyId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          "FirestoreAPI - getParentFromFamilyUserId: No parents found for familyId: $familyId",
        );
        return [];
      }

      for (var doc in querySnapshot.docs) {
        debugPrint(doc.data().toString());
        myList.add(ParentModel.fromMap({...doc.data(), 'parentId': doc.id}));
      }

      return myList;
    } catch (e) {
      debugPrint(
        "FirestoreAPI - Error fetching parents for familyUserId $familyId: $e",
      );
      throw Exception('Failed to fetch parents: $e');
    }
  }

  // fetching a list of KidModel by familyuserid...
  Future<List<KidModel>> getKidsByFamilyUserId(String familyId) async {
    List<KidModel> myList = [];
    try {
      final querySnapshot = await db
          .collection('kids')
          .where('familyId', isEqualTo: familyId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          "FirestoreAPI - getKidsByFamilyUserId: No Kids found for familyId: $familyId",
        );
        return [];
      }

      for (var doc in querySnapshot.docs) {
        myList.add(KidModel.fromMap({...doc.data(), 'kidId': doc.id}));
      }

      return myList;
    } catch (e) {
      debugPrint(
        "FirestoreAPI - Error fetching parents for familyUserId $familyId: $e",
      );
      throw Exception('Failed to fetch parents: $e');
    }
  }

  Future<List<ChoreModel>> getAllChoresByKidId(String kidId) async {
    List<ChoreModel> myList = [];

    final allDocs = await db
        .collection('chores')
        .where("KidId", isEqualTo: kidId)
        .get();

    for (var doc in allDocs.docs) {
      try {
        final fullData = {...doc.data(), 'choreId': doc.id};
        myList.add(ChoreModel.fromMap(fullData));
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    return myList;
  }

  Future<String?> getFamilyPaymentCardNumber(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('family_payment_info')
        .where('user_id', isEqualTo: userId)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data()['card_number'] as String?;
  }

  Future<String> getFamilyName(String familyId) async {
    var familyName = '';

    try {
      var familyCollection = db.collection("family");
      var familyCollectionSnapshot = await familyCollection
          .where("familyId", isEqualTo: familyId)
          .get();
      var familyDoc = familyCollectionSnapshot.docs.first;
      familyName = familyDoc["familyName"];
      return familyName;
    } catch (e) {
      debugPrint("$e");
      throw Error;
    }
  }

  Future<String> getKidFirstName(String kidDocId) async {
    var kidFirstName = '';

    var kidCollection = db.collection("kids");
    var kidDoc = await kidCollection.doc(kidDocId).get();

    if (kidDoc["firstName"] != null) {
      kidFirstName = kidDoc["firstName"];
    }

    return kidFirstName;
  }

  Future<void> fixAllNullOrEmptydateOfBirthPropertyInFirestore() async {
    final brokenDocIDs = <String>{};
    final kidsCollection = FirebaseFirestore.instance.collection("kids");

    final querySnapshot = await kidsCollection.get();

    debugPrint(
      "migrateKidsCollection: Fetched ${querySnapshot.docs.length} documents",
    );

    final now = DateTime.now().toIso8601String(); // Save as ISO 8601 String

    for (final doc in querySnapshot.docs) {
      final data = doc.data();

      final dob = data['dateOfBirth'] ?? data['date_of_birth'];

      // Check if dob is null, empty string, or blank
      final isMissingDOB =
          dob == null ||
          (dob is String && dob.trim().isEmpty) ||
          (dob is Timestamp && dob.toDate().toIso8601String().trim().isEmpty);

      if (isMissingDOB) {
        try {
          await kidsCollection.doc(doc.id).update({'dateOfBirth': now});
          debugPrint("Updated doc ${doc.id} with dateOfBirth: $now");
          brokenDocIDs.add(doc.id);
        } catch (e) {
          debugPrint("Failed to update ${doc.id}: $e");
        }
      }
    }

    debugPrint("Fixed ${brokenDocIDs.length} documents.");
  }

  // HELPER AND MIGRATION CODES:

  Future<void> fixAllNullOrEmptyIdFieldsInKidsCollection() async {
    final kidsCollection = FirebaseFirestore.instance.collection("kids");
    final querySnapshot = await kidsCollection.get();

    debugPrint("Fetched ${querySnapshot.docs.length} documents.");

    int fixedCount = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();

      final id = data['id'];
      final isIdMissing = id == null || (id is String && id.trim().isEmpty);

      if (isIdMissing) {
        try {
          await kidsCollection.doc(doc.id).update({'id': doc.id});
          debugPrint("✅ Updated doc ${doc.id} with id: ${doc.id}");
          fixedCount++;
        } catch (e) {
          debugPrint("❌ Failed to update doc ${doc.id}: $e");
        }
      }
    }

    debugPrint(
      "🔧 Fixed $fixedCount documents with missing/empty 'id' fields.",
    );
  }

  Future<void> fixAllNullOrEmptyLastNameFields() async {
    final kidsCollection = FirebaseFirestore.instance.collection("kids");
    final querySnapshot = await kidsCollection.get();

    debugPrint("Fetched ${querySnapshot.docs.length} kid documents.");

    int fixedCount = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();

      final lastName = data['lastName'];
      final isLastNameEmpty =
          lastName == null || (lastName is String && lastName.trim().isEmpty);

      if (isLastNameEmpty) {
        try {
          await kidsCollection.doc(doc.id).update({'lastName': "..."});
          debugPrint("✅ Fixed lastName for doc ${doc.id}");
          fixedCount++;
        } catch (e) {
          debugPrint("❌ Failed to fix lastName for doc ${doc.id}: $e");
        }
      }
    }

    debugPrint("🔧 Fixed $fixedCount documents with missing/empty 'lastName'.");
  }

  Future<void> migratePasswordToPincodeInKidsCollection() async {
    final kidsCollection = FirebaseFirestore.instance.collection("kids");
    final querySnapshot = await kidsCollection.get();

    debugPrint("Fetched ${querySnapshot.docs.length} kid documents.");

    int updatedCount = 0;

    for (final doc in querySnapshot.docs) {
      final data = doc.data();

      final hasPassword = data.containsKey('password');
      final hasPincode = data.containsKey('pincode');

      if (hasPassword) {
        final updates = <String, dynamic>{};

        // Copy password to pincode if pincode is missing or null
        if (!hasPincode ||
            data['pincode'] == null ||
            data['pincode'].toString().trim().isEmpty) {
          updates['pincode'] = data['password'] ?? '';
        }

        // Remove the password field
        updates['password'] = FieldValue.delete();

        try {
          await kidsCollection.doc(doc.id).update(updates);
          debugPrint("✅ Updated doc ${doc.id}");
          updatedCount++;
        } catch (e) {
          debugPrint("❌ Failed to update doc ${doc.id}: $e");
        }
      }
    }

    debugPrint("🔁 Finished. Updated $updatedCount documents.");
  }
}
