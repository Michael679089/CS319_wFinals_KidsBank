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

  String _filterType = 'all'; // all, deposit, withdrawal, chore, reward

  @override
  void initState() {
    super.initState();
    debugPrint('🛠 KidsNotificationsPage initState');
    fetchKidInfo();
  }

  Future<void> fetchKidInfo() async {
    debugPrint('📌 Fetching kid info for kidId=${widget.kidId}');
    try {
      final doc = await FirebaseFirestore.instance.collection('kids').doc(widget.kidId).get();
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('✅ Kid data: $data');
        setState(() {
          avatarPath = data['avatar_file_path'] ?? data['avatar'] ?? 'assets/avatar1.png';
          kidName = data['firstName'] ?? 'Kid';
        });
      } else {
        debugPrint('⚠️ Kid doc does not exist');
      }
    } catch (e) {
      debugPrint('❌ Error fetching kid info: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Query<Map<String, dynamic>> _buildQuery() {
    List<String> typeFilter;
    switch (_filterType) {
      case 'deposit':
        typeFilter = ['deposit'];
        break;
      case 'withdrawal':
        typeFilter = ['withdraw'];
        break;
      case 'chore':
        typeFilter = ['locked_reward']; // chores stored as locked_reward
        break;
      case 'reward':
        typeFilter = ['reward'];
        break;
      default:
        typeFilter = ['deposit', 'withdraw', 'reward', 'locked_reward'];
    }

    return FirebaseFirestore.instance
        .collection('kids_notifications')
        .where('kid_id', isEqualTo: widget.kidId)
        .where('type', whereIn: typeFilter)
        .orderBy('created_at', descending: true);
  }

  Map<String, dynamic> _getTypeData(String type) {
    return {
      'deposit': {'icon': '💵', 'color': Colors.lightBlue[100]!, 'title': 'Deposit'},
      'withdraw': {'icon': '🏧', 'color': Colors.orange[100]!, 'title': 'Withdrawal'},
      'locked_reward': {'icon': '🧹', 'color': Colors.purple[100]!, 'title': 'Chore'},
      'reward': {'icon': '🎁', 'color': Colors.green[100]!, 'title': 'Reward'},
    }[type] ??
        {'icon': '🔔', 'color': Colors.grey[100]!, 'title': 'Notification'};
  }

  Widget _buildFilterButton(String typeKey, String label) {
    final selected = _filterType == typeKey;
    return GestureDetector(
      onTap: () {
        if (_filterType != typeKey) {
          debugPrint('🔍 Filter changed: $typeKey');
          setState(() {
            _filterType = typeKey;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFD6327) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Text(
          label,
          style: GoogleFonts.fredoka(
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
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
          labelTextStyle: WidgetStateProperty.all(const TextStyle(color: Colors.white)),
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
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => GestureDetector(
                              onTap: () => Scaffold.of(context).openDrawer(),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black, width: 2),
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
                            ),
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
                      const SizedBox(height: 12),

                      // Filter bar
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterButton('all', 'All'),
                            _buildFilterButton('deposit', 'Deposits'),
                            _buildFilterButton('withdrawal', 'Withdrawals'),
                            _buildFilterButton('chore', 'Chores'),
                            _buildFilterButton('reward', 'Rewards'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Notifications List
                      Expanded(
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _buildQuery().snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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

                            final notifications = snapshot.data!.docs.map((doc) {
                              try {
                                return NotificationModel.fromFirestore(doc, null);
                              } catch (e) {
                                debugPrint('❌ Error parsing notification ${doc.id}: $e');
                                return null;
                              }
                            }).whereType<NotificationModel>().toList();

                            return ListView.builder(
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notif = notifications[index];
                                final timestamp = notif.created_at ?? DateTime.now();
                                final typeData = _getTypeData(notif.type);

                                String displayTitle;
                                String displayMessage;

                                if (notif.type == 'locked_reward') {
                                  displayTitle = "New Chore Added";
                                  displayMessage = notif.notification_message;
                                } else if (notif.type == 'reward') {
                                  displayTitle = "Reward Unlocked: ${notif.notification_title}";
                                  displayMessage =
                                      "Amount: \$${notif.amount.toStringAsFixed(2)}\n${notif.notification_message}";
                                } else {
                                  displayTitle =
                                      "${notif.notification_title}${notif.amount > 0 ? ': \$${notif.amount.toStringAsFixed(2)}' : ''}";
                                  displayMessage = notif.notification_message;
                                }

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: typeData['color'],
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.black, width: 2),
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
                                      displayTitle,
                                      style: GoogleFonts.fredoka(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(displayMessage),
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
