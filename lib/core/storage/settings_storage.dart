import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan dan membaca konfigurasi setup secara permanen.
/// Mendukung Android, iOS, dan Windows.
class SettingsStorage {
  static const _keyScriptUrl   = 'cfg_script_url';
  static const _keyFolderId    = 'cfg_folder_id';
  static const _keyTemplateB64 = 'cfg_template_b64';
  static const _keyTplWidth    = 'cfg_tpl_w';
  static const _keyTplHeight   = 'cfg_tpl_h';

  // ── READ ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'scriptUrl'     : prefs.getString(_keyScriptUrl),
      'folderId'      : prefs.getString(_keyFolderId),
      'templateB64'   : prefs.getString(_keyTemplateB64),
      'templateWidth' : prefs.getInt(_keyTplWidth) ?? 1200,
      'templateHeight': prefs.getInt(_keyTplHeight) ?? 1800,
    };
  }

  /// Decode bytes template dari base64 yang tersimpan.
  /// Mengembalikan null jika tidak ada data tersimpan.
  static Uint8List? decodeTemplateBytes(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  // ── WRITE ────────────────────────────────────────────────────────────────

  static Future<void> saveScriptUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url == null || url.isEmpty) {
      await prefs.remove(_keyScriptUrl);
    } else {
      await prefs.setString(_keyScriptUrl, url.trim());
    }
  }

  static Future<void> saveFolderId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_keyFolderId);
    } else {
      await prefs.setString(_keyFolderId, id.trim());
    }
  }

  static Future<void> saveTemplate(Uint8List bytes, int width, int height) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTemplateB64, base64Encode(bytes));
    await prefs.setInt(_keyTplWidth, width);
    await prefs.setInt(_keyTplHeight, height);
  }

  static Future<void> clearTemplate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyTemplateB64);
    await prefs.remove(_keyTplWidth);
    await prefs.remove(_keyTplHeight);
  }
}
