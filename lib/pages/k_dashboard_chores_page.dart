import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class KidsChoresPage extends StatefulWidget {
  final String kid_id;
  final dynamic familyUserId;

  const KidsChoresPage({
    super.key,
    required this.kid_id,
    required this.familyUserId,
  });

  @override
  State<KidsChoresPage> createState() => _KidsChoresPageState();
}

class _KidsChoresPageState extends State<KidsChoresPage> {
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
          .doc(widget.kid_id)
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

  Stream<List<ChoreModel>> getChoresStream(String kidId) {
    return FirebaseFirestore.instance
        .collection('chores')
        .where('kid_id', isEqualTo: kidId) // Consistent field name casing
        .snapshots()
        .handleError((error) {
          debugPrint('Error fetching chores: $error');
          return const Stream<
            List<ChoreModel>
          >.empty(); // Return empty stream on error
        })
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                try {
                  return ChoreModel.fromFirestore(
                    doc, // Pass the DocumentSnapshot directly
                    null, // Or provide SnapshotOptions if needed
                  );
                } catch (e) {
                  debugPrint('Error parsing chore ${doc.id}: $e');
                  return null;
                }
              })
              .whereType<ChoreModel>()
              .toList(); // Filter out null values
        });
  }

  Future<void> handleChoreTap(
    String choreId,
    String title,
    bool isLocked,
  ) async {
    if (isLocked) return;

    bool confirmed = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          "Mark Chore as Completed?",
          style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to mark \"$title\" as completed? This will notify your parent for approval.",
          style: GoogleFonts.fredoka(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.fredoka(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              "Yes",
              style: GoogleFonts.fredoka(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (!confirmed) return;

    await FirebaseFirestore.instance.collection('chores').doc(choreId).update({
      'status': 'completed',
    });

    await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'chore_completed',
      'KidId': widget.kid_id,
      'firstName': kidName,
      'choreTitle': title,
      'timestamp': FieldValue.serverTimestamp(),
    });

    showCustomSnackBar(
      "\u2714\uFE0F \"$title\" marked as completed!",
      Colors.green,
    );
  }

  void showCustomSnackBar(String message, Color bgColor) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: GoogleFonts.fredoka(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 50, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Color getTileColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange[100]!;
      case 'completed':
        return Colors.green[100]!;
      case 'rewarded':
        return Colors.blue[100]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Color getIconColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'rewarded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
              kidId: widget.kid_id,
              familyUserId: widget.familyUserId,
              context: context,
            );
          },
          selectedIndex: UtilitiesKidsDashboardNavigation.currentPageIndex,
          backgroundColor: const Color.fromARGB(255, 253, 99, 39),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(color: Colors.yellow),
          ),
          indicatorColor: Colors.orange.shade200,
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
                                  padding: const EdgeInsets.all(0),
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
                                "$kidName's Chores",
                                style: GoogleFonts.fredoka(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: StreamBuilder<List<ChoreModel>>(
                          stream: getChoresStream(widget.kid_id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(
                                child: Text(
                                  "No chores assigned yet! \uD83C\uDF89",
                                  style: GoogleFonts.fredoka(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            }
                            final chores = snapshot.data!;
                            return ListView.builder(
                              itemCount: chores.length,
                              itemBuilder: (context, index) {
                                final chore = chores[index];
                                final isLocked =
                                    chore.status == 'completed' ||
                                    chore.status == 'rewarded';

                                return GestureDetector(
                                  onTap: () => handleChoreTap(
                                    chore.id as String,
                                    chore.chore_title,
                                    isLocked,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getTileColor(chore.status),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: Colors.black,
                                        width: 2,
                                      ),
                                    ),
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.task_alt,
                                        color: getIconColor(chore.status),
                                        size: 30,
                                      ),
                                      title: Text(
                                        chore.chore_title,
                                        style: GoogleFonts.fredoka(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chore.chore_description,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            chore.status == 'pending'
                                                ? "\uD83D\uDFE0 Pending"
                                                : chore.status == 'completed'
                                                ? "\uD83D\uDFE2 Completed! Waiting for Parent"
                                                : "\uD83D\uDD35 Rewarded",
                                            style: GoogleFonts.fredoka(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: getIconColor(chore.status),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        child: Text(
                                          "\$${chore.reward_money.toStringAsFixed(2)}",
                                          style: GoogleFonts.fredoka(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
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
