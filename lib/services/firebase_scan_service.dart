import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class FirebaseScanService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  static Future<void> processScan({
    required String qrData,
    required String method,
    required String scannedBy,
    required Function(Map<String, dynamic> result) onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    try {
      DatabaseReference newScanRef = _db.ref('scans').push();

      await newScanRef.set({
        'qr_data': qrData,
        'method': method,
        'scanned_by': scannedBy,
        'status': 'PENDING',
        'created_at': ServerValue.timestamp,
      });

      late StreamSubscription<DatabaseEvent> subscription;

      subscription = newScanRef.onValue.listen((event) {
        if (event.snapshot.value == null) return;

        final Map<dynamic, dynamic> rawData =
            event.snapshot.value as Map<dynamic, dynamic>;

        final String status = rawData['status']?.toString() ?? 'PENDING';

        if (status == 'SUCCESS' || status == 'FAILED') {
          SystemSound.play(SystemSoundType.click);

          final bool isSuccess = (status == 'SUCCESS');

          onSuccess({
            'ok': isSuccess,
            'type': rawData['attendance_type']?.toString() ?? 'GAGAL',
            'nama': rawData['student_nama']?.toString() ?? 'Tidak Dikenal',
            'kelas': rawData['student_kelas']?.toString() ?? '-',
            'nis': rawData['student_nis']?.toString() ?? '-',
            'foto': rawData['student_foto']?.toString() ?? '',
            'message': rawData['message']?.toString() ?? '',
            'time': rawData['time']?.toString() ?? '',
          });

          subscription.cancel();
        }
      });

      Timer(const Duration(seconds: 8), () {
        subscription.cancel();
      });

    } catch (e) {
      onError('Gagal terhubung ke Firebase: $e');
    }
  }
}
