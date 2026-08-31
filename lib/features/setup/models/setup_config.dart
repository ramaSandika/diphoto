import 'dart:typed_data';
import 'package:camera/camera.dart';
import '../../../core/utils/template_slot_detector.dart';

class SetupConfig {
  final String? scriptUrl;
  final String? folderId;
  final Uint8List? templatePngBytes;
  final CameraDescription? selectedCamera;

  /// Slot foto terdeteksi otomatis dari template PNG (area transparan)
  final List<PhotoSlot>? detectedSlots;

  /// Dimensi asli template (untuk canvas size yang tepat)
  final int templateWidth;
  final int templateHeight;

  const SetupConfig({
    this.scriptUrl,
    this.folderId,
    this.templatePngBytes,
    this.selectedCamera,
    this.detectedSlots,
    this.templateWidth = 1200,
    this.templateHeight = 1800,
  });

  bool get isReady => templatePngBytes != null;

  /// Jumlah foto yang perlu diambil — sesuai jumlah slot (maks 2)
  int get photoCount {
    final count = detectedSlots?.length ?? 2;
    return count.clamp(1, 2);
  }

  SetupConfig copyWith({
    String? scriptUrl,
    String? folderId,
    Uint8List? templatePngBytes,
    CameraDescription? selectedCamera,
    List<PhotoSlot>? detectedSlots,
    int? templateWidth,
    int? templateHeight,
  }) {
    return SetupConfig(
      scriptUrl: scriptUrl ?? this.scriptUrl,
      folderId: folderId ?? this.folderId,
      templatePngBytes: templatePngBytes ?? this.templatePngBytes,
      selectedCamera: selectedCamera ?? this.selectedCamera,
      detectedSlots: detectedSlots ?? this.detectedSlots,
      templateWidth: templateWidth ?? this.templateWidth,
      templateHeight: templateHeight ?? this.templateHeight,
    );
  }
}

