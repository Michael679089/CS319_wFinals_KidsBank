import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:wfinals_kidsbank/database/models/notifications_model.dart';

import 'package:wfinals_kidsbank/utilities/utilities.dart';

class KidsNotificationsPage extends StatefulWidget {
  final String kidId;

  final dynamic familyUserId;

  const KidsNotificationsPage({
    super.key,

    required this.kidId,

    required this.familyUserId,
  });

  @override
  State<KidsNotificationsPage> createState() => _KidsNotificationsPageState();
}

class _KidsNotificationsPageState extends State<KidsNotificationsPage> {
  String kidName = '';

  String avatarPath = '';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    fetchKidInfo();
  }

  Future<void> fetchKidInfo() async {
    try {
      final kidSnapshot = await FirebaseFirestore.instance
          .collection('kids')
          .doc(widget.kidId)
          .get();

      if (kidSnapshot.exists) {
        final kidData = kidSnapshot.data()!;

        setState(() {
          kidName = kidData['firstName'] ?? 'Kid';

          avatarPath = kidData['avatar'] ?? 'assets/avatar1.png';
        });
      }
    } catch (e) {
      debugPrint('Error fetching kid info: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Fetch notifications and filter for this kid

  /// Updated function:

  Stream<List<NotificationModel>> getKidsNotificationsStream(String kidId) {
    return FirebaseFirestore.instance
        .collection('kids_notifications')
        .snapshots()
        .handleError((error) {
          debugPrint("Error fetching notifications: $error");
          return <QuerySnapshot>[]; // Return empty on error to prevent stream failure
        })
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc, null))
              .where((notif) => notif.kid_id == kidId) // Local filtering
              .toList()
            ..sort((a, b) => (b.created_at ?? DateTime.now())
                .compareTo(a.created_at ?? DateTime.now())); // Local sorting
          
          debugPrint("Loaded ${notifications.length} notifications for $kidId");
          return notifications;
        });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,

      onPopInvokedWithResult: (didPop, result) async {},

      child: Scaffold(
        bottomNavigationBar: NavigationBar(
          onDestinationSelected: (int index) {
            UtilitiesKidsDashboardNavigation.handleKidDashboardNavigationBottomBar(
              index: index,

              kidId: widget.kidId,

              familyUserId: widget.familyUserId,

              context: context,
            );
          },

          selectedIndex: UtilitiesKidsDashboardNavigation.currentPageIndex,

          backgroundColor: const Color.fromARGB(255, 253, 99, 39),

          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.white),
          ),

          destinations: UtilitiesKidsDashboardNavigation.myDestinations,
        ),

        backgroundColor: const Color(0xFFFFCA26),

        body: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),

                  child: Column(
                    children: [
                      // ✅ Header Row: Avatar + Hamburger
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          Builder(
                            builder: (context) {
                              return GestureDetector(
                                onTap: () {
                                  Scaffold.of(context).openDrawer();
                                },

                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,

                                    border: Border.all(
                                      color: Colors.black,

                                      width: 2,
                                    ),
                                  ),

                                  child: ClipOval(
                                    child: Image.asset(
                                      'assets/hamburger_icon.png',

                                      height: 50,

                                      width: 50,

                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,

                                backgroundColor: Colors.white,

                                backgroundImage: AssetImage(avatarPath),
                              ),

                              const SizedBox(width: 10),

                              Text(
                                "Notifications",

                                style: GoogleFonts.fredoka(
                                  fontSize: 36,

                                  fontWeight: FontWeight.bold,

                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ✅ Notifications List
                      Expanded(
                        child: StreamBuilder<List<NotificationModel>>(
                          stream: getKidsNotificationsStream(widget.kidId),

                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 50,
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      "Couldn't load notifications",

                                      style: GoogleFonts.fredoka(
                                        fontSize: 18,

                                        color: Colors.red,

                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    Text(
                                      snapshot.error.toString(),

                                      textAlign: TextAlign.center,

                                      style: GoogleFonts.fredoka(fontSize: 14),
                                    ),

                                    TextButton(
                                      onPressed: () => setState(() {}),

                                      child: Text(
                                        "Try Again",
                                        style: GoogleFonts.fredoka(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            final notifications = snapshot.data ?? [];

                            if (notifications.isEmpty) {
                              return Center(
                                child: Text(
                                  "No notifications yet! 🎉",

                                  style: GoogleFonts.fredoka(
                                    fontSize: 22,

                                    fontWeight: FontWeight.bold,

                                    color: Colors.black,
                                  ),

                                  textAlign: TextAlign.center,
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: notifications.length,

                              itemBuilder: (context, index) {
                                final notif = notifications[index];

                                final timestamp =
                                    notif.created_at ?? DateTime.now();

                                // Determine UI based on notification type

                                Map<String, dynamic> typeData =
                                    {
                                      'deposit': {
                                        'icon': '💵',
                                        'color': Colors.lightBlue[100]!,
                                        'title': 'Deposit',
                                      },

                                      'withdrawal': {
                                        'icon': '🏧',
                                        'color': Colors.orange[100]!,
                                        'title': 'Withdrawal',
                                      },

                                      'chore': {
                                        'icon': '🧹',
                                        'color': Colors.purple[100]!,
                                        'title': 'New Chore',
                                      },

                                      'reward': {
                                        'icon': '🎁',
                                        'color': Colors.green[100]!,
                                        'title': 'Reward',
                                      },
                                    }[notif.type] ??
                                    {
                                      'icon': '🔔',
                                      'color': Colors.grey[100]!,
                                      'title': 'Notification',
                                    };

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),

                                  decoration: BoxDecoration(
                                    color: typeData['color'],

                                    borderRadius: BorderRadius.circular(15),

                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),

                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.transparent,

                                      child: Text(
                                        typeData['icon'],
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),

                                    title: Text(
                                      "${notif.notification_title}${notif.amount > 0 ? ': \$${notif.amount.toStringAsFixed(2)}' : ''}",

                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,

                                        fontSize: 18,

                                        color: Colors.black,
                                      ),
                                    ),

                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,

                                      children: [
                                        Text(notif.notification_message),

                                        Text(
                                          "${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}",

                                          style: GoogleFonts.inter(
                                            fontSize: 12,

                                            color: Colors.grey[700],
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
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
