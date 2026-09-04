
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentsView extends StatefulWidget {
  const StudentsView({super.key});

  @override
  State<StudentsView> createState() => _StudentsViewState();
}

class _StudentsViewState extends State<StudentsView> {
  List<dynamic> _students = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() => _loading = true);
    final res = await ApiService.getStudents(search: _search);
    setState(() {
      _students = (res['data'] as List?) ?? [];
      _loading = false;
    });
  }

  Future<void> _markHadir(String nis, String nama) async {
    final res = await ApiService.scan(nis);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nama: ${res['message'] ?? 'Selesai'}'),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
    _fetchStudents();
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
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final s = _students[index] as Map<String, dynamic>;
                    final status = s['status']?.toString() ?? 'BELUM';
                    return Card(
                      color: const Color(0xFF1E293B),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        title: Text(
                          s['nama']?.toString() ?? '-',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Kelas ${s['kelas']} • NIS: ${s['nis']}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        trailing: status != 'BELUM'
                            ? Chip(
                                label: Text(status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                backgroundColor: Colors.green.withOpacity(0.35),
                              )
                            : ElevatedButton(
                                onPressed: () => _markHadir(
                                  s['nis']?.toString() ?? '',
                                  s['nama']?.toString() ?? '',
                                ),
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
