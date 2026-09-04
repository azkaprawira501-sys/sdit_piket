
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/piket/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal konek server. Cek Wi-Fi & IP.\n$e',
      };
    }
  }

  static Future<Map<String, dynamic>> scan(String qrData, {int? userId}) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final user = await ApiConfig.getUser();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/piket/scan'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'qr_data': qrData,
              'user_id': userId ?? user['id'],
            }),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Koneksi terputus: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getStudents({
    String search = '',
    String kelas = '',
  }) async {
    final baseUrl = await ApiConfig.getBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/api/piket/students').replace(
        queryParameters: {
          'search': search,
          'kelas': kelas,
        },
      );

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'data': [],
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> toggleGate() async {
    final baseUrl = await ApiConfig.getBaseUrl();
    final user = await ApiConfig.getUser();

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/piket/gate-toggle'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'user_id': user['id'],
              'user_name': user['name'],
            }),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal ubah status gerbang',
      };
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    final baseUrl = await ApiConfig.getBaseUrl();
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/piket/stats'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {'success': false};
    }
  }
}
