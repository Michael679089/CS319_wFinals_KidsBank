import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Utilities {
  static void sayHi() {
    debugPrint("Hello World");
  }

  // Widgets
  ButtonStyle ourButtonStyle1() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4E88CF),
      padding: const EdgeInsets.symmetric(vertical: 16),
      side: const BorderSide(color: Colors.black, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

class Utility_TopSnackBar {
  static OverlayEntry? _overlayEntry;

  Utility_TopSnackBar(String s, BuildContext context);

  static void show({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove any existing snackbar before showing a new one
    _overlayEntry?.remove();
    _overlayEntry = null;

    final color = isError ? Colors.red : Colors.green;
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewInsets.top + 40,
        left: 20,
        right: 20,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontFamily: GoogleFonts.fredoka().fontFamily,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);

    Future.delayed(duration, () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }
}

class UtilitiesKidsDashboardNavigation {
  static var selectedPage = "";
  static var currentPageIndex = 0;

  static final WidgetStateProperty<TextStyle?> labelTextStyle =
      WidgetStateProperty.all(TextStyle(color: Colors.white));

  static final _myHamburgerIcon = SizedBox(
    height: 24,
    width: 24,
    child: Image.asset('assets/hamburger_icon.png'),
  );

  static final List<NavigationDestination> myDestinations = [
    NavigationDestination(
      selectedIcon: _myHamburgerIcon,
      icon: Icon(Icons.home_outlined, color: Color(0xFFFFCA26)),
      label: "Dashboard",
    ),
    NavigationDestination(
      selectedIcon: _myHamburgerIcon,
      icon: Icon(Icons.work, color: Color(0xFFFFCA26)),
      label: "Chores",
    ),
    NavigationDestination(
      selectedIcon: _myHamburgerIcon,
      icon: Icon(Icons.notifications, color: Color(0xFFFFCA26)),
      label: "Notifications",
    ),
    NavigationDestination(
      selectedIcon: _myHamburgerIcon,
      icon: Icon(Icons.logout, color: Color(0xFFFFCA26)),
      label: "Log Out",
    ),
  ];

  static void handleKidDashboardNavigationBottomBar({
    required int index,
    required String kidId,
    required String familyUserId,
    required BuildContext context,
  }) {
    var navigator = Navigator.of(context);
    currentPageIndex = index;

    switch (index) {
      case 0:
        if (selectedPage != "dashboard") {
          selectedPage = "dashboard";
          navigator.pushReplacementNamed(
            "/kids-dashboard-page",
            arguments: {"kid-id": kidId, "family-user-id": familyUserId},
          );
        }
        break;
      case 1:
        if (selectedPage != "chores") {
          selectedPage = "chores";
          navigator.pushReplacementNamed(
            "/kids-chores-page",
            arguments: {"kid-id": kidId, "family-user-id": familyUserId},
          );
        }
        break;
      case 2:
        if (selectedPage != "notifications") {
          selectedPage = "notifications";
          navigator.pushReplacementNamed(
            "/kids-notifications-page",
            arguments: {"kid-id": kidId, "family-user-id": familyUserId},
          );
        }
        break;
      case 3:
        if (selectedPage != "logout") {
          selectedPage = "logout";
          navigator.pushReplacementNamed(
            "/account-selector-page",
            arguments: {"kid-id": kidId, "family-user-id": familyUserId},
          );
        }
        break;
    }
  }
}
