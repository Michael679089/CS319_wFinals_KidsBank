import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';

class AccountSelectorPage extends StatefulWidget {
  const AccountSelectorPage({super.key});

  @override
  State<AccountSelectorPage> createState() => _AccountSelectorPageState();
}

class _AccountSelectorPageState extends State<AccountSelectorPage> {
  // Saved Credentials
  String familyName = "";
  String familyUserId = "";
  List<ParentModel> parents = [];
  bool isLoading = true;
  String? errorMessage;

  // My Services
  var myFirestoreAPI = FirestoreAPI();

  // FUNCTIONS
  Future<void> updateFamilyName() async {
    var myModalRoute = ModalRoute.of(context);

    if (myModalRoute == null) {
      setState(() {
        errorMessage = 'Navigation arguments not found';
        isLoading = false;
      });
      return;
    }

    final args = myModalRoute.settings.arguments as Map<String, String>;
    final newFamilyName = args["family-name"] as String;
    final newUserId = args["family-user-id"] as String;

    setState(() {
      familyName = newFamilyName;
      familyUserId = newUserId;
    });

    // Fetch parents
    await fetchParents();
  }

  Future<void> fetchParents() async {
    try {
      final parentList = await myFirestoreAPI.getParentsByFamilyUserId(
        familyUserId,
      );
      setState(() {
        parents = parentList;
        isLoading = false;
      });

      // Check if there are parents, redirect to setup if none
      if (parentList.isEmpty) {
        Navigator.of(context).pushNamed('/parent-setup-page');
        debugPrint(
          "accountSelectorPage - No Parent found, Redirected to Parent-Setup-Page",
        );
      }
      debugPrint("accountSelectorPage - successfully fetched parents");
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load parents: $e';
        isLoading = false;
      });
    }
  }

  // INITSTATE
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updateFamilyName();
    });
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFCA26),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              "Hi!",
              style: TextStyle(
                fontFamily: GoogleFonts.fredoka().fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              "$familyName Family",
              style: TextStyle(
                fontFamily: GoogleFonts.fredoka().fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Who is using?",
              style: TextStyle(
                fontFamily: GoogleFonts.fredoka().fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(
                        fontFamily: GoogleFonts.fredoka().fontFamily,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  )
                : parents.isEmpty
                ? const Center(
                    child: Text(
                      "No parents found. Redirecting to setup...",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: parents.length,
                      itemBuilder: (context, index) {
                        final parent = parents[index];
                        return Card(
                          color: const Color(0xFFF9F1F1),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 2,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              "${parent.firstName} ${parent.lastName}",
                              style: TextStyle(
                                fontFamily: GoogleFonts.fredoka().fontFamily,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onTap: () => navigateToParentDashboard(parent),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
