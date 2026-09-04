
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import 'gate_view.dart';
import 'login_view.dart';
import 'students_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;
  Map<String, dynamic>? _lastResult;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final qrData = capture.barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() => _isProcessing = true);

    final res = await ApiService.scan(qrData);
    setState(() => _lastResult = res);

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _lastResult = null;
        _isProcessing = false;
      });
    });
  }

  Future<void> _logout() async {
    await ApiConfig.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'SDIT UKHUWAH - PIKET',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildScanTab(),
          const StudentsView(),
          const GateView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.lightBlueAccent,
        unselectedItemColor: Colors.white54,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Siswa'),
          BottomNavigationBarItem(icon: Icon(Icons.lock_clock), label: 'Gerbang'),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white12),
            ),
            clipBehavior: Clip.antiAlias,
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _lastResult == null
                ? const Center(
                    child: Text(
                      'Arahkan kamera ke QR kartu pelajar',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (_lastResult!['success'] == true)
                          ? Colors.green.withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (_lastResult!['success'] == true) ? Colors.green : Colors.red,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _lastResult!['data']?['nama']?.toString() ?? 'Tidak Dikenal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelas ${_lastResult!['data']?['kelas'] ?? '-'} • NIS: ${_lastResult!['data']?['nis'] ?? '-'}',
                          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastResult!['status']?.toString() ?? 'GAGAL',
                          style: TextStyle(
                            color: (_lastResult!['success'] == true) ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastResult!['message']?.toString() ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
