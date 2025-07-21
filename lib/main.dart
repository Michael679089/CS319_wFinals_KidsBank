import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wfinals_kidsbank/database/api/auth_service.dart';
import 'package:wfinals_kidsbank/pages/login_page.dart';
import 'package:wfinals_kidsbank/pages/register_page.dart';
import 'package:wfinals_kidsbank/pages/verifyEmail_page.dart';

void main() async {
  // Main Driver Class
  // Initializing Firebase Auth:
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Somewhere in your main or init function (only for debug/development)
  // FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  // FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

  runApp(const MyApp()); // runs my MyApp class below...
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("AuthService State Changes: ${AuthService().authStateChanges}");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/verification-email': (context) => VerificationEmailPage(),
        // '/home': (context) => const HomePage(),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Route Not Found')),
          body: Center(child: Text('No route defined for ${settings.name}')),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: AuthService().authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            final user = snapshot.data;
            if (user != null) {
              // Return widget directly instead of navigating
              // return user.emailVerified ? const HomePage() : const VerificationEmailPage();
            }
            return const LoginPage(); // Default to LoginPage for unauthenticated users
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}
