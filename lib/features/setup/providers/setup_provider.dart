import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import '../../../core/storage/settings_storage.dart';
import '../../../core/utils/id_extractor_util.dart';
import '../../../core/utils/image_processor_isolate.dart';
import '../../../core/utils/template_slot_detector.dart';
import '../models/setup_config.dart';

class SetupNotifier extends StateNotifier<SetupConfig> {
  SetupNotifier() : super(const SetupConfig()) {
    _loadSavedSettings();
  }

  // ── LOAD SAAT STARTUP ───────────────────────────────────────────────────

  Future<void> _loadSavedSettings() async {
    final saved = await SettingsStorage.loadAll();

    final String? scriptUrl   = saved['scriptUrl'] as String?;
    final String? folderId    = saved['folderId'] as String?;
    final String? templateB64 = saved['templateB64'] as String?;
    final int     tplW        = saved['templateWidth'] as int;
    final int     tplH        = saved['templateHeight'] as int;

    final Uint8List? templateBytes =
        SettingsStorage.decodeTemplateBytes(templateB64);

    if (mounted) {
      state = state.copyWith(
        scriptUrl:      scriptUrl,
        folderId:       folderId,
        templatePngBytes: templateBytes,
        templateWidth:  tplW,
        templateHeight: tplH,
      );
    }

    // Deteksi ulang slot dari template yang tersimpan (non-blocking) dan pre-cache template
    if (templateBytes != null) {
      _detectSlots(templateBytes);
      ImageProcessorIsolate.cacheTemplate(templateBytes, tplW, tplH);
    }
  }

  Future<void> _detectSlots(Uint8List bytes) async {
    try {
      final List<PhotoSlot> slots = await TemplateSlotDetector.detect(bytes);
      if (mounted && slots.isNotEmpty) {
        state = state.copyWith(detectedSlots: slots);
      }
    } catch (_) {
      // Gagal deteksi slot → fallback default, tidak masalah
    }
  }

  // ── SETTERS (AUTO-SAVE) ─────────────────────────────────────────────────

  void setScriptUrl(String url) {
    state = state.copyWith(scriptUrl: url.trim());
    SettingsStorage.saveScriptUrl(url.trim());
  }

  void setGoogleDriveUrl(String url) {
    final folderId = IdExtractorUtil.extractFolderId(url);
    state = state.copyWith(folderId: folderId);
    SettingsStorage.saveFolderId(folderId);
  }

  /// Set template dan otomatis deteksi slot transparan di background isolate
  Future<void> setTemplateBytes(Uint8List bytes) async {
    // Simpan bytes dulu agar UI tidak freeze
    state = state.copyWith(templatePngBytes: bytes, detectedSlots: null);

    try {
      // Deteksi dimensi template (mendukung PNG, JPG, WebP)
      final decoded = img.decodeImage(bytes);
      final int tplW = decoded?.width ?? 1200;
      final int tplH = decoded?.height ?? 1800;

      // Simpan ke storage permanen di background
      SettingsStorage.saveTemplate(bytes, tplW, tplH);

      // Pre-cache template yang sudah ter-decode dan ter-resize agar saat sesi foto 0ms
      ImageProcessorIsolate.cacheTemplate(bytes, tplW, tplH);

      // Deteksi slot transparan di background isolate (non-blocking)
      final List<PhotoSlot> slots = await TemplateSlotDetector.detect(bytes);

      if (mounted) {
        state = state.copyWith(
          templateWidth:  tplW,
          templateHeight: tplH,
          detectedSlots:  slots.isEmpty ? null : slots,
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
    SettingsStorage.clearTemplate();
    state = SetupConfig(
      scriptUrl: state.scriptUrl,
      folderId:  state.folderId,
      templatePngBytes: null,
      selectedCamera: state.selectedCamera,
    );
  }
}

final setupProvider = StateNotifierProvider<SetupNotifier, SetupConfig>((ref) {
  return SetupNotifier();
});
