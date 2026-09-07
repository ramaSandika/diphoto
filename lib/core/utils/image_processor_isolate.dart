import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';
import 'template_slot_detector.dart';

/// Payload data yang dikirim ke Background Isolate
class CompositePayload {
  /// List foto (maks 2) sesuai jumlah slot terdeteksi
  final List<Uint8List> photos;
  final Uint8List templatePngBytes;

  /// Slot yang terdeteksi dari template. Jika null pakai posisi default hardcoded.
  final List<PhotoSlot>? detectedSlots;

  /// Ukuran template asli (untuk canvas size yang tepat)
  final int templateWidth;
  final int templateHeight;

  const CompositePayload({
    required this.photos,
    required this.templatePngBytes,
    this.detectedSlots,
    this.templateWidth = 1200,
    this.templateHeight = 1800,
  });
}

/// Pipeline Pemrosesan Gambar Berjalan di Background Isolate menggunakan compute()
class ImageProcessorIsolate {
  /// Entry point publik
  static Future<Uint8List> processBoothImages(CompositePayload payload) async {
    if (kIsWeb) {
      return _compositeTask(payload);
    }
    return await compute(_compositeTask, payload);
  }

  // TASK UTAMA DI ISOLATE (Jank-Free)
  static Uint8List _compositeTask(CompositePayload payload) {
    // 1. Decode Template PNG Transparan
    final img.Image? rawTemplate = img.decodeImage(payload.templatePngBytes);
    if (rawTemplate == null) {
      throw Exception('Gagal melakukan decoding template PNG');
    }

    // 2. Tentukan ukuran canvas dari template asli
    final int canvasW = payload.templateWidth;
    final int canvasH = payload.templateHeight;

    // 3. Inisialisasi Canvas dengan latar putih
    final img.Image canvas = img.Image(
      width: canvasW,
      height: canvasH,
      numChannels: 4,
    );
    img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));

    // 4. Tentukan slot posisi foto
    final List<PhotoSlot> slots = _resolveSlots(
      payload.detectedSlots,
      canvasW,
      canvasH,
    );

    // 5. Composite setiap foto ke slot yang sesuai
    final int count = payload.photos.length.clamp(0, slots.length);
    for (int i = 0; i < count; i++) {
      final img.Image? rawPhoto = img.decodeImage(payload.photos[i]);
      if (rawPhoto == null) continue;

      final PhotoSlot slot = slots[i];

      final img.Image croppedPhoto = _smartCenterCrop(
        rawPhoto,
        slot.width,
        slot.height,
      );

      img.compositeImage(
        canvas,
        croppedPhoto,
        dstX: slot.x,
        dstY: slot.y,
        blend: img.BlendMode.direct,
      );
    }

    // 6. Resize template ke ukuran canvas jika berbeda
    img.Image preparedTemplate = rawTemplate;
    if (rawTemplate.width != canvasW || rawTemplate.height != canvasH) {
      preparedTemplate = img.copyResize(
        rawTemplate,
        width: canvasW,
        height: canvasH,
        interpolation: img.Interpolation.linear,
      );
    }

    // 7. Overlay Template PNG di paling depan (alpha blending)
    img.compositeImage(
      canvas,
      preparedTemplate,
      dstX: 0,
      dstY: 0,
      blend: img.BlendMode.alpha,
    );

    // 8. Encode ke JPEG
    final Uint8List finalJpgBytes = Uint8List.fromList(
      img.encodeJpg(canvas, quality: AppConstants.jpegQuality),
    );

    return finalJpgBytes;
  }

  // RESOLVE SLOTS: pakai detectedSlots atau fallback default
  static List<PhotoSlot> _resolveSlots(
    List<PhotoSlot>? detected,
    int canvasW,
    int canvasH,
  ) {
    if (detected != null && detected.isNotEmpty) {
      return detected;
    }

    // Fallback: 2 slot atas-bawah proporsional
    final int padX = (canvasW * 0.083).round();
    final int padYTop = (canvasH * 0.05).round();
    final int photoW = canvasW - (padX * 2);
    final int photoH = (canvasH * 0.39).round();
    final int gap = (canvasH * 0.055).round();
    final int slot2Y = padYTop + photoH + gap;

    return [
      PhotoSlot(x: padX, y: padYTop, width: photoW, height: photoH),
      PhotoSlot(x: padX, y: slot2Y, width: photoW, height: photoH),
    ];
  }

  // ALGORITMA SMART CENTER-CROP CEPAT (Crop langsung di resolusi asli lalu resize sekali)
  static img.Image _smartCenterCrop(
    img.Image source,
    int targetWidth,
    int targetHeight,
  ) {
    final double srcAspect = source.width / source.height;
    final double targetAspect = targetWidth / targetHeight;

    int cropX = 0;
    int cropY = 0;
    int cropW = source.width;
    int cropH = source.height;

    // Crop dulu di ukuran asli sebelum resize (jauh lebih hemat memori & CPU)
    if (srcAspect > targetAspect) {
      // Source lebih lebar -> potong sisi kiri & kanan
      cropW = (source.height * targetAspect).round().clamp(1, source.width);
      cropX = ((source.width - cropW) / 2).round().clamp(0, source.width - cropW);
    } else {
      // Source lebih tinggi -> potong sisi atas & bawah
      cropH = (source.width / targetAspect).round().clamp(1, source.height);
      cropY = ((source.height - cropH) / 2).round().clamp(0, source.height - cropH);
    }

    final img.Image cropped = img.copyCrop(
      source,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    // Resize hanya bagian yang sudah dicrop langsung ke target size
    return img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );
  }
}
