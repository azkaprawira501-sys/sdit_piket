import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/firebase_config.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: FirebaseConfig.options,
    );
  } catch (e) {
    debugPrint('Firebase init: $e');
  }

  final loggedIn = await FirebaseConfig.isLoggedIn();

  runApp(
    MaterialApp(
      title: 'SDIT Piket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: loggedIn ? const HomeView() : const LoginView(),
    ),
  );
}
