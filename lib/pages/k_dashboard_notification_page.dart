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
        .where(
          'kid_id',
          isEqualTo: kidId,
        ) // Filter at query level for efficiency
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          debugPrint('Error in notifications stream: $error');
          return Stream.value(
            [],
          ); // Return empty list on error to keep stream alive
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return NotificationModel.fromFirestore(
                    doc,
                    null,
                  ); // Pass the whole doc
                } catch (e) {
                  debugPrint('Error parsing notification ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<NotificationModel>() // Remove nulls
              .toList();
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
                                child: Text(
                                  "⚠️ Error: \${snapshot.error}",
                                  style: GoogleFonts.fredoka(
                                    fontSize: 18,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
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
                                final timestamp = notif.created_at;
                                final type = notif.type;

                                String title = "";
                                String subtitle = "";

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      radius: 25,
                                      backgroundColor: const Color(0xFFFFCA26),
                                      child: Text(
                                        type == 'reward'
                                            ? "🎁"
                                            : type == 'deposit'
                                            ? "💵"
                                            : type == 'withdrawal'
                                            ? "🏧"
                                            : "🔔",
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    title: Text(
                                      title,
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
                                        Text(
                                          subtitle,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          "\${timestamp.month}/\${timestamp.day} \${timestamp.hour}:\${timestamp.minute.toString().padLeft(2, '0')}",
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        if (notif
                                            .notification_message
                                            .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              "💌 \${notif.message}",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                                color: Colors.black54,
                                              ),
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
