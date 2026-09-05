// lib/config/api_config.dart
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  // Logout: hapus data user dari SharedPreferences
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('userName');
  }

  // Ambil data user dari SharedPreferences
  static Future<Map<String, dynamic>> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('userId') ?? 0;
    final name = prefs.getString('userName') ?? 'Guru Piket';
    return {'id': id, 'name': name};
  }

  // Dummy method untuk base URL (tidak terpakai karena pakai Firebase)
  static Future<String> getBaseUrl() async {
    return ''; // Tidak digunakan, tapi wajib ada agar tidak error
  }
}
