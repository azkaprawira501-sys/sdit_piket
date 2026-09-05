import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../config/firebase_config.dart';
import '../services/firebase_scan_service.dart';
import 'login_view.dart';
import 'students_view.dart'; // dipakai sebagai halaman RIWAYAT (Opsi B)
import 'gate_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final TextEditingController _manualNisController = TextEditingController();

  bool _isProcessing = false;
  bool _camOn = true;
  Map<String, dynamic>? _lastResult;
  String _userName = 'Guru Piket';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await FirebaseConfig.getUser();
    if (!mounted) return;
    setState(() {
      _userName = (user['name'] ?? 'Guru Piket').toString();
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_camOn) return;
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final String? qrData = capture.barcodes.first.rawValue;
    if (qrData == null || qrData.trim().isEmpty) return;

    _sendToFirebase(qrData.trim(), 'kamera');
  }

  void _submitManual() {
    if (_isProcessing) return;

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

        // Reset popup setelah 4 detik
        Future.delayed(const Duration(seconds: 4), () {
          if (!mounted) return;
          setState(() {
            _lastResult = null;
            _isProcessing = false;
          });
        });
      },
      onError: (errorMsg) {
        if (!mounted) return;

        setState(() {
          _isProcessing = false;
          _lastResult = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      },
    );
  }

  Future<void> _toggleCamera() async {
    try {
      if (_camOn) {
        await _scannerController.stop();
        if (!mounted) return;
        setState(() => _camOn = false);
      } else {
        await _scannerController.start();
        if (!mounted) return;
        setState(() => _camOn = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal ubah kamera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseConfig.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginView()),
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
        title: const Text(
          'SDIT UKHUWAH - PIKET',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.lightBlueAccent,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildScanTab(),
          const StudentsView(), // Opsi B: Riwayat scan hari ini
          const GateView(),     // Buka sementara 45 detik (aman)
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.lightBlueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lock_clock_rounded),
            label: 'Gerbang',
          ),
        ],
      ),
    );
  }

  Widget _buildScanTab() {
    final bool ok = _lastResult != null && _lastResult!['ok'] == true;

    return Column(
      children: [
        // ===================== KAMERA =====================
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
                // Preview kamera / offline camera
                Positioned.fill(
                  child: _camOn
                      ? MobileScanner(
                          controller: _scannerController,
                          onDetect: _onDetect,
                        )
                      : const ColoredBox(
                          color: Colors.black,
                          child: Center(
                            child: Text(
                              'Kamera dimatikan\nGunakan input NIS manual',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                ),

                // Header kamera + tombol ON/OFF
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _camOn
                              ? '📷 Kamera ON (Cloud Realtime)'
                              : '📷 Kamera OFF',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _toggleCamera,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _camOn ? Colors.redAccent : Colors.green,
                          minimumSize: const Size(40, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: Text(
                          _camOn ? 'MATIKAN' : 'NYALAKAN',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Overlay proses
                if (_isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'Memproses absensi...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ===================== INPUT MANUAL =====================
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
                    enabled: !_isProcessing,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ketik NIS Manual...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _submitManual(),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _submitManual,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'ABSEN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // ===================== HASIL SCAN =====================
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: _lastResult == null
                ? const Center(
                    child: Text(
                      'Scan Kartu Pelajar atau Ketik NIS\n(Hasil masuk ke tab Riwayat)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ok
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: ok ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          (_lastResult!['nama'] ?? 'Tidak Dikenal').toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Kelas ${_lastResult!['kelas'] ?? '-'} • NIS: ${_lastResult!['nis'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ok ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (_lastResult!['type'] ?? 'GAGAL').toString(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold, // jangan FontWeight.black
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (_lastResult!['message'] ?? '').toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                        if ((_lastResult!['time'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${_lastResult!['time']} WITA',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white54,
                              ),
                            ),
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
