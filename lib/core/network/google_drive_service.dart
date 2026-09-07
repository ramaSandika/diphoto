import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  /// Mengunggah gambar ke Google Drive via Google Apps Script Web App Deployment URL
  /// Tanpa retry loop otomatis agar tidak terjadi duplikasi upload file yang sama
  Future<String> uploadViaAppsScript({
    required Uint8List photoBytes,
    required String scriptUrl,
    required String folderId,
    required String fileName,
  }) async {
    final base64Image = base64Encode(photoBytes);
    final uri = Uri.parse(scriptUrl.trim());

    final payload = jsonEncode({
      'image': base64Image,
      'fileName': fileName,
      'folderId': folderId.trim(),
    });

    // Catatan: Google Apps Script Web App tidak menangani HTTP OPTIONS (CORS preflight).
    // Menggunakan 'text/plain;charset=utf-8' diperlakukan oleh browser sebagai 'Simple Request'
    // sehingga browser langsung mengirimkan POST tanpa OPTIONS preflight.
    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'text/plain;charset=utf-8'},
          body: payload,
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode >= 200 && response.statusCode < 400) {
      try {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['success'] == true && body['link'] != null) {
          return body['link'] as String;
        } else if (body['error'] != null) {
          throw Exception(body['error']);
        }
      } catch (e) {
        if (e is Exception && e.toString().contains('Gagal')) rethrow;
        // Jika response body berupa redirect HTML atau text sukses dari script
        if (response.body.contains('drive.google.com')) {
          final match = RegExp(r'https://drive\.google\.com/[^\s"<>]+').firstMatch(response.body);
          if (match != null) return match.group(0)!;
        }
      }
      // Jika berhasil tapi respons redirect tidak mengembalikan json link
      return 'https://drive.google.com/drive/folders/${folderId.trim()}';
    } else {
      throw Exception('Server merespons dengan status: ${response.statusCode}');
    }
  }
}
