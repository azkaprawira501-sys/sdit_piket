import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({super.key});

  @override
  State<StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<StudentsView> {
  final DatabaseReference _ref =
      FirebaseDatabase.instance.ref('attendance_today');

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _listenToday();
  }

  void _listenToday() {
    _ref.onValue.listen((event) {
      final List<Map<String, dynamic>> list = [];

      if (event.snapshot.value != null && event.snapshot.value is Map) {
        final Map<dynamic, dynamic> data =
            event.snapshot.value as Map<dynamic, dynamic>;

        data.forEach((key, value) {
          if (value is Map) {
            final item = Map<String, dynamic>.from(value);
            item['key'] = key.toString();
            list.add(item);
          }
        });

        list.sort((a, b) {
          final ta = a['time']?.toString() ?? '';
          final tb = b['time']?.toString() ?? '';
          return tb.compareTo(ta);
        });
      }

      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    }, onError: (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.trim().isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items.where((s) {
      final nama = s['nama']?.toString().toLowerCase() ?? '';
      final nis = s['nis']?.toString().toLowerCase() ?? '';
      final kelas = s['kelas']?.toString().toLowerCase() ?? '';
      return nama.contains(q) || nis.contains(q) || kelas.contains(q);
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'HADIR':
        return Colors.green;
      case 'TERLAMBAT':
        return Colors.orange;
      case 'PULANG':
        return Colors.lightBlue;
      case 'IZIN':
        return Colors.cyan;
      case 'SAKIT':
        return Colors.purple;
      case 'ALFA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _filtered;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
          child: Row(
            children: [
              const Text(
                'Riwayat Scan Hari Ini',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.lightBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.lightBlueAccent),
                ),
                child: Text(
                  '${data.length} scan',
                  style: const TextStyle(
                    color: Colors.lightBlueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari nama / NIS / kelas...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : data.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada scan hari ini.\nScan QR / ketik NIS di tab Scan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final s = data[index];
                        final nama = s['nama']?.toString() ?? '-';
                        final nis = s['nis']?.toString() ?? '-';
                        final kelas = s['kelas']?.toString() ?? '-';
                        final status = s['status']?.toString() ?? '-';
                        final time = s['time']?.toString() ?? '-';
                        final jamMasuk = s['jam_masuk']?.toString() ?? '-';
                        final jamPulang = s['jam_pulang']?.toString() ?? '-';
                        final method = s['method']?.toString() ?? '-';

                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _statusColor(status).withOpacity(0.2),
                              child: Text(
                                kelas,
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              nama,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            subtitle: Text(
                              'NIS: $nis • $method\nMasuk: $jamMasuk • Pulang: $jamPulang',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  time,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
