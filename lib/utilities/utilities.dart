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

  // functions:

  static void invokeTopSnackBar(
    String message,
    BuildContext context, {
    bool isError = true,
  }) {
    final snackBar = SnackBar(
      content: Text(message, style: GoogleFonts.fredoka(color: Colors.white)),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
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
