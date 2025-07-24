import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'parent_drawer.dart';
import 'package:flutter/services.dart';

class ParentNotificationsPage extends StatefulWidget {
  const ParentNotificationsPage({super.key});

  @override
  State<ParentNotificationsPage> createState() =>
      _ParentNotificationsPageState();
}

class _ParentNotificationsPageState extends State<ParentNotificationsPage> {
  /// Fetch notifications stream with kid info
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    return FirebaseFirestore.instance
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> notifications = [];

          for (var doc in snapshot.docs) {
            final data = doc.data();
            final kidId = data['kid_id'];

            // Fetch kid info from kids collection
            final kidSnapshot = await FirebaseFirestore.instance
                .collection('kids')
                .doc(kidId)
                .get();

            String kidName = data['kid_name'] ?? 'Kid';
            String avatarPath = 'assets/avatar1.png'; // Default avatar

            if (kidSnapshot.exists) {
              final kidData = kidSnapshot.data()!;
              kidName = kidData['firstName'] ?? kidName;
              avatarPath = kidData['avatar'] ?? avatarPath;
            }

            notifications.add({
              'id': doc.id,
              'type': data['type'], // withdrawal OR chore_completed
              'kidId': kidId,
              'kidName': kidName,
              'avatar': avatarPath,
              'choreTitle': data['chore_title'], // for chore_completed
              'choreDesc': data['description'], // for chore_completed
              'title': data['title'], // for withdrawal
              'amount': data['amount'], // for withdrawal
              'status': data['status'] ?? 'pending',
              'timestamp': data['timestamp'],
            });
          }
          return notifications;
        });
  }

  // Saved credentials
  String familyName = '';
  String familyUserId = '';

  // INITSTATE Function:

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMyFamilyData();
    });
  }

  // Other Functions:

  void _loadMyFamilyData() async {
    final myModalRoute = ModalRoute.of(context);
    if (myModalRoute == null) {
      return;
    }
    final args = myModalRoute.settings.arguments as Map<String, String?>;
    setState(() {
      familyName = args['family-name'] as String;
      familyUserId = args["family-user-id"] as String;
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
    final TextEditingController amountController = TextEditingController(
      text: defaultReward.toStringAsFixed(2),
    );
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
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom * 0.4,
              ),
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
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Image.asset(
                            avatar,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 10),
                            Text(
                              "Reward Chore",
                              style: GoogleFonts.fredoka(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "for $kidName",
                              style: GoogleFonts.fredoka(
                                fontSize: 24,
                                color: Colors.black54,
                              ),
                            ),
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
                                        amountController.text = rewardAmount
                                            .toStringAsFixed(2);
                                      }
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCA26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
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
                                    focusNode:
                                        FocusNode(), // Prevent auto-focus
                                    textAlign: TextAlign.center,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d+\.?\d{0,2}'),
                                      ), // Allow numbers and decimal
                                    ],
                                    decoration: InputDecoration(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setModalState(() {
                                        rewardAmount =
                                            double.tryParse(value) ?? 0;
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
                                      amountController.text = rewardAmount
                                          .toStringAsFixed(2);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFCA26),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
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
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Confirm Button
                            ElevatedButton(
                              onPressed: () async {
                                final String message = messageController.text
                                    .trim();
                                final enteredAmount = double.tryParse(
                                  amountController.text.trim(),
                                );

                                // ⚠️ Error checks
                                if (enteredAmount == null ||
                                    enteredAmount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "⚠️ Please enter a valid reward amount.",
                                        style: GoogleFonts.fredoka(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
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
                                        style: GoogleFonts.fredoka(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  // 1. Update kid's balance
                                  final paymentDoc = FirebaseFirestore.instance
                                      .collection('kids_payment_info')
                                      .doc(kidId);

                                  final paymentSnapshot = await paymentDoc
                                      .get();
                                  double currentBalance = 0;
                                  if (paymentSnapshot.exists) {
                                    currentBalance =
                                        (paymentSnapshot
                                                    .data()?['usable_balance'] ??
                                                0)
                                            .toDouble();
                                  }

                                  final newBalance =
                                      currentBalance + enteredAmount;

                                  await paymentDoc.set({
                                    'usable_balance': newBalance,
                                    'last_updated':
                                        FieldValue.serverTimestamp(),
                                  });

                                  // 2. Update notification & chore status
                                  await FirebaseFirestore.instance
                                      .collection('notifications')
                                      .doc(notifId)
                                      .update({'status': 'rewarded'});

                                  final choreQuery = await FirebaseFirestore
                                      .instance
                                      .collection('chores')
                                      .where('kid_id', isEqualTo: kidId)
                                      .where(
                                        'chore_title',
                                        isEqualTo: choreTitle,
                                      )
                                      .get();

                                  for (var choreDoc in choreQuery.docs) {
                                    await choreDoc.reference.update({
                                      'status': 'rewarded',
                                    });
                                  }

                                  // 3. Add kids notification with message
                                  await FirebaseFirestore.instance
                                      .collection('kids_notifications')
                                      .add({
                                        'kid_id': kidId,
                                        'chore_title': choreTitle,
                                        'amount': enteredAmount,
                                        'message': message,
                                        'timestamp':
                                            FieldValue.serverTimestamp(),
                                        'type': 'reward',
                                      });

                                  Navigator.pop(context); // Close modal
                                  onRewarded(); // Refresh parent list

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "✅ Chore rewarded successfully!",
                                        style: GoogleFonts.fredoka(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
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
                                        style: GoogleFonts.fredoka(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF60C56F),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                "Confirm and Reward",
                                style: GoogleFonts.fredoka(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
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
        drawer: ParentDrawer(
          selectedPage: 'notifications',
          familyName: familyName,
          familyUserId: familyUserId,
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
              padding: const EdgeInsets.only(
                left: 12,
                right: 4,
                top: 5,
                bottom: 10,
              ),
              child: InkWell(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
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
                    child: Text(
                      "Error loading notifications",
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        color: Colors.red,
                      ),
                    ),
                  );
                }
                final notifications = snapshot.data ?? [];
                if (notifications.isEmpty) {
                  return Center(
                    child: Text(
                      "No notifications yet!",
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
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

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFFFFCA26),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundImage: AssetImage(notif['avatar']),
                        ),
                        title: Text(
                          isChore
                              ? "${notif['kidName']} completed a chore!"
                              : "${notif['kidName']} withdrew \$${(notif['amount'] as num).toStringAsFixed(2)}",
                          style: GoogleFonts.fredoka(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isRewarded
                                ? const Color(0xFF7d5e0d)
                                : Colors.black,
                          ),
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
                                    decoration: isRewarded
                                        ? TextDecoration.none
                                        : TextDecoration.underline,
                                  ),
                                ),
                              )
                            else if (timestamp != null)
                              Text(
                                "${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} | "
                                "\"${notif['title']}\""
                                "${(notif['choreDesc'] != null && notif['choreDesc'].toString().isNotEmpty) ? " | ${notif['choreDesc']}" : ""}",
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
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
