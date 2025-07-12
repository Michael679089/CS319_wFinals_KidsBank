// wfinals_kidsbank/java/api/fetchCurrentUser.dart
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';  // Add this import
import 'package:flutter/material.dart';
import 'dart:convert'; // For jsonEncode



Future<String> fetchPrintCurrentUserJSON() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userMap = {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'isEmailVerified': user.emailVerified,
      'providerData': user.providerData.map((provider) => {
        'providerId': provider.providerId,
        'uid': provider.uid,
        'displayName': provider.displayName,
        'photoURL': provider.photoURL,
        'email': provider.email,
        'phoneNumber': provider.phoneNumber,
      }).toList(),
      'metadata': {
        'creationTime': user.metadata.creationTime?.toIso8601String(),
        'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
      }
    };
    return jsonEncode(userMap);
  } else {
    print('fetchPrintCurrentUser: No user is currently signed in.');
    return jsonEncode(null);
  }
}


Future<User?> fetchCurrentUser() async {
  // Wait for Firebase to finish initialization (if needed)
  await Future.delayed(Duration.zero);
  FirebaseAuth.instance.currentUser;
  return FirebaseAuth.instance.currentUser;
}

