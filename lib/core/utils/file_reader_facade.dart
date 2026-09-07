import 'dart:typed_data';
import 'file_reader_io.dart' if (dart.library.js_interop) 'file_reader_web.dart' as impl;

/// Membaca byte file dengan aman baik di Web (browser) maupun Native (Windows, Android, iOS)
Future<Uint8List?> readFileBytesSafe({Uint8List? directBytes, String? path}) {
  return impl.readFileBytes(directBytes: directBytes, path: path);
}
