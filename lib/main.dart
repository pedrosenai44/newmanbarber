import 'package:flutter/material.dart';
import 'package:newmanbarber/telas/login_page.dart';

void main() {
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
        fontFamily: 'sans-serif', // Setting a default font
      ),
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
