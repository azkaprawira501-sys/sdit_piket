
import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'views/home_view.dart';
import 'views/login_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
