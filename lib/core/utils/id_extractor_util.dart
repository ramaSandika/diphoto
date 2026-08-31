class IdExtractorUtil {
  /// Ekstraksi Google Drive Folder ID dari tautan lengkap atau ID mentah.
  /// Mendukung format:
  /// - https://drive.google.com/drive/folders/1A2B3C4D5E...
  /// - https://drive.google.com/drive/u/0/folders/1A2B3C4D5E...
  /// - https://drive.google.com/drive/u/1/folders/1A2B3C4D5E?usp=sharing
  /// - 1A2B3C4D5E... (ID mentah)
  static String? extractFolderId(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 1. Coba ekstrak dari URL Google Drive (prioritas: path /folders/<id>)
    final urlRegex = RegExp(r'/folders/([a-zA-Z0-9_-]{10,})');
    final urlMatch = urlRegex.firstMatch(trimmed);
    if (urlMatch != null) {
      return urlMatch.group(1);
    }

    // 2. Fallback: jika input adalah ID mentah (bukan URL), ambil langsung
    final rawIdRegex = RegExp(r'^[a-zA-Z0-9_-]{15,}$');
    if (rawIdRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    return null;
  }
}
