
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class FirebaseScanService {
  static final FirebaseDatabase _db = FirebaseDatabase.instance;

  /// Tembak data scan ke Firebase RTDB & Dengarkan Balasan Real-Time
  static Future<void> processScan({
    required String qrData,
    required String method,
    required String scannedBy,
    required Function(Map<String, dynamic> result) onSuccess,
    required Function(String errorMessage) onError,
  }) async {
    try {
      // 1. Buat Node Baru di bawah 'scans' dengan Status PENDING
      DatabaseReference newScanRef = _db.ref('scans').push();

      await newScanRef.set({
        'qr_data': qrData,
        'method': method,
        'scanned_by': scannedBy,
        'status': 'PENDING',
        'created_at': ServerValue.timestamp,
      });

      // 2. LISTEN REAL-TIME PERUBAHAN DATA PADA NODE DIBUAT (BALASAN LARAVEL)
      late StreamSubscription<DatabaseEvent> subscription;

      subscription = newScanRef.onValue.listen((event) {
        if (event.snapshot.value == null) return;

        final Map<dynamic, dynamic> rawData =
            event.snapshot.value as Map<dynamic, dynamic>;

        final String status = rawData['status']?.toString() ?? 'PENDING';

        // 3. Jika Status Berubah menjadi SUCCESS atau FAILED dari Laravel
        if (status == 'SUCCESS' || status == 'FAILED') {
          // Play Sound Click / Beep
          SystemSound.play(SystemSoundType.click);

          final bool isSuccess = (status == 'SUCCESS');

          // Kirim Hasil ke UI Flutter Popup
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

          // Unsubscribe listener setelah mendapat balasan
          subscription.cancel();
        }
      });

      // Timeout Pengaman: Batalkan jika tidak ada respon dalam 8 detik
      Timer(const Duration(seconds: 8), () {
        subscription.cancel();
      });

    } catch (e) {
      onError('Gagal terhubung ke Firebase: $e');
    }
  }
}
