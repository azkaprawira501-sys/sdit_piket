
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _ipController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedConfig();
  }

  Future<void> _loadSavedConfig() async {
    final ip = await ApiConfig.getBaseUrl();
    setState(() {
      _ipController.text = ip;
      _emailController.text = 'piket@sdit.sch.id';
      _passwordController.text = 'password';
    });
  }

  Future<void> _doLogin() async {
    setState(() => _isLoading = true);

    await ApiConfig.setBaseUrl(_ipController.text.trim());
    final res = await ApiService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (res['success'] == true) {
      final data = res['data'] as Map<String, dynamic>;
      await ApiConfig.saveUser(data['id'] as int, data['name'] as String);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeView()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']?.toString() ?? 'Login gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.school_rounded, size: 64, color: Colors.lightBlueAccent),
                const SizedBox(height: 12),
                const Text(
                  'SDIT UKHUWAH',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Aplikasi Guru Piket',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 28),
                _buildField(
                  controller: _ipController,
                  label: 'IP Server Sekolah (Wi-Fi)',
                  icon: Icons.wifi,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _emailController,
                  label: 'Email Guru Piket',
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _doLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'MASUK APLIKASI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.lightBlueAccent),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
