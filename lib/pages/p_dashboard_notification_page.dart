import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'p_dashboard_drawer.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class UnifiedNotification {
  final String id;
  final String kidId;
  final String kidName;
  final String avatar;
  final String type;
  final String title;
  final String message;
  final String? choreTitle;
  final String? choreDesc;
  final double? amount;
  final DateTime createdAt;
  final String status;
  final ChoreModel? chore;

  UnifiedNotification({
    required this.id,
    required this.kidId,
    required this.kidName,
    required this.avatar,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.status,
    this.choreTitle,
    this.choreDesc,
    this.amount,
    this.chore,
  });
}

class ParentNotificationsPage extends StatefulWidget {
  final String user_id;
  final String parent_id;
  final String family_id;

  const ParentNotificationsPage({
    super.key,
    required this.user_id,
    required this.parent_id,
    required this.family_id,
  });

  @override
  State<ParentNotificationsPage> createState() =>
      _ParentNotificationsPageState();
}

class _ParentNotificationsPageState extends State<ParentNotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? familyName;

  @override
  void initState() {
    super.initState();
    _fetchFamilyName();
  }

 Future<void> showRewardChoreModal(
  BuildContext context,
  UnifiedNotification notif,
  VoidCallback onRewarded,
) async {
  final messageController = TextEditingController();
  final focusNode = FocusNode();
  final rewardAmount = notif.chore?.reward_money ?? 0;

  showDialog(
    context: context,
    barrierDismissible: true, //Allow close on outside tap
    builder: (_) {
      return Center(
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(notif.avatar, width: 80, height: 80),
                  const SizedBox(height: 10),
                  Text("Reward Chore",
                      style: GoogleFonts.fredoka(
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  Text("for ${notif.kidName}",
                      style: GoogleFonts.fredoka(
                          fontSize: 22, color: Colors.black54)),
                  const SizedBox(height: 20),
                  TextField(
                    readOnly: true,
                    controller: TextEditingController(
                        text: rewardAmount.toStringAsFixed(2)),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: "Reward Amount",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: messageController,
                    focusNode: focusNode,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: "Message for Kid (required)",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60C56F),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side:
                                const BorderSide(color: Colors.black, width: 2))),
                    child: Text("Confirm and Reward",
                        style: GoogleFonts.fredoka(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    onPressed: () async {
                      final msg = messageController.text.trim();
                      if (msg.isEmpty) {
                        UtilityTopSnackBar.show(
                          context: context,
                          message: "⚠️ Please enter a message",
                          isError: true,
                        );
                        return;
                      }

                      try {
                        //Transaction: update chore + payment + kids_notifications
                        final choreRef = _firestore
                            .collection('chores')
                            .doc(notif.chore?.id ?? notif.id);

                        final paymentQuery = await _firestore
                            .collection('kids_payment_info')
                            .where('kid_id', isEqualTo: notif.kidId)
                            .limit(1)
                            .get();
                        if (paymentQuery.docs.isEmpty) {
                          throw Exception("No payment info found");
                        }
                        final paymentRef = paymentQuery.docs.first.reference;

                        await _firestore.runTransaction((txn) async {
                          final paySnap = await txn.get(paymentRef);
                          final bal = (paySnap['total_amount_left'] ?? 0).toDouble();
                          txn.update(choreRef, {'status': 'rewarded'});
                          txn.update(paymentRef,
                              {'total_amount_left': bal + rewardAmount});
                        });

                        // Add kids_notification with type reward
                        await _firestore.collection('kids_notifications').add({
                          'kid_id': notif.kidId,
                          'family_id': widget.family_id,
                          'notification_title': notif.choreTitle?.isNotEmpty == true 
                              ? notif.choreTitle 
                              : 'Chore Rewarded',
                          'notification_message': msg.isNotEmpty 
                              ? msg 
                              : 'You have received a reward!',
                          'amount': rewardAmount > 0 ? rewardAmount : 0,
                          'created_at': FieldValue.serverTimestamp(), // still okay
                          'type': 'reward',
                          'status': 'done',
                        });

                        Navigator.pop(context);
                        onRewarded();
                        UtilityTopSnackBar.show(
                          context: context,
                          message:
                              "✅ ${notif.kidName}'s chore rewarded!",
                          isError: false,
                        );
                      } catch (e) {
                        UtilityTopSnackBar.show(
                          context: context,
                          message: "❌ Failed: ${e.toString()}",
                          isError: true,
                        );
                      }
                    },
                  )
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  // Auto-focus message after short delay
  Future.delayed(const Duration(milliseconds: 300),
      () => FocusScope.of(context).requestFocus(focusNode));
}

  Future<void> _fetchFamilyName() async {
    final familyDoc =
        await _firestore.collection('families').doc(widget.parent_id).get();
    if (familyDoc.exists) {
      setState(() {
        familyName = familyDoc.data()?['family_name'] ?? 'Family';
      });
    }
  }

  /// Unified stream with Chores + Withdrawals
  Stream<List<UnifiedNotification>> getNotificationsStream() async* {
    debugPrint("Fetching kids for family_id: ${widget.family_id}");

    final kidsSnapshot = await _firestore
        .collection('kids')
        .where('family_id', isEqualTo: widget.family_id)
        .get();

    if (kidsSnapshot.docs.isEmpty) {
      debugPrint("No kids found for family_id: ${widget.family_id}");
      yield [];
      return;
    }

    final kidIds = kidsSnapshot.docs.map((doc) => doc.id).toList();
    final kidNames = {
      for (var doc in kidsSnapshot.docs)
        doc.id: doc.data().containsKey('first_name') &&
                doc['first_name'] != null
            ? doc['first_name'] as String
            : 'Kid'
    };
    final kidAvatars = {
      for (var doc in kidsSnapshot.docs)
        doc.id: doc.data().containsKey('avatar_file_path') &&
                doc['avatar_file_path'] != null &&
                (doc['avatar_file_path'] as String).isNotEmpty
            ? doc['avatar_file_path'] as String
            : 'assets/avatar1.png'
    };

    debugPrint("Kids found: $kidIds");
    for (var id in kidIds) {
      debugPrint(
          "Kid: $id | Name: ${kidNames[id]} | Avatar: ${kidAvatars[id]}");
    }

    //Chores Stream
    final choresStream = _firestore
        .collection('chores')
        .where('status', whereIn: ['completed', 'rewarded'])
        .snapshots()
        .map((snapshot) {
      debugPrint("Chores snapshot received: ${snapshot.docs.length} docs");
      return snapshot.docs
          .where((doc) => kidIds.contains(doc['kid_id']))
          .map((doc) {
        final data = doc.data();
        debugPrint("Chore doc: ${doc.id} => $data");

        final kidId = data['kid_id'] ?? '';
        return UnifiedNotification(
          id: doc.id,
          kidId: kidId,
          kidName: kidNames[kidId] ?? 'Kid',
          avatar: kidAvatars[kidId] ?? 'assets/avatar1.png',
          type: 'chore_completed',
          title: 'Chore Completed',
          message: '${kidNames[kidId]} completed a chore!',
          choreTitle: data['chore_title'] ?? '',
          choreDesc: data['chore_description'] ?? '',
          createdAt: (data['created_at'] as Timestamp).toDate(),
          status: data['status'] ?? 'pending',
          chore: ChoreModel(
            id: doc.id,
            kid_id: kidId,
            chore_title: data['chore_title'] ?? '',
            chore_description: data['chore_description'] ?? '',
            reward_money: (data['reward_money'] ?? 0).toDouble(),
            status: data['status'] ?? '',
            created_at: (data['created_at'] as Timestamp).toDate(),
          ),
        );
      }).toList();
    });

    //Withdrawals Stream
    final withdrawalStream = _firestore
        .collection('kids_notifications')
        .where('type', isEqualTo: 'withdrawal')
        .snapshots()
        .map((snapshot) {
      debugPrint(
          "Kids_notifications snapshot received: ${snapshot.docs.length} docs");
      return snapshot.docs
          .where((doc) => kidIds.contains(doc['kid_id']))
          .map((doc) {
        final data = doc.data();
        debugPrint("Notification doc: ${doc.id} => $data");

        final kidId = data['kid_id'] ?? '';
        return UnifiedNotification(
          id: doc.id,
          kidId: kidId,
          kidName: kidNames[kidId] ?? 'Kid',
          avatar: kidAvatars[kidId] ?? 'assets/avatar1.png',
          type: 'withdrawal',
          title: data['notification_title'] ?? '',
          message: data['notification_message'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          createdAt: (data['timestamp'] as Timestamp).toDate(),
          status: data['status'] ?? 'done',
        );
      }).toList();
    });

    yield* Rx.combineLatest2(
      choresStream,
      withdrawalStream,
      (List<UnifiedNotification> chores,
          List<UnifiedNotification> withdrawals) {
        final all = [...chores, ...withdrawals]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        debugPrint("Combined notifications: ${all.length} total");
        return all;
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) async {},
      child: Scaffold(
        drawer: ParentDrawer(
          selectedPage: 'notifications',
          familyName: familyName ?? 'Family',
          user_id: widget.user_id,
          parentId: widget.parent_id,
          family_id: widget.family_id,
        ),
        backgroundColor: const Color(0xFFFFCA26),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFCA26),
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Notifications",
            style: GoogleFonts.fredoka(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          leading: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.all(8),
              child: InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: const CircleAvatar(
                  backgroundColor: Colors.black,
                  child: Icon(Icons.menu, color: Color(0xFFFFCA26)),
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<UnifiedNotification>>(
            stream: getNotificationsStream(),
            builder: (context, snapshot) {
              debugPrint("StreamBuilder state: ${snapshot.connectionState}");
              if (snapshot.hasError) {
                debugPrint("Stream error: ${snapshot.error}");
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error loading notifications"));
              }
              final notifications = snapshot.data ?? [];
              if (notifications.isEmpty) {
                return Center(
                  child: Text(
                    "No notifications yet!",
                    style: GoogleFonts.fredoka(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, i) {
                  final n = notifications[i];
                  final ts = DateFormat('MM/dd HH:mm').format(n.createdAt);
                  final isRewarded = n.status == 'rewarded';
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: const Color(0xFFFFCA26),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage(n.avatar),
                        radius: 25,
                      ),
                      title: Text(
                        n.type == 'chore_completed'
                            ? "${n.kidName} completed a chore!"
                            : "${n.kidName} withdrew \$${n.amount?.toStringAsFixed(2) ?? '0.00'}",
                        style: GoogleFonts.fredoka(
                          fontWeight: FontWeight.bold,
                          color: isRewarded
                              ? const Color(0xFF7d5e0d)
                              : Colors.black,
                        ),
                      ),
                      subtitle: n.type == 'chore_completed'
                          ? GestureDetector(
                              onTap: isRewarded 
                              ? null 
                              : () =>showRewardChoreModal(context, n, () {
                                      debugPrint("UI refresh after reward");
                                    }),
                              child: Text(
                                "\"${n.choreTitle}\" | Click to confirm & reward",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF7d5e0d),
                                  decoration: isRewarded
                                      ? TextDecoration.none
                                      : TextDecoration.underline,
                                ),
                              ),
                            )
                          : Text(
                              "$ts | \"${n.title}\" ${n.choreDesc ?? ''}",
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
