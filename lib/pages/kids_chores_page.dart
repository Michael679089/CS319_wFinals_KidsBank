import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kids_dashboard.dart'; // <-- Import the dashboard to navigate back

class KidsChoresPage extends StatelessWidget {
  final String kidName = "Johnson"; // This will later come from Firebase
  final String avatarPath = "assets/avatar.png"; // Placeholder for profile icon

  final List<Map<String, dynamic>> chores = [
    {
      'title': 'Room',
      'description': 'Change Bedsheets',
      'price': 5,
      'color': Color(0xFFFFC2C2), // light red
    },
    {
      'title': 'Kitchen',
      'description': 'Wash Dishes',
      'price': 7,
      'color': Color(0xFFD2C2FF), // lavender
    },
    {
      'title': 'Living Room',
      'description': 'Sweep Floors',
      'price': 5,
      'color': Color(0xFFFF8B60), // orange
    },
    {
      'title': 'Kitchen',
      'description': 'Basta',
      'price': 3,
      'color': Color(0xFFC2FFD2), // mint green
    },
    {
      'title': 'Outdoors',
      'description': 'Takeout Trash',
      'price': 10,
      'color': Color(0xFFAEDDFF), // soft blue
    },
  ];

  KidsChoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFCA26), // Yellow background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Icon and Kid's Name (split into two lines)
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blue[200], // Placeholder color
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                    // backgroundImage: AssetImage(avatarPath),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "$kidName’s\nChores", // <-- New line for Chores
                    style: GoogleFonts.fredoka(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2, // Adjust line spacing
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Chores List wrapped in Container
              Expanded(
                child: chores.isNotEmpty
                    ? Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF8E1), // Light yellow background
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black,
                            width: 2,
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: chores.length,
                          itemBuilder: (context, index) {
                            final chore = chores[index];
                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: chore['color'],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.black,
                                  width: 2,
                                ),
                              ),
                              child: ListTile(
                                leading: Icon(Icons.check_circle,
                                    color: Colors.green, size: 28),
                                title: Text(
                                  chore['title'],
                                  style: GoogleFonts.fredoka(
                                    fontSize: 23,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  chore['description'],
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFefe6e8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    "\$${chore['price']}",
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          "No chores assigned yet!",
                          style: GoogleFonts.fredoka(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
              ),

              SizedBox(height: 10),

              // Back Button below chores list
              Align(
                alignment: Alignment.center,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => KidsDashboard()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    "Back",
                    style: GoogleFonts.fredoka(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
