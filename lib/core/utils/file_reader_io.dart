import 'dart:io';
import 'dart:typed_data';

/// Abstraksi pembacaan file lintas platform (Native & Web)
Future<Uint8List?> readFileBytes({Uint8List? directBytes, String? path}) async {
  if (directBytes != null) return directBytes;
  if (path != null) {
    return await File(path).readAsBytes();
  }
  return null;
}
