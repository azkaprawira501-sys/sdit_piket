import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../config/firebase_config.dart';

class GateView extends StatefulWidget {
  const GateView({super.key});

  @override
  State<GateView> createState() => _GateViewState();
}

class _GateViewState extends State<GateView> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  String _gateStatus = 'terbuka';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _listenGateStatus();
  }

  void _listenGateStatus() {
    _dbRef.child('gate/status').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _gateStatus = event.snapshot.value.toString();
        });
      }
    });
  }

  void _toggleGate() async {
    setState(() => _loading = true);
    final user = await FirebaseConfig.getUser();
    final newStatus = (_gateStatus == 'terkunci') ? 'terbuka' : 'terkunci';

    await _dbRef.child('gate').set({
      'status': newStatus,
      'updated_by': user['name'],
      'updated_at': ServerValue.timestamp,
    });

    setState(() => _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == 'terkunci' ? '🔒 Gerbang DIKUNCI!' : '🔓 Gerbang DIBUKA!'),
        backgroundColor: newStatus == 'terkunci' ? Colors.red : Colors.green,
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
              locked ? Icons.lock_rounded : Icons.lock_open_rounded,
              size: 80,
              color: locked ? Colors.redAccent : Colors.emeraldAccent,
            ),
            const SizedBox(height: 12),
            Text(
              locked ? 'GERBANG TERKUNCI' : 'GERBANG TERBUKA',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _toggleGate,
              style: ElevatedButton.styleFrom(
                backgroundColor: locked ? Colors.emerald : Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                locked ? '🔓 BUKA GERBANG' : '🔒 KUNCI GERBANG',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
