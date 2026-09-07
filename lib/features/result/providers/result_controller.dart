import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/google_drive_service.dart';
import '../../../core/utils/image_processor_isolate.dart';
import '../../../core/utils/template_slot_detector.dart';
import '../models/result_state.dart';

class ResultController extends StateNotifier<ResultState> {
  final GoogleDriveService _driveService;

  ResultController(this._driveService) : super(const ResultState());

  /// Menjalankan Isolate Image Processor dan langsung perlihatkan hasil gabungan foto & template
  Future<void> processAndUpload({
    required List<Uint8List> photos,
    required Uint8List template,
    List<PhotoSlot>? detectedSlots,
    int templateWidth = 1200,
    int templateHeight = 1800,
    String? scriptUrl,
    String? folderId,
  }) async {
    try {
      // 1. Status: Isolate Processing (Menggabungkan Foto + Template PNG)
      state = state.copyWith(status: ResultStatus.processing);

      final payload = CompositePayload(
        photos: photos,
        templatePngBytes: template,
        detectedSlots: detectedSlots,
        templateWidth: templateWidth,
        templateHeight: templateHeight,
      );

      // Eksekusi compute() di background Isolate (Jank-Free)
      final Uint8List compositeBytes = await ImageProcessorIsolate.processBoothImages(payload);

      // 2. Langsung tampilkan hasil komposit (Instant Display)
      // Barcode selalu merujuk ke link FOLDER Google Drive agar tamu bisa melihat/mengunduh semua foto dalam folder
      final String? folderLink = (folderId != null && folderId.isNotEmpty)
          ? 'https://drive.google.com/drive/folders/$folderId'
          : null;

      state = state.copyWith(
        status: ResultStatus.success,
        compositeImageBytes: compositeBytes,
        driveViewLink: folderLink,
        isUploading: (scriptUrl != null && scriptUrl.isNotEmpty && folderId != null && folderId.isNotEmpty),
      );

      // 3. Upload ke Google Drive via Google Apps Script Web App jika Script URL & Folder ID tersedia
      if (scriptUrl != null && scriptUrl.isNotEmpty && folderId != null && folderId.isNotEmpty) {
        try {
          final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
          final String fileName = 'photobooth_$timestamp.jpg';

          await _driveService.uploadViaAppsScript(
            photoBytes: compositeBytes,
            scriptUrl: scriptUrl,
            folderId: folderId,
            fileName: fileName,
          );

          // Upload berhasil: barcode tetap mengarah ke FOLDER Google Drive
          state = state.copyWith(
            driveViewLink: folderLink,
            isUploading: false,
            uploadError: null,
          );
        } catch (e) {
          // Tetap gunakan link folder Google Drive
          state = state.copyWith(
            driveViewLink: folderLink,
            isUploading: false,
            uploadError: e.toString(),
          );
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: ResultStatus.error,
        errorMessage: 'Gagal memproses gambar: $e',
      );
    }
  }

  void reset() {
    state = const ResultState();
  }
}

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

final resultProvider = StateNotifierProvider<ResultController, ResultState>((ref) {
  final driveService = ref.read(googleDriveServiceProvider);
  return ResultController(driveService);
});
