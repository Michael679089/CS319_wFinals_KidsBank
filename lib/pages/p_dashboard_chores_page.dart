import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/chores_model.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'p_dashboard_drawer.dart';

class ParentChoresPage extends StatefulWidget {
  final String user_id;
  final String parentId;
  final String family_id; 

  const ParentChoresPage({super.key, required this.user_id, required this.parentId, required this.family_id});

  @override
  State<ParentChoresPage> createState() => _ParentChoresPageState();
}

class _ParentChoresPageState extends State<ParentChoresPage> {
  List<KidModel> kids = [];
  String? selectedKidId;
  String selectedStatus = 'All';
  String familyName = '';

  final FirestoreService myFirestoreService = FirestoreService();
  bool isLoadingKids = true;

  @override
  void initState() {
    super.initState();
    loadKids();
  }

  Future<void> loadKids() async {
    var family_object = await FirestoreService.readFamily(widget.user_id);
    var family_id = family_object?.id;

    final loadedKids = await FirestoreService.fetch_all_kids_by_family_id(family_id!);
    final family_name = family_object?.family_name;

    if (mounted) {
      setState(() {
        kids = loadedKids;
        selectedKidId = loadedKids.isNotEmpty ? loadedKids.first.id : null;
        familyName = family_name!;
        isLoadingKids = false;
      });
    }
  }

  Future<List<ChoreModel>> fetchChores() async {
    if (selectedKidId == null) return [];
    debugPrint("Calling getAllChores");
    List<ChoreModel> chores = await FirestoreService.fetch_all_chores_by_kid_id(selectedKidId as String);

    if (selectedStatus != 'All') {
      chores = chores.where((chore) => chore.status.toLowerCase() == selectedStatus.toLowerCase()).toList();
    }

    return chores;
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
        drawer: ParentDrawer(selectedPage: 'chores', familyName: familyName, user_id: widget.user_id, parentId: widget.parentId, family_id: widget.family_id),
        backgroundColor: const Color(0xFFFFCA26),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFCA26),
          elevation: 0,
          title: Text(
            "Chores",
            style: GoogleFonts.fredoka(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
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
        body: isLoadingKids
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Kid Selector
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: kids.length,
                        itemBuilder: (context, index) {
                          final kid = kids[index];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedKidId = kid.id;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: selectedKidId == kid.id ? Colors.black : Colors.transparent, width: 3),
                              ),
                              child: CircleAvatar(radius: 30, backgroundImage: AssetImage(kid.avatar_file_path)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status Filter Dropdown
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        DropdownButton<String>(
                          value: selectedStatus,
                          items: ['All', 'Pending', 'Completed', 'Rewarded'].map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status, style: GoogleFonts.fredoka(fontSize: 16, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedStatus = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Chore List
                    Expanded(
                      child: FutureBuilder<List<ChoreModel>>(
                        future: fetchChores(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text("No chores found.", style: GoogleFonts.fredoka(fontSize: 22, fontWeight: FontWeight.bold)),
                            );
                          }

                          final chores = snapshot.data!;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF2D0),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: ListView.builder(
                              itemCount: chores.length,
                              itemBuilder: (context, index) {
                                final chore = chores[index];
                                final statusColor = getStatusColor(chore.status);

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.black, width: 2),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.assignment, color: Colors.black),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(chore.chore_title, style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 20)),
                                            const SizedBox(height: 4),
                                            Text(chore.chore_description, style: GoogleFonts.fredoka(fontSize: 15)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "\$${chore.reward_money.toStringAsFixed(2)}",
                                            style: GoogleFonts.fredoka(fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            chore.status[0].toUpperCase() + chore.status.substring(1),
                                            style: GoogleFonts.fredoka(color: statusColor, fontWeight: FontWeight.w600, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}