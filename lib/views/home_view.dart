import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/firebase_config.dart';
import '../services/firebase_scan_service.dart';
import 'login_view.dart';
import 'students_view.dart';
import 'gate_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualNisController = TextEditingController();

  bool _isProcessing = false;
  Map<String, dynamic>? _lastResult;
  String _userName = 'Guru Piket';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() async {
    final user = await FirebaseConfig.getUser();
    setState(() {
      _userName = user['name'] ?? 'Guru Piket';
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final String? qrData = capture.barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    _sendToFirebase(qrData, 'kamera');
  }

  void _submitManual() {
    final String nis = _manualNisController.text.trim();
    if (nis.isEmpty) return;

    _manualNisController.clear();
    FocusScope.of(context).unfocus();

    _sendToFirebase(nis, 'manual');
  }

  void _sendToFirebase(String qrData, String method) {
    setState(() {
      _isProcessing = true;
    });

    FirebaseScanService.processScan(
      qrData: qrData,
      method: method,
      scannedBy: _userName,
      onSuccess: (result) {
        if (!mounted) return;
        setState(() {
          _lastResult = result;
        });

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _lastResult = null;
              _isProcessing = false;
            });
          }
        });
      },
      onError: (errorMsg) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualNisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text('SDIT UKHUWAH - PIKET',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.lightBlueAccent)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseConfig.logout();
              if (!mounted) return;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const LoginView()));
            },
          )
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
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.lightBlueAccent,
        unselectedItemColor: Colors.white54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Siswa'),
          BottomNavigationBarItem(icon: Icon(Icons.lock_clock_rounded), label: 'Gerbang'),
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
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('📷 Kamera Active (Realtime Cloud)',
                        style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manualNisController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Ketik NIS Manual...',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitManual(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _submitManual,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isProcessing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('ABSEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: _lastResult == null
                ? const Center(
                    child: Text(
                      'Scan Kartu Pelajar atau Ketik NIS\n(Real-Time Cloud Sync)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _lastResult!['ok'] == true ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _lastResult!['ok'] == true ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _lastResult!['nama'] ?? 'Tidak Dikenal',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kelas ${_lastResult!['kelas'] ?? '-'} • NIS: ${_lastResult!['nis'] ?? '-'}',
                          style: const TextStyle(fontSize: 11, color: Colors.lightBlueAccent),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _lastResult!['ok'] == true ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _lastResult!['type'] ?? 'GAGAL',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.black, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastResult!['message'] ?? '',
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
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
