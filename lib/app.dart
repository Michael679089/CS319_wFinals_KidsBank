import 'package:flutter/material.dart';

import 'pages/register.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: RegisterPage(clientId: clientId),
    );
  }
}
