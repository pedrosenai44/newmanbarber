import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:newmanbarber/auth_gate.dart'; // Import the new AuthGate

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewManBarber',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'sans-serif',
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // Use AuthGate as the starting point
    );
  }
}
