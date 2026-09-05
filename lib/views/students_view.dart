import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/firebase_scan_service.dart';
import '../config/firebase_config.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({super.key});

  @override
  State<StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<StudentsView> {
  List<Map<String, dynamic>> _students = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    try {
      final ref = FirebaseDatabase.instance.ref('students');
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> data = snapshot.value as Map<dynamic, dynamic>;
        final List<Map<String, dynamic>> list = [];
        data.forEach((key, val) {
          if (val is Map) {
            final studentMap = Map<String, dynamic>.from(val);
            String nama = studentMap['nama']?.toString().toLowerCase() ?? '';
            String nis = studentMap['nis']?.toString().toLowerCase() ?? '';
            if (_search.isEmpty || nama.contains(_search.toLowerCase()) || nis.contains(_search.toLowerCase())) {
              list.add(studentMap);
            }
          }
        });
        setState(() {
          _students = list;
          _loading = false;
        });
      } else {
        setState(() {
          _students = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markHadir(String nis, String nama) async {
    final user = await FirebaseConfig.getUser();
    FirebaseScanService.processScan(
      qrData: nis,
      method: 'manual',
      scannedBy: user['name'] ?? 'Guru Piket',
      onSuccess: (res) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$nama: ${res['message'] ?? 'Berhasil'}'),
            backgroundColor: res['ok'] == true ? Colors.green : Colors.red,
          ),
        );
      },
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            onChanged: (v) {
              _search = v;
              _fetchStudents();
            },
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Cari nama / NIS...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
                  ? const Center(child: Text('Data siswa belum tersedia', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final s = _students[index];
                        final String nama = s['nama']?.toString() ?? '-';
                        final String nis = s['nis']?.toString() ?? '-';
                        final String kelas = s['kelas']?.toString() ?? '-';
                        final String status = s['status']?.toString() ?? 'BELUM';

                        return Card(
                          color: const Color(0xFF1E293B),
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            title: Text(
                              nama,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              'Kelas $kelas • NIS: $nis',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                            trailing: status != 'BELUM'
                                ? Chip(
                                    label: Text(status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    backgroundColor: Colors.green.withOpacity(0.35),
                                  )
                                : ElevatedButton(
                                    onPressed: () => _markHadir(nis, nama),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
                                    child: const Text('+ HADIR', style: TextStyle(fontSize: 10, color: Colors.white)),
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
