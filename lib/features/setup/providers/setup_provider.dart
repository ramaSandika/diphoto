import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../../../core/utils/id_extractor_util.dart';
import '../../../core/utils/template_slot_detector.dart';
import '../models/setup_config.dart';

class SetupNotifier extends StateNotifier<SetupConfig> {
  SetupNotifier() : super(const SetupConfig());

  void setScriptUrl(String url) {
    state = state.copyWith(scriptUrl: url.trim());
  }

  void setGoogleDriveUrl(String url) {
    final folderId = IdExtractorUtil.extractFolderId(url);
    state = state.copyWith(folderId: folderId);
  }

  /// Set template dan otomatis deteksi slot transparan di background isolate
  Future<void> setTemplateBytes(Uint8List bytes) async {
    // Simpan bytes dulu agar UI tidak freeze
    state = state.copyWith(templatePngBytes: bytes, detectedSlots: null);

    try {
      // Deteksi dimensi template
      final decoded = img.decodePng(bytes);
      final int tplW = decoded?.width ?? 1200;
      final int tplH = decoded?.height ?? 1800;

      // Deteksi slot transparan di background isolate (non-blocking)
      final List<PhotoSlot> slots = await TemplateSlotDetector.detect(bytes);

      if (mounted) {
        state = state.copyWith(
          templateWidth: tplW,
          templateHeight: tplH,
          detectedSlots: slots.isEmpty ? null : slots,
        );
      }
    } catch (_) {
      // Deteksi gagal → fallback ke posisi default, tidak masalah
    }
  }

  void setSelectedCamera(CameraDescription? camera) {
    state = state.copyWith(selectedCamera: camera);
  }

  void resetTemplate() {
    state = SetupConfig(
      scriptUrl: state.scriptUrl,
      folderId: state.folderId,
      templatePngBytes: null,
      selectedCamera: state.selectedCamera,
    );
  }
}

final setupProvider = StateNotifierProvider<SetupNotifier, SetupConfig>((ref) {
  return SetupNotifier();
});

