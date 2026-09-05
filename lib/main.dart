import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/api_config.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi Firebase Engine
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase auto-init: $e');
  }

  final loggedIn = await ApiConfig.isLoggedIn();

  runApp(
    MaterialApp(
      title: 'SDIT Piket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: loggedIn ? const HomeView() : const LoginView(),
    ),
  );
}
