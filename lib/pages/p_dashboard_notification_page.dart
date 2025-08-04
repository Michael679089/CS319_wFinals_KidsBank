import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'p_dashboard_drawer.dart';
import 'package:flutter/services.dart';

class ParentNotificationsPage extends StatefulWidget {
  final String user_id;
  final String parent_id;

  const ParentNotificationsPage({super.key, required this.user_id, required this.parent_id});

  @override
  State<ParentNotificationsPage> createState() => _ParentNotificationsPageState();
}

class _ParentNotificationsPageState extends State<ParentNotificationsPage> {
  // myservices
  var myFirestoreService = FirestoreService();

  /// Fetch notifications stream with kid info
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return FirebaseFirestore.instance.collection('notifications').orderBy('createdAt', descending: true).snapshots().asyncMap((snapshot) async {
      debugPrint("parentDashNotifPage - getting notifications");

      List<Map<String, dynamic>> notifications = [];

      for (var doc in snapshot.docs) {
        final notificationData = doc.data();
        final kidId = notificationData['kidId'];

        // Fetch corresponding kid info
        final kidDoc = await FirebaseFirestore.instance.collection('kids').doc(kidId).get();

        if (!kidDoc.exists) continue;

        final kidData = kidDoc.data()!;
        final kidName = kidData['firstName'] ?? "Unknown Kid";
        final avatarPath = kidData['avatarFilePath'] ?? "";

        // Combine kid info with notification info
        notifications.add({
          'id': doc.id,
          'type': notificationData["type"],
          'choreTitle': notificationData['choreTitle'] ?? '',
          'choreDesc': notificationData['choreDesc'] ?? '',
          'title': notificationData['title'] ?? '',
          'amount': notificationData['amount'] ?? 0,
          'status': notificationData['status'] ?? 'pending',
          'message': notificationData['message'] ?? "",
          'timestamp': notificationData['timestamp'],
          'kidId': kidId,
          'kidName': kidName,
          'kidAvatar': avatarPath,
        });
      }

      debugPrint("parentDashNotifPage - returned notifications: \$notifications");
      return notifications;
    });
  }

  // saved credentials
  String familyName = '';
  String familyUserId = '';
  String parentId = '';

  // INITSTATE Function:

  @override
  void initState() {
    debugPrint("PDNotificationPage - loading Page");
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint("PDNotificationPage - loading family data");
      _loadMyFamilyData();
      debugPrint("PDNotificationPage - family data loaded");
    });
  }

  // Other Functions:

  void _loadMyFamilyData() async {
    final myModalRoute = ModalRoute.of(context);
    if (myModalRoute == null) {
      return;
    }
    final args = myModalRoute.settings.arguments as Map<String, String?>;
    var new_family_name = await FirestoreService.fetch_family_name(familyUserId);
    parentId = widget.parent_id;

    setState(() {
      familyUserId = widget.user_id;
      familyName = new_family_name;
      parentId = args["parent-id"] as String;
      debugPrint("PDashboardNotifsPage - loaded family data");
    });
  }

  /// Show reward modal and reward chore
  void showRewardChoreModal(
    BuildContext context,
    String notifId, // Notification document ID
    String kidName,
    String kidId,
    String avatar,
    String choreTitle,
    double defaultReward,
    Function onRewarded,
  ) {
    final TextEditingController amountController = TextEditingController(text: defaultReward.toStringAsFixed(2));
    final TextEditingController messageController = TextEditingController();
    final FocusNode messageFocusNode = FocusNode();

    double rewardAmount = defaultReward;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom * 0.4),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: StatefulBuilder(
                  builder: (context, setModalState) {
                    return Stack(
                      children: [
                        // Avatar Image
                        Positioned(top: 0, right: 0, child: Image.asset(avatar, width: 80, height: 80, fit: BoxFit.cover)),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            Text("Reward Chore", style: GoogleFonts.fredoka(fontSize: 30, fontWeight: FontWeight.bold)),
                            Text("for $kidName", style: GoogleFonts.fredoka(fontSize: 24, color: Colors.black54)),
                            const SizedBox(height: 20),

                            // Reward Amount Section
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Decrement Button
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      if (rewardAmount > 1) {
                                        rewardAmount -= 1;
                                        amountController.text = rewardAmount.toStringAsFixed(2);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCA26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black, width: 2),
                                    ),
                                    child: const Icon(Icons.remove, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Amount Text Field (Only numbers allowed)
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    controller: amountController,
                                    focusNode: FocusNode(), // Prevent auto-focus
                                    textAlign: TextAlign.center,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), // Allow numbers and decimal
                                    ],
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onChanged: (value) {
                                      setModalState(() {
                                        rewardAmount = double.tryParse(value) ?? 0;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Increment Button
                                InkWell(
                                  onTap: () {
                                    setModalState(() {
                                      rewardAmount += 1;
                                      amountController.text = rewardAmount.toStringAsFixed(2);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCA26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black, width: 2),
                                    ),
                                    child: const Icon(Icons.add, size: 20),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Message Field (Auto-focus)
                            TextField(
                              controller: messageController,
                              focusNode: messageFocusNode,
                              maxLines: 2,
                              autofocus: true, // Auto-focus this field
                              decoration: InputDecoration(
                                labelText: "Message for Kid (required)",
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Confirm Button
                            ElevatedButton(
                              onPressed: () async {
                                final String message = messageController.text.trim();
                                final enteredAmount = double.tryParse(amountController.text.trim());

                                // ⚠️ Error checks
                                if (enteredAmount == null || enteredAmount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "⚠️ Please enter a valid reward amount.",
                                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                if (message.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "⚠️ Please enter a message for the kid.",
                                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  // 1. Update kid's balance
                                  final paymentDoc = FirebaseFirestore.instance.collection('kidPaymentInfo').doc(kidId);

                                  final paymentSnapshot = await paymentDoc.get();
                                  double currentBalance = 0;
                                  if (paymentSnapshot.exists) {
                                    currentBalance = (paymentSnapshot.data()?['usable_balance'] ?? 0).toDouble();
                                  }

                                  final newBalance = currentBalance + enteredAmount;

                                  await paymentDoc.set({'amountLeft': newBalance, 'lastUpdated': FieldValue.serverTimestamp()});

                                  // 2. Update notification & chore status
                                  await FirebaseFirestore.instance.collection('notifications').doc(notifId).update({'status': 'rewarded'});

                                  final choreQuery = await FirebaseFirestore.instance
                                      .collection('chores')
                                      .where('kidId', isEqualTo: kidId)
                                      .where('choreTitle', isEqualTo: choreTitle)
                                      .get();

                                  for (var choreDoc in choreQuery.docs) {
                                    await choreDoc.reference.update({'status': 'rewarded'});
                                  }

                                  // 3. Add kids notification with message
                                  await FirebaseFirestore.instance.collection('kids_notifications').add({
                                    'kidId': kidId,
                                    'choreTitle': choreTitle,
                                    'amountMoney': enteredAmount,
                                    'message': message,
                                    'timestamp': FieldValue.serverTimestamp(),
                                    'type': 'reward',
                                  });

                                  Navigator.pop(context); // Close modal
                                  onRewarded(); // Refresh parent list

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "✅ Chore rewarded successfully!",
                                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "❌ Failed to reward chore. Try again.",
                                        style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF60C56F),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: const BorderSide(color: Colors.black, width: 2),
                                ),
                              ),
                              child: Text(
                                "Confirm and Reward",
                                style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    // Autofocus message field when modal opens
    Future.delayed(const Duration(milliseconds: 300), () {
      FocusScope.of(context).requestFocus(messageFocusNode);
    });
  }

  // BUILD Function:

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back navigation
      onPopInvokedWithResult: (didPop, result) async {},
      child: Scaffold(
        drawer: ParentDrawer(selectedPage: 'notifications', familyName: familyName, user_id: familyUserId, parentId: parentId),
        backgroundColor: const Color(0xFFFFCA26),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFCA26),
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Notifications",
            style: GoogleFonts.fredoka(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          leading: Builder(
            builder: (context) => Padding(
              padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 10),
              child: InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(Icons.menu, color: Color(0xFFFFCA26)),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getNotificationsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading notifications", style: GoogleFonts.fredoka(fontSize: 18, color: Colors.red)),
                  );
                }
                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return Center(
                    child: Text(
                      "No notifications yet!",
                      style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    final isChore = notif['type'] == 'chore_completed';
                    final isRewarded = notif['status'] == 'rewarded';
                    final timestamp = notif['timestamp']?.toDate();
                    final avatarFilePath = notif["kidAvatar"];

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFFFCA26),
                      child: ListTile(
                        leading: CircleAvatar(radius: 25, backgroundImage: AssetImage(avatarFilePath)),
                        title: Text(
                          isChore ? "${notif['kidName']} completed a chore!" : "${notif['kidName']} withdrew \$${(notif['amount'] as num).toStringAsFixed(2)}",
                          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 16, color: isRewarded ? const Color(0xFF7d5e0d) : Colors.black),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isChore)
                              GestureDetector(
                                onTap: isRewarded
                                    ? null
                                    : () {
                                        showRewardChoreModal(
                                          context,
                                          notif['id'], //Pass notification ID
                                          notif['kidName'],
                                          notif['kidId'],
                                          notif['avatar'],
                                          notif['choreTitle'],
                                          1.00,
                                          () {
                                            setState(() {}); // Refresh
                                          },
                                        );
                                      },
                                child: Text(
                                  "\"${notif['choreTitle']}\" | Click to confirm & reward",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF7d5e0d),
                                    decoration: isRewarded ? TextDecoration.none : TextDecoration.underline,
                                  ),
                                ),
                              )
                            else if (timestamp != null)
                              Text(
                                "${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} | "
                                "\"${notif['title']}\""
                                "${(notif['choreDesc'] != null && notif['choreDesc'].toString().isNotEmpty) ? " | ${notif['choreDesc']}" : ""}",
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.black),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
