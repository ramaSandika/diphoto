import 'package:flutter/foundation.dart';
import 'google_drive_service.dart';

/// Task item di dalam antrian upload background
class UploadTask {
  final String id;
  final Uint8List photoBytes;
  final String scriptUrl;
  final String folderId;
  final String fileName;
  final DateTime createdAt;

  UploadTask({
    required this.id,
    required this.photoBytes,
    required this.scriptUrl,
    required this.folderId,
    required this.fileName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

/// Service singleton yang mengelola antrian upload ke Google Drive di background.
/// Upload akan tetap berjalan tuntas meskipun user menekan 'SESI BARU'
/// atau ResultController di-reset.
class BackgroundUploadQueue {
  static final BackgroundUploadQueue instance = BackgroundUploadQueue._internal();

  BackgroundUploadQueue._internal();

  final GoogleDriveService _driveService = GoogleDriveService();
  final List<UploadTask> _queue = [];
  bool _isProcessing = false;

  /// Enqueue foto untuk langsung di-upload ke Google Drive.
  /// Berjalan secara fire-and-forget di background tanpa memblokir UI atau state photobooth.
  void enqueue({
    required Uint8List photoBytes,
    required String scriptUrl,
    required String folderId,
    String? fileName,
  }) {
    if (scriptUrl.trim().isEmpty || folderId.trim().isEmpty) {
      debugPrint('[BackgroundUploadQueue] Peringatan: scriptUrl atau folderId kosong. Upload dilewati.');
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final name = fileName ?? 'photobooth_$timestamp.jpg';
    final task = UploadTask(
      id: 'task_$timestamp',
      photoBytes: photoBytes,
      scriptUrl: scriptUrl.trim(),
      folderId: folderId.trim(),
      fileName: name,
    );

    _queue.add(task);
    debugPrint('[BackgroundUploadQueue] Task ditambahkan: ${task.fileName}. Total antrian: ${_queue.length}');
    _processNext();
  }

  void _processNext() async {
    if (_isProcessing || _queue.isEmpty) return;
    _isProcessing = true;

    final task = _queue.removeAt(0);
    debugPrint('[BackgroundUploadQueue] Memulai upload: ${task.fileName}...');

    try {
      final link = await _driveService.uploadViaAppsScript(
        photoBytes: task.photoBytes,
        scriptUrl: task.scriptUrl,
        folderId: task.folderId,
        fileName: task.fileName,
      );
      debugPrint('[BackgroundUploadQueue] Berhasil upload ${task.fileName} ke Google Drive: $link');
    } catch (e) {
      debugPrint('[BackgroundUploadQueue] Gagal upload ${task.fileName}: $e');
    } finally {
      _isProcessing = false;
      if (_queue.isNotEmpty) {
        _processNext();
      }
    }
  }

  /// Jumlah item yang sedang menunggu di antrian
  int get queueLength => _queue.length;

  /// Status apakah sedang mengunggah
  bool get isProcessing => _isProcessing;
}
