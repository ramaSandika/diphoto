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

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image': base64Image,
            'fileName': fileName,
            'folderId': folderId.trim(),
          }),
        )
        .timeout(const Duration(seconds: 35));

    if (response.statusCode == 200 || response.statusCode == 302) {
      final Map<String, dynamic> body = jsonDecode(response.body);
      if (body['success'] == true && body['link'] != null) {
        return body['link'] as String;
      } else {
        throw Exception(body['error'] ?? 'Gagal mengunggah foto ke Google Drive');
      }
    } else {
      throw Exception('Gagal menghubungi Web App (Status: ${response.statusCode})');
    }
  }
}
