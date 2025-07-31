import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/database/api/firestore_service.dart';
import 'package:wfinals_kidsbank/database/models/kid_model.dart';
import 'package:wfinals_kidsbank/database/models/parent_model.dart';
import 'package:wfinals_kidsbank/utilities/utilities.dart';

class AccountSelectorPage extends StatefulWidget {
  final String user_id;

  const AccountSelectorPage({super.key, required this.user_id});

  @override
  State<AccountSelectorPage> createState() => _AccountSelectorPageState();
}

class _AccountSelectorPageState extends State<AccountSelectorPage> {
  ParentModel? Parent;
  List<KidModel> Kids_List = [];
  bool isLoading = true;
  String? errorMessage;
  String? selectedId;
  String? selectedName;
  String? selectedRole;
  String? selectedAvatar;
  OverlayEntry? overlayEntry;
  bool user_first_time = false;

  // Saved Credentials
  String familyName = "";
  String user_id = "";

  // My Services
  final myFirestoreService = FirestoreService();

  // FUNCTIONS

  Future<void> updateFamilyName() async {
    user_id = widget.user_id;
    debugPrint("accountSelectorPage - fetching family name $user_id");
    var newFamilyName = await FirestoreService.fetch_family_name(user_id);

    if (newFamilyName.isEmpty) {
      debugPrint("accountSelectorPage - ERROR: Connection");
    }

    setState(() {
      familyName = newFamilyName;
    });
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
    });

    var navigator = Navigator.of(context);
    var family_id = user_id;

    // Step 1: Get the USER_ID
    final user = AuthService.getCurrentUser();
    if (user == null) {
      setState(() {
        errorMessage = 'User not authenticated';
        isLoading = false;
      });
      return;
    }

    // Step 2: Fetch the parent and all the kids.
    try {
      var the_main_parent = await FirestoreService.readParent(family_id);
      var newKids = await FirestoreService.fetch_all_kids_by_family_id(family_id);

      var is_there_a_parent = the_main_parent != null;

      if (is_there_a_parent == false) {
        setState(() {
          user_first_time = true;
        });

        debugPrint("accountSelectorPage - the main parent is not found - will redirect to /parent-setup-page in 5 seconds");

        // Add 5-second delay before navigation
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            // Check if widget is still in the tree
            navigator.pushNamed("/parent-setup-page");
            debugPrint("accountSelectorPage - redirected to /parent-setup-page");
          }
        });

        return;
      }

      setState(() {
        Parent = the_main_parent;
        Kids_List = newKids;
        isLoading = false;
      });

      debugPrint("accountSelectorPage - fetchUsers successfully");
      return;
    } catch (e) {
      debugPrint("accountSelectorPage - ERROR: fetching users $e");
      return;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleSelectingAccount(String id, String role) {}

  void _handleLoginButton() {
    var navigator = Navigator.of(context);

    debugPrint("accountSelectorPage - LoginBTN pressed: $selectedRole - $selectedName");

    if (selectedName == null || selectedRole == null) {
      Utility_TopSnackBar.show(context: context, message: "Please select a user above first");
      return;
    }

    if (selectedRole == 'parent') {
    } else {}
  }

  // Helper method to show SnackBar, consistent with LoginPage
  void _handleLogOutFromFamily() async {
    var navigator = Navigator.of(context);

    // Step 1: Log User out but don't redirect him yet.
    var logoutResponse = await AuthService.logoutAccount();

    if (logoutResponse["status"] == "success") {
      debugPrint("log out successful");

      // Step 2: If log out successful removed shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.remove('savedEmail');
      prefs.remove('savedPassword');
      prefs.remove('keepLoggedIn');

      // Step 3: Finally Redirect him
      (context, "Logged out successfully!", isError: false);
      navigator.pushReplacementNamed("/login-page");
      return;
    }

    debugPrint("log out failed");
  }

  // INITSTATE
  @override
  void initState() {
    super.initState();
    updateFamilyName();
    fetchUsers();
  }

  Text _buildText(String text, double size, {bool isTextAlignmentCenter = false}) {
    return Text(
      text,
      textAlign: isTextAlignmentCenter ? TextAlign.center : null,
      style: TextStyle(fontSize: size, fontWeight: FontWeight.w600, fontFamily: GoogleFonts.fredoka().fontFamily),
    );
  }

  Text get title => _buildText("Hi!", 56);
  Text get subTitle => _buildText("Who is using?", 28.8);
  Text get parentsLabelText => _buildText("Parents", 20);
  Text get kidsLabelText => _buildText("Kids", 20);

  // BUILD FUNCTION

  @override
  Widget build(BuildContext context) {
    Row TitleDisplay = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          flex: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [title, subTitle]),
        ),
        Flexible(flex: 1, child: Image.asset('assets/owl.png', height: 150, width: 240, alignment: Alignment.centerRight)),
      ],
    );

    Positioned myOwl = Positioned(
      child: Container(color: Colors.red, child: Image.asset('assets/owl.png', height: 150, width: 240)),
    );

    Widget InnerDisplay(bool isLoading) {
      var parentEmpty = (Parent == null);
      var kidEmpty = Kids_List.isEmpty;

      if (isLoading == false && parentEmpty && !user_first_time) {
        return Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Column(children: [parentsLabelText]),
            ),
            Divider(color: Colors.black, thickness: 2, indent: 20, endIndent: 20),
            Container(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              child: Column(children: [kidsLabelText]),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
              margin: EdgeInsetsGeometry.all(40),
              child: ElevatedButton(
                onPressed: _handleLoginButton,
                style: Utilities().ourButtonStyle1(),
                child: Text("Log in as $selectedName", style: TextStyle(fontFamily: GoogleFonts.fredoka().fontFamily)),
              ),
            ),
          ],
        );
      } else if (user_first_time) {
        return Column(children: [_buildText("Its users first time using the app, redirecting to parent selector", 42, isTextAlignmentCenter: true)]);
      } else {
        return Center(child: CircularProgressIndicator());
      }
    }

    Widget MainDisplay(bool isLoading) {
      return Container(
        margin: EdgeInsets.all(20),
        child: Column(
          children: [
            TitleDisplay,
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: InnerDisplay(isLoading),
            ),

            ElevatedButton(onPressed: _handleLogOutFromFamily, style: Utilities().ourButtonStyle1(), child: Text("Log out from Family")),
          ],
        ),
      );
    }

    ///
    ///
    ///
    ///
    ///

    var doesParentExist = (Parent != null);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        debugPrint("accountSelectorPage - User attempted to go back through phone btns");
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFCA26),
        appBar: AppBar(backgroundColor: const Color(0xFFFFCA26), title: const Text("Account Selector Page"), automaticallyImplyLeading: false),
        body: MainDisplay(isLoading),
      ),
    );
  }
}
