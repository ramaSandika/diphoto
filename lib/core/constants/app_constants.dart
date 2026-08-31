class AppConstants {
  // === DIMENSI UTAMA TEMPLATE / OUTPUT FOTO ===
  // Ukuran kanvas foto strip standar (1200 x 1800 px)
  static const int canvasWidth = 1200;
  static const int canvasHeight = 1800;

  // Dimensi Target Smart Crop Foto 1 & Foto 2 (Landscape 4:3 proporsional)
  // Menyesuaikan slot transparan di template
  static const int photoTargetWidth = 1000;
  static const int photoTargetHeight = 700;

  // Koordinat Posisi Foto di belakang Template (Slot Atas & Slot Bawah)
  // Slot 1 (Atas):
  static const int photo1X = 100;
  static const int photo1Y = 90;

  // Slot 2 (Bawah):
  static const int photo2X = 100;
  static const int photo2Y = 990;

  // Durasi Flash & Jeda Antara Foto
  static const Duration flashDuration = Duration(milliseconds: 100);
  static const Duration intervalBetweenShots = Duration(milliseconds: 1500);

  // Kualitas output JPEG (85% optimal untuk kecepatan proses & upload cepat tanpa kompromi kualitas)
  static const int jpegQuality = 85;
}
