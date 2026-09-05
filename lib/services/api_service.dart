import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/firebase_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    return {'success': false, 'message': 'Gunakan Firebase Auth'};
  }
}
