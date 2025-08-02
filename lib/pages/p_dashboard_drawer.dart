import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParentDrawer extends StatelessWidget {
  final String selectedPage;

  // Saved credentials
  final String familyName;
  final String user_id;
  final String parentId;

  // Constructor of our drawer navbar page
  const ParentDrawer({super.key, required this.selectedPage, required this.familyName, required this.user_id, required this.parentId});

  void _handleConfirmLogOut(BuildContext context) {
    var navigator = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log out?"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              navigator.pop(); // close dialog

              navigator.pushReplacementNamed(
                "/account-selector-page",
                arguments: {"family-name": familyName, "user-id": user_id, "there-are-parent-in-family": true},
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Log out"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var navigator = Navigator.of(context);

    return Drawer(
      backgroundColor: const Color(0xFFFFCA26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                  padding: const EdgeInsets.all(5),
                  child: const Icon(Icons.menu, color: Color(0xFFFFCA26), size: 28),
                ),
                const SizedBox(width: 12),
                Text(
                  "Menu",
                  style: GoogleFonts.fredoka(fontSize: 44, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 2, color: Colors.black),
          ),
          _buildMenuItem(
            context,
            label: "Dashboard",
            isSelected: selectedPage == 'dashboard',
            onTap: () {
              if (selectedPage != 'dashboard') {
                navigator.pushReplacementNamed(
                  "/parent-dashboard-page",
                  arguments: {"parent-id": parentId, "family-name": familyName, "family-user-id": user_id},
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            label: "Notifications",
            isSelected: selectedPage == 'notifications',
            onTap: () {
              if (selectedPage != 'notifications') {
                navigator.pushReplacementNamed(
                  "/parent-notifications-page",
                  arguments: {"family-name": familyName, "family-user-id": user_id, "parent-id": parentId},
                );

                debugPrint("parentDashboardDrawer - redirected to notifications - check: $parentId");
              }
            },
          ),
          _buildMenuItem(
            context,
            label: "Chores",
            isSelected: selectedPage == 'chores',
            onTap: () {
              if (selectedPage != 'chores') {
                navigator.pushReplacementNamed("/parent-chores-page", arguments: {"parent-id": parentId, "family-name": familyName, "family-user-id": user_id});
              }
            },
          ),
          _buildMenuItem(
            context,
            label: "Make Child Account",
            isSelected: selectedPage == 'make-new-child-account',
            onTap: () {
              if (selectedPage != 'make-new-child-account') {
                navigator.pushNamed(
                  "/kids-setup-page",
                  arguments: {"family-name": familyName, "family-user-id": user_id, "came-from-parent-dashboard": true, "parent-id": parentId},
                );
              }
            },
          ),
          _buildMenuItem(context, label: "Logout", onTap: () => _handleConfirmLogOut(context)),
          const Spacer(),
          Center(
            child: Padding(padding: const EdgeInsets.only(bottom: 20), child: Image.asset('assets/owl2.png', width: 200)),
          ),
        ],
      ),
    );
  }

  // Widgets for BUILD

  Widget _buildMenuItem(BuildContext context, {required String label, required VoidCallback onTap, bool isSelected = false}) {
    return ListTile(
      title: Row(
        children: [
          if (isSelected)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.circle, size: 10, color: Colors.black),
            ),
          Text(
            label,
            style: GoogleFonts.fredoka(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.black),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
