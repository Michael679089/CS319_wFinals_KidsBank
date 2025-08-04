import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'package:wfinals_kidsbank/database/models/transactions_model.dart';

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

      debugPrint("family.read - query loaded");
      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        debugPrint("family.read: No family found for user $user_id");
        return null;
      }

      return snapshot.docs.first.data();
    } catch (e, stack) {
      debugPrint('family.read: Error reading family: $e');
      debugPrint('family.read: Stack trace: $stack');
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

  static Future<FamilyPaymentInfoModel?> readFamilyPaymentInfo(
    String user_id,
  ) async {
    debugPrint("FirestoreService@readFamilyPaymentInfo = Function START");

    try {
      var collection = db.collection("family_payment_info");
      var query = collection
          .where("user_id", isEqualTo: user_id)
          .limit(1)
          .withConverter<FamilyPaymentInfoModel>(
            fromFirestore: FamilyPaymentInfoModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );
      var querySnapShot = await query.get();
      FamilyPaymentInfoModel send_family_payment_info_model = querySnapShot
          .docs
          .first
          .data();
      return send_family_payment_info_model;
    } catch (e) {
      debugPrint("readFamilyPaymentInfo failed: $e");
      return null;
    } finally {
      debugPrint("FirestoreService@readFamilyPaymentInfo = Function END");
    }
  }

  ///
  /// PARENT MODEL | CRUD
  ///

  static Future<String> createParent(ParentModel parent_model) async {
    try {
      // Step 1: Query for a new Parent
      final collection = db.collection('parents');
      final parent_id = collection.doc().id;

      // Step 2: Get the link of the current family id
      final user_id = AuthService.getCurrentUser()?.uid;
      FamilyModel myFamily = await readFamily(user_id!) as FamilyModel;

      // Step 3: Add the server timestamp & link family id
      await collection.doc(parent_id).set({
        ...parent_model.toFirestore(),
        'id': parent_id,
        'family_id': myFamily.id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "parent.add - added parent to parent collection [$parent_id, ${parent_model.first_name}]",
      );
      return parent_id;
    } catch (e) {
      throw Exception('ERROR: Adding parent to "parent" collection: $e');
    }
  }

  static Future<ParentModel?> readParent(String family_id) async {
    debugPrint("parent.read called!");
    try {
      // Step 1: parent is referenced via family_id fetch it.
      final query = db
          .collection('parents')
          .where('family_id', isEqualTo: family_id)
          .limit(1)
          .withConverter<ParentModel>(
            fromFirestore: ParentModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );
      debugPrint("parent.read - query is loaded");

      final snapshot = await query.get();
      ParentModel placeholder_parent_model = snapshot.docs.first.data();
      return placeholder_parent_model; // Returns null if empty
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
    debugPrint("createKid - Function START");
    try {
      // Step 1: Query for a new kid
      final collection = db.collection('kids');
      final kid_id = collection.doc().id;

      // Step 2: Get the link of the current family id
      final user_id = AuthService.getCurrentUser()?.uid;
      FamilyModel myFamily = await readFamily(user_id!) as FamilyModel;

      // Step 3: Add the server timestamp & link family id
      await collection.doc(kid_id).set({
        ...kid_model.toFirestore(),
        'family_id': myFamily.id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "kid.add - added kid to kids collection [${myFamily.id}, ${myFamily.family_name}]",
      );
      return kid_id;
    } catch (e) {
      throw Exception('ERROR: Adding kids to "kids" collection: $e');
    } finally {
      debugPrint("createKid - Function END");
    }
  }

  ///
  // NOTIFICATION MODEL | CRUD
  ///

  static Future<String> createNotification(
    NotificationModel notification_model,
  ) async {
    try {
      // Validate required fields
      if (notification_model.kid_id.isEmpty ||
          notification_model.family_id.isEmpty) {
        throw Exception('Missing required fields');
      }

      final collection = db.collection('kids_notifications');
      final docRef = await collection.add({
        ...notification_model.toFirestore(),
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      rethrow;
    }
  }

  Stream<List<NotificationModel>> getKidNotifications(String kidId) {
    return FirebaseFirestore.instance
        .collection('kids_notifications')
        .where('kid_id', isEqualTo: kidId) // Filter only (no sorting)
        .snapshots()
        .map((snapshot) {
          // Sort manually in memory
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc, null))
              .toList();
          notifications.sort(
            (a, b) => b.created_at!.compareTo(a.created_at!),
          ); // Newest first
          return notifications;
        });
  }

  ///
  /// KID PAYMENT INFO MODEL | CRUD
  ///

  static Future<String> createKidPaymentInfo(
    KidsPaymentInfoModel kid_payment_info,
  ) async {
    try {
      // Step 1: Query for a new Collection
      final collection = db.collection('kids_payment_info');
      final kid_payment_info_id = collection.doc().id;

      // Step 2: Get the link of the current family id
      final user_id = AuthService.getCurrentUser()?.uid;
      var family_id;
      try {
        FamilyModel myFamily = await readFamily(user_id!) as FamilyModel;
        family_id = myFamily.id;
      } catch (e) {
        debugPrint(e.toString());
      }

      // Step 3: Add the server timestamp & link family id
      await collection.doc(kid_payment_info_id).set({
        ...kid_payment_info.toFirestore(),
        'id': kid_payment_info_id,
        'family_id': family_id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "family.add - added kid payment info to kids_payment_info collection [${kid_payment_info.id}]",
      );
      return kid_payment_info_id;
    } catch (e) {
      throw Exception('ERROR: Adding family to "notification" collection: $e');
    }
  }

  static Future<KidsPaymentInfoModel?> readKidPaymentInfo(var family_id) async {
    debugPrint("FirestoreService@readKidPaymentInfo = Function START");

    try {
      var collection = db.collection("kids_payment_info");
      var query = collection
          .where("family_id", isEqualTo: family_id)
          .limit(1)
          .withConverter<KidsPaymentInfoModel>(
            fromFirestore: KidsPaymentInfoModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );
      var querySnapShot = await query.get();
      KidsPaymentInfoModel send_family_payment_info_model = querySnapShot
          .docs
          .first
          .data();
      return send_family_payment_info_model;
    } catch (e) {
      debugPrint("KidsPaymentInfoModel failed: $e");
      return null;
    } finally {
      debugPrint("FirestoreService@readKidPaymentInfo = Function END");
    }
  }

  ///
  /// TRANSACTIONS MODEL | CRUD
  ///

  static Future<String> createTransaction(
    TransactionsModel transaction_model,
  ) async {
    try {
      debugPrint("adding transaction FUNCTION START");
      // Step 1: Query for a new Collection
      final collection = db.collection('transactions');
      final transaction_id = collection.doc().id;

      // Step 2: Get the link of the current family id
      final user_id = AuthService.getCurrentUser()?.uid;
      FamilyModel myFamily = readFamily(user_id!) as FamilyModel;
      var family_id = myFamily.id;

      // Step 3: Add the server timestamp & link family id
      await collection.doc(transaction_id).set({
        ...transaction_model.toFirestore(),
        'family_id': family_id,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint(
        "family.add - added transactions to 'transactions' collection [${transaction_model.id}]",
      );
      return transaction_id;
    } catch (e) {
      throw Exception(
        'ERROR: Adding transactions to "transactions" collection: $e',
      );
    } finally {
      debugPrint("adding transaction FUNCTION END");
    }
  }

  static Future<TransactionsModel?> readTransaction(String family_id) async {
    debugPrint("FirestoreService@readTransaction = Function START");

    try {
      var collection = db.collection("transactions");
      var query = collection
          .where("family_id", isEqualTo: family_id)
          .limit(1)
          .withConverter<TransactionsModel>(
            fromFirestore: TransactionsModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );
      var querySnapShot = await query.get();
      TransactionsModel send_transaction_model = querySnapShot.docs.first
          .data();
      return send_transaction_model;
    } catch (e) {
      debugPrint("Read TransactionsModel failed: $e");
      return null;
    } finally {
      debugPrint("FirestoreService@readTransaction = Function END");
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
    debugPrint("firestoreservice@fetch_family_name - START");
    var family_name = "";

    try {
      var family_collection = db.collection("family");
      var query = await family_collection
          .where("user_id", isEqualTo: user_id)
          .get();
      var docRef = query.docs.first;

      family_name = docRef["family_name"];
      debugPrint(
        "FirestoreService@fetch_family_name - fetched family name $family_name",
      );
    } catch (e) {
      debugPrint("ERROR: Connection failed");
    }

    debugPrint("firestoreservice@fetch_family_name - END");
    return family_name;
  }

  static Future<List<KidModel>> fetch_all_kids_by_family_id(
    String family_id,
  ) async {
    try {
      final query = db
          .collection("kids")
          .where("family_id", isEqualTo: family_id)
          .withConverter<KidModel>(
            fromFirestore: KidModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('Error fetching kids: $e');
      throw Exception('Failed to load kids. Please check connection');
    }
  }

  static Future<String?> fetch_family_id(String user_id) async {
    final user_id = AuthService.getCurrentUser()?.uid;
    FamilyModel myFamily = await readFamily(user_id!) as FamilyModel;
    var family_id = myFamily.id;
    return family_id;
  }

  static Future<ParentModel?> fetch_parent_by_parent_id(
    String parent_id,
  ) async {
    debugPrint("fetch_parent_by_family_id START");
    try {
      var parentsCollection = db.collection("parents");
      final docRef = parentsCollection
          .doc(parent_id)
          .withConverter<ParentModel>(
            fromFirestore: ParentModel.fromFirestore,
            toFirestore: (model, _) => model.toFirestore(),
          );
      final docSnap = await docRef.get();
      ParentModel? send_parent_model = docSnap.data();
      return send_parent_model; // Returns null if empty
    } catch (e) {
      debugPrint("fetch_parent_by_family_id failed: $e");
      return null;
    } finally {
      debugPrint("fetch_parent_by_family_id END");
    }
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

  static Future<List<TransactionsModel>>
  fetch_all_transactions_by_family_id_and_type(
    String selected_family_id,
    String target_type,
  ) async {
    debugPrint("fetch_all_transactions_by_family_id - Function START");
    List<TransactionsModel> transactions_list = [];
    try {
      final chores = db.collection("transactions");
      final choresSnapshot = await chores
          .where("family_id", isEqualTo: selected_family_id)
          .where("type", isEqualTo: target_type)
          .get();

      // Convert each document to a KidModel and add to list
      transactions_list = choresSnapshot.docs.map((doc) {
        return TransactionsModel.fromFirestore(
          doc,
          null,
        ); // Pass the document snapshot
      }).toList();
    } catch (e) {
      debugPrint("ERROR: Connection error (fetching kids): $e");
    }

    debugPrint("fetch_all_transactions_by_family_id - Function END");
    return transactions_list;
  }
}
