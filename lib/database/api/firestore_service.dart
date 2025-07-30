import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';
import 'package:wfinals_kidsbank/database/models/family_payment_info_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_payment_info_model.dart';
import 'package:wfinals_kidsbank/database/models/notifications_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';

// Models:
import 'package:wfinals_kidsbank/database/models/family_model.dart';

class FirestoreService {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  // CRUD OPERATIONS FOR EACH MODEL
  //
  ///
  // FAMILY | crud for family model
  ///

  static Future<String> createFamily(FamilyModel family) async {
    debugPrint("family.add called!");

    // Step 1: Query
    try {
      final collection = db.collection('family');
      final family_id = collection.doc().id;

      // Step 2: Add the server timestamp & id
      await collection.doc(family_id).set({
        ...family.toFirestore(),
        'id': family_id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "family.add - added family to family collection [$family_id, ${family.family_name}]",
      );
      return family_id;
    } catch (e) {
      throw Exception('ERROR: Adding family to "family" collection: $e');
    }
  }

  static Future<FamilyModel?> readFamily(String user_id) async {
    debugPrint("family.read called!");
    try {
      final query = db
          .collection('family')
          .where('user_id', isEqualTo: user_id)
          .limit(1)
          .withConverter<FamilyModel>(
            fromFirestore: FamilyModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );

      final snapshot = await query.get();
      final data = snapshot.docs.first.data();
      return data; // Returns null if empty
    } catch (e) {
      debugPrint('family.read: Error reading family: $e');
      return null;
    }
  }

  static void updateFamily(FamilyModel new_family) async {
    var target_user_id = new_family.user_id;

    var query = await db
        .collection("family")
        .where("user_id", isEqualTo: target_user_id)
        .get();
    var doesDocRefExists = query.docs.isNotEmpty;

    if (doesDocRefExists) {
      var docRef = query.docs.first;
      var family_collection = db.collection("family");
      var targetDocRef = family_collection.doc(docRef.id);

      await targetDocRef.update(new_family.toFirestore());
    } else {
      ("family.update - no family document found for user_id: $target_user_id");
    }
  }

  static void deleteFamily(String user_id_of_family) async {
    var query = await db
        .collection("family")
        .where("user_id", isEqualTo: user_id_of_family)
        .get();
    var doesDocRefExists = query.docs.isNotEmpty;

    if (doesDocRefExists) {
      var docRef = query.docs.first;
      var family_collection = db.collection("family");
      var targetDocRef = family_collection.doc(docRef.id);

      targetDocRef.delete();
      debugPrint("family.delete - successfully deleted: $user_id_of_family");
    }

    debugPrint("family.delete - couldn't delete: $user_id_of_family");
  }

  ///
  // FAMILY CARD INFO | crud for family_payment_info_model
  ///

  static Future<String> createFamilyPaymentInfo(
    FamilyPaymentInfoModel family_payment_info,
  ) async {
    // Step 1: Query
    try {
      final collection = db.collection('family_payment_info');
      final family_payment_info_id = collection.doc().id;

      // Step 2: Add the server timestamp & id
      await collection.doc(family_payment_info_id).set({
        ...family_payment_info.toFirestore(),
        'id': family_payment_info_id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "family.add - added family to family collection [$family_payment_info_id, ${family_payment_info.card_name}]",
      );
      return family_payment_info_id;
    } catch (e) {
      throw Exception('ERROR: Adding family to "family" collection: $e');
    }
  }

  ///
  /// PARENT MODEL | CRUD
  ///

  static Future<String> createParent(ParentModel parent_model) async {
    try {
      // Step 1: Query for a new Parent
      final collection = db.collection('parent');
      final parent_id = collection.doc().id;

      // Step 2: Get the link of the current family id
      final user_id = AuthService.getCurrentUser()?.uid;
      FamilyModel myFamily = readFamily(user_id!) as FamilyModel;

      // Step 3: Add the server timestamp & link family id
      await collection.doc(parent_id).set({
        ...parent_model.toFirestore(),
        'family_id': myFamily.id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "family.add - added family to parent collection [${myFamily.id}, ${myFamily.family_name}]",
      );
      return parent_id;
    } catch (e) {
      throw Exception('ERROR: Adding parent to "parent" collection: $e');
    }
  }

  static Future<ParentModel?> readParent(String family_id) async {
    debugPrint("family.read called!");
    try {
      final query = db
          .collection('family')
          .where('user_id', isEqualTo: family_id)
          .limit(1)
          .withConverter<ParentModel>(
            fromFirestore: ParentModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );

      final snapshot = await query.get();
      final parent_model = snapshot.docs.first.data();
      return parent_model; // Returns null if empty
    } catch (e) {
      debugPrint('family.read: Error reading family: $e');
      return null;
    }
  }

  ///
  /// KID MODEL | CRUD
  ///

  static Future<KidModel?> readKid(String family_id) async {
    try {
      final query = db
          .collection('kids')
          .where('family_id', isEqualTo: family_id)
          .limit(1)
          .withConverter<KidModel>(
            fromFirestore: KidModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );
      final snapshot = await query.get();
      final kid_model = snapshot.docs.first.data();
      return kid_model; // Returns null if empty
    } catch (e) {
      debugPrint('family.read: Error reading family: $e');
      return null;
    }
  }

  static Future<String?> createKid(KidModel kid_model) async {
    try {
      // Step 1: Query for a new kid
      final collection = db.collection('parent');
      final kid_id = collection.doc().id;

      // Step 2: Get the link of the current family id
      final user_id = AuthService.getCurrentUser()?.uid;
      FamilyModel myFamily = readFamily(user_id!) as FamilyModel;

      // Step 3: Add the server timestamp & link family id
      await collection.doc(kid_id).set({
        ...kid_model.toFirestore(),
        'family_id': myFamily.id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "family.add - added family to notification collection [${myFamily.id}, ${myFamily.family_name}]",
      );
      return kid_id;
    } catch (e) {
      throw Exception('ERROR: Adding kids to "kids" collection: $e');
    }
  }

  ///
  // NOTIFICATION MODEL | CRUD
  ///

  static Future<String> createNotification(
    NotificationModel notification_model,
  ) async {
    try {
      // Step 1: Query for a new Collection
      final collection = db.collection('collection');
      final notification_id = collection.doc().id;

      // Step 2: Get the link of the current family id
      final user_id = AuthService.getCurrentUser()?.uid;
      FamilyModel myFamily = readFamily(user_id!) as FamilyModel;
      var family_id = myFamily.id;

      // Step 3: Add the server timestamp & link family id
      await collection.doc(notification_id).set({
        ...notification_model.toFirestore(),
        'family_id': family_id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "family.add - added family to notification collection [${notification_model.id}]",
      );
      return notification_id;
    } catch (e) {
      throw Exception('ERROR: Adding family to "notification" collection: $e');
    }
  }

  ///
  /// KID PAYMENT INFO MODEL | CRUD
  ///

  static Future<String> createKidPaymentInfo(
    KidsPaymentInfoModel kid_payment_info,
  ) async {
    try {
      // Step 1: Query for a new Collection
      final collection = db.collection('collection');
      final notification_id = collection.doc().id;

      // Step 2: Get the link of the current family id
      final user_id = AuthService.getCurrentUser()?.uid;
      FamilyModel myFamily = readFamily(user_id!) as FamilyModel;

      // Step 3: Add the server timestamp & link family id
      await collection.doc(notification_id).set({
        ...kid_payment_info.toFirestore(),
        'family_id': myFamily.id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "family.add - added family to notification collection [${kid_payment_info.id}]",
      );
      return notification_id;
    } catch (e) {
      throw Exception('ERROR: Adding family to "notification" collection: $e');
    }
  }

  ////////////////////////
  ////////////////////////
  ////////////////////////
  ////////////////////////

  static Future<bool> doesFirestoreCollectionExist(
    String target_collection,
  ) async {
    try {
      final collectionRef = db.collection(target_collection);
      final snapshot = await collectionRef.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> does_family_account_exist_in_firestore(
    String family_email,
  ) async {
    var query = await db
        .collection("family")
        .where("email", isEqualTo: family_email)
        .get();

    var doesFamilyAccountExist = query.docs.isNotEmpty;

    if (doesFamilyAccountExist) {
      return true;
    } else {
      return false;
    }
  }

  static Future<String> fetch_family_name(String user_id) async {
    var family_name = "";

    try {
      var family_collection = db.collection("family");
      var query = await family_collection
          .where("user_id", isEqualTo: user_id)
          .get();
      var docRef = query.docs.first;

      family_name = docRef["family_name"];
    } catch (e) {
      debugPrint("ERROR: Connection failed");
    }

    return family_name;
  }

  static Future<List<KidModel>> fetch_all_kids_by_family_id(
    String family_id,
  ) async {
    List<KidModel> kids_list = [];

    try {
      final querySnapshot = await db
          .collection("kids")
          .where("family_id", isEqualTo: family_id)
          .get();

      // Convert each document to a KidModel and add to list
      kids_list = querySnapshot.docs.map((doc) {
        return KidModel.fromFirestore(doc, null); // Pass the document snapshot
      }).toList();
    } catch (e) {
      debugPrint("ERROR: Connection error (fetching kids): $e");
    }

    return kids_list;
  }

  static Future<String?> fetch_family_id(String user_id) async {
    final user_id = AuthService.getCurrentUser()?.uid;
    FamilyModel myFamily = await readFamily(user_id!) as FamilyModel;
    var family_id = myFamily.id;
    return family_id;
  }

  static Future<List<ChoreModel>> fetch_all_chores_by_kid_id(
    String selected_kid_id,
  ) async {
    List<ChoreModel> chores_list = [];
    try {
      final chores = db.collection("chores");
      final choresSnapshot = await chores
          .where("kid_id", isEqualTo: selected_kid_id)
          .get();

      // Convert each document to a KidModel and add to list
      chores_list = choresSnapshot.docs.map((doc) {
        return ChoreModel.fromFirestore(
          doc,
          null,
        ); // Pass the document snapshot
      }).toList();
    } catch (e) {
      debugPrint("ERROR: Connection error (fetching kids): $e");
    }

    return chores_list;
  }
}
