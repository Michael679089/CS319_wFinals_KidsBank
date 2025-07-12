import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';

import '../home.dart';
import '../api/fetchCurrentUser.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key, required this.clientId}) {
    debugPrint("You called RegisterPage.");
  }

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: fetchCurrentUser(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) { // Ask info if no previous userData.
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(clientId: clientId),
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/flutterfire_300x.png'),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: action == AuthAction.signIn
                      ? const Text('Welcome to FlutterFire, please sign in!')
                      : const Text('Welcome to Flutterfire, please sign up!')
              );
            },
            footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
            sideBuilder: (context, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('flutterfire_300x.png'),
                ),
              );
            },
          );
        }

        print("Found User: ");
        print(fetchPrintCurrentUserJSON());

        return const HomeScreen(); // else login to screen.
      },
    );
  }
}
