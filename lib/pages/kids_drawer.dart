import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wfinals_kidsbank/pages/verify_email_page_2.dart';
import 'package:wfinals_kidsbank/pages/kids_dashboard.dart';
import 'package:wfinals_kidsbank/pages/kids_chores_page.dart';
import 'package:wfinals_kidsbank/pages/kids_notification.dart';

class KidsDrawer extends StatelessWidget {
  final String selectedPage;
  final String kidId; // Pass kidId for navigation

  const KidsDrawer({
    super.key,
    required this.selectedPage,
    required this.kidId,
  });

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Log out?"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const VerifyEmailPage()),
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
                  padding: const EdgeInsets.all(0),
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
                const SizedBox(width: 12),
                Text(
                  "Menu",
                  style: GoogleFonts.fredoka(
                    fontSize: 44,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 2, color: Colors.black),
          ),

          // Dashboard
          _buildMenuItem(
            context,
            label: "Dashboard",
            isSelected: selectedPage == 'dashboard',
            onTap: () {
              if (selectedPage != 'dashboard') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => KidsDashboard(kidId: kidId),
                  ),
                );
              }
            },
          ),

          // Notifications
          _buildMenuItem(
            context,
            label: "Notifications",
            isSelected: selectedPage == 'notifications',
            onTap: () {
              if (selectedPage != 'notifications') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => KidsNotificationsPage(kidId: kidId),
                  ),
                );
              }
            },
          ),

          // Chores
          _buildMenuItem(
            context,
            label: "Chores",
            isSelected: selectedPage == 'chores',
            onTap: () {
              if (selectedPage != 'chores') {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => KidsChoresPage(kidId: kidId),
                  ),
                );
              }
            },
          ),

          // Logout
          _buildMenuItem(
            context,
            label: "Logout",
            onTap: () => _confirmLogout(context),
          ),

          const Spacer(),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Image.asset('assets/owl2.png', width: 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
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
            style: GoogleFonts.fredoka(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: Colors.black,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
