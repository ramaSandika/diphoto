import 'dart:typed_data';

/// Abstraksi pembacaan file lintas platform (Native & Web)
Future<Uint8List?> readFileBytes({Uint8List? directBytes, String? path}) async {
  return directBytes;
}
