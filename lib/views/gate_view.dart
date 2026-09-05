import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../config/firebase_config.dart';

class GateView extends StatefulWidget {
  const GateView({super.key});

  @override
  State<GateView> createState() => _GateViewState();
}

class _GateViewState extends State<GateView> {
  final _gateRef = FirebaseDatabase.instance.ref('gate');
  final _cmdRef = FirebaseDatabase.instance.ref('gate_commands');

  String _status = 'terkunci';
  String _masterMode = 'schedule'; // schedule | force_open | force_locked
  int _tempOpenUntil = 0;
  String _tempReason = '';
  bool _loading = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _listen();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _listen() {
    _gateRef.onValue.listen((event) {
      final v = event.snapshot.value;
      if (v is Map) {
        setState(() {
          _status = v['status']?.toString() ?? 'terkunci';
          _masterMode = v['master_mode']?.toString() ?? 'schedule';
          _tempOpenUntil = int.tryParse('${v['temp_open_until'] ?? 0}') ?? 0;
          _tempReason = v['temp_open_reason']?.toString() ?? '';
        });
      }
    });
  }

  bool get _isTempOpen {
    final now = DateTime.now().millisecondsSinceEpoch;
    return _tempOpenUntil > now;
  }

  int get _tempRemainSec {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_tempOpenUntil <= now) return 0;
    return ((_tempOpenUntil - now) / 1000).ceil();
  }

  bool get _canRequestTempOpen {
    // App hanya boleh minta temp open jika BUKAN force_locked admin
    return _masterMode != 'force_locked';
  }

  Future<void> _requestTempOpen() async {
    if (!_canRequestTempOpen) {
      _toast('Gerbang dikunci manual Admin. Tidak bisa dibuka dari app.', false);
      return;
    }

    setState(() => _loading = true);
    final user = await FirebaseConfig.getUser();
    final cmd = _cmdRef.push();

    await cmd.set({
      'action': 'temp_open',
      'by': user['name'] ?? 'Guru Piket',
      'reason': 'Pulang awal (sakit/izin)',
      'seconds': 45,
      'status': 'PENDING',
      'created_at': ServerValue.timestamp,
    });

    setState(() => _loading = false);
    _toast('Meminta buka sementara 45 detik...', true);
  }

  void _toast(String msg, bool ok) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: ok ? Colors.green : Colors.red),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final open = _status == 'terbuka' || _isTempOpen;

    String modeText;
    switch (_masterMode) {
      case 'force_open':
        modeText = 'Mode Admin: BUKA MANUAL';
        break;
      case 'force_locked':
        modeText = 'Mode Admin: KUNCI MANUAL';
        break;
      default:
        modeText = 'Mode: SESUAI JADWAL';
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            open ? Icons.lock_open_rounded : Icons.lock_rounded,
            size: 72,
            color: open ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(height: 10),
          Text(
            open ? 'GERBANG TERBUKA' : 'GERBANG TERKUNCI',
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(modeText, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          if (_isTempOpen) ...[
            const SizedBox(height: 8),
            Text(
              'Buka sementara: $_tempRemainSec dtk\n$_tempReason',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_loading || !_canRequestTempOpen || _isTempOpen) ? null : _requestTempOpen,
              icon: const Icon(Icons.timer),
              label: Text(_loading ? 'Memproses...' : 'Buka Sementara 45 Detik (Pulang Awal)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'App Piket tidak bisa buka/kunci permanen.\nHanya Admin di sistem master yang berwenang.\nTombol di atas hanya untuk darurat pulang awal.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
