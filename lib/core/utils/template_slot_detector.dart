import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Representasi satu slot foto yang terdeteksi dari area transparan template
class PhotoSlot {
  final int x;
  final int y;
  final int width;
  final int height;

  const PhotoSlot({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  @override
  String toString() => 'PhotoSlot(x:$x, y:$y, w:$width, h:$height)';
}

/// Payload untuk isolate deteksi slot
class _DetectPayload {
  final Uint8List templateBytes;
  const _DetectPayload(this.templateBytes);
}

/// Detektor otomatis slot foto transparan dalam template PNG.
class TemplateSlotDetector {
  static Future<List<PhotoSlot>> detect(Uint8List templateBytes) async {
    if (kIsWeb) {
      return _detectTask(_DetectPayload(templateBytes));
    }
    return await compute(_detectTask, _DetectPayload(templateBytes));
  }

  static List<PhotoSlot> _detectTask(_DetectPayload payload) {
    final img.Image? rawTemplate = img.decodeImage(payload.templateBytes);
    if (rawTemplate == null) return [];

    final int origW = rawTemplate.width;
    final int origH = rawTemplate.height;

    const int analysisMaxW = 400;
    final double scale = origW > analysisMaxW ? analysisMaxW / origW : 1.0;
    final int anaW = (origW * scale).round().clamp(1, origW);
    final int anaH = (origH * scale).round().clamp(1, origH);

    final img.Image small = img.copyResize(
      rawTemplate,
      width: anaW,
      height: anaH,
      interpolation: img.Interpolation.linear,
    );

    final List<List<bool>> transparent = List.generate(
      anaH,
      (y) => List.generate(anaW, (x) {
        final pixel = small.getPixel(x, y);
        final double alpha = pixel.a.toDouble();
        if (alpha < 128) return true;

        // Fallback: Jika pengguna mengunggah template JPG atau PNG dengan kotak putih solid (R>245, G>245, B>245)
        final double r = pixel.r.toDouble();
        final double g = pixel.g.toDouble();
        final double b = pixel.b.toDouble();
        return r > 245 && g > 245 && b > 245;
      }),
    );

    final List<List<bool>> visited = List.generate(anaH, (_) => List.filled(anaW, false));
    final List<PhotoSlot> slots = [];
    final int minSlotArea = ((anaW * anaH) * 0.03).round();

    for (int startY = 0; startY < anaH; startY++) {
      for (int startX = 0; startX < anaW; startX++) {
        if (!transparent[startY][startX] || visited[startY][startX]) continue;

        int minX = startX, maxX = startX;
        int minY = startY, maxY = startY;
        int pixelCount = 0;

        final List<(int, int)> queue = [(startX, startY)];
        visited[startY][startX] = true;

        while (queue.isNotEmpty) {
          final (int cx, int cy) = queue.removeLast();
          pixelCount++;
          if (cx < minX) minX = cx;
          if (cx > maxX) maxX = cx;
          if (cy < minY) minY = cy;
          if (cy > maxY) maxY = cy;

          for (final (int nx, int ny) in [
            (cx + 1, cy), (cx - 1, cy),
            (cx, cy + 1), (cx, cy - 1),
          ]) {
            if (nx < 0 || nx >= anaW || ny < 0 || ny >= anaH) continue;
            if (visited[ny][nx] || !transparent[ny][nx]) continue;
            visited[ny][nx] = true;
            queue.add((nx, ny));
          }
        }

        if (pixelCount < minSlotArea) continue;

        final int origX = (minX / scale).round().clamp(0, origW - 1);
        final int origY = (minY / scale).round().clamp(0, origH - 1);
        final int origSlotW = ((maxX - minX + 1) / scale).round().clamp(1, origW - origX);
        final int origSlotH = ((maxY - minY + 1) / scale).round().clamp(1, origH - origY);

        slots.add(PhotoSlot(
          x: origX,
          y: origY,
          width: origSlotW,
          height: origSlotH,
        ));
      }
    }

    slots.sort((a, b) {
      final int yDiff = (a.y - b.y).abs();
      if (yDiff > origH * 0.10) return a.y.compareTo(b.y);
      return a.x.compareTo(b.x);
    });

    return slots;
  }
}
