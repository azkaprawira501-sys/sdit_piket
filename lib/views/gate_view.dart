
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GateView extends StatefulWidget {
  const GateView({super.key});

  @override
  State<GateView> createState() => _GateViewState();
}

class _GateViewState extends State<GateView> {
  String _gateStatus = 'terbuka';
  bool _loading = false;
  int _totalHadir = 0;
  int _totalSiswa = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final res = await ApiService.getStats();
    if (res['success'] == true) {
      setState(() {
        _gateStatus = res['gate_status']?.toString() ?? 'terbuka';
        _totalHadir = res['total_hadir'] ?? 0;
        _totalSiswa = res['total_siswa'] ?? 0;
      });
    }
  }

  Future<void> _toggleGate() async {
    setState(() => _loading = true);
    final res = await ApiService.toggleGate();
    setState(() {
      _loading = false;
      if (res['success'] == true) {
        _gateStatus = res['gate_status']?.toString() ?? _gateStatus;
      }
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message']?.toString() ?? 'Selesai'),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = _gateStatus == 'terkunci';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              locked ? Icons.lock : Icons.lock_open,
              size: 80,
              color: locked ? Colors.redAccent : Colors.greenAccent,
            ),
            const SizedBox(height: 12),
            Text(
              locked ? 'GERBANG TERKUNCI' : 'GERBANG TERBUKA',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Hadir hari ini: $_totalHadir / $_totalSiswa',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _toggleGate,
              style: ElevatedButton.styleFrom(
                backgroundColor: locked ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                locked ? 'BUKA GERBANG' : 'KUNCI GERBANG',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadStats,
              child: const Text('Refresh Status', style: TextStyle(color: Colors.lightBlueAccent)),
            ),
          ],
        ),
      ),
    );
  }
}
