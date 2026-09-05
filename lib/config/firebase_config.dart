import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseConfig {
  // DATA DARI GOOGLE-SERVICES.JSON ANDA (SUDAH TEPAT & SESUAI)
  static const FirebaseOptions options = FirebaseOptions(
    apiKey: "AIzaSyCpnnsmGYcbYhW691-56aSbXXCb_tnlMWY",
    appId: "1:947534562613:android:ab45fa84f0d21b6887787c",
    messagingSenderId: "947534562613",
    projectId: "sdit-absensi",
    databaseURL: "https://sdit-absensi-default-rtdb.asia-southeast1.firebasedatabase.app",
  );

  static const String keyUserName = 'user_name';
  static const String keyUserId = 'user_id';
  static const String keyIsLoggedIn = 'is_logged_in';

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsLoggedIn) ?? false;
  }

  static Future<void> saveUser(int id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyUserId, id);
    await prefs.setString(keyUserName, name);
    await prefs.setBool(keyIsLoggedIn, true);
  }

  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getInt(keyUserId) ?? 0,
      'name': prefs.getString(keyUserName) ?? 'Guru Piket',
    };
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyIsLoggedIn);
    await prefs.remove(keyUserId);
    await prefs.remove(keyUserName);
  }
}
