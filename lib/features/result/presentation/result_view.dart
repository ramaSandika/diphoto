import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/result_state.dart';
import '../providers/result_controller.dart';
import '../../booth/providers/booth_controller.dart';
import '../../setup/providers/setup_provider.dart';

class ResultView extends ConsumerWidget {
  final VoidCallback? onNewSession;
  final VoidCallback? onBackToSetup;

  const ResultView({
    super.key,
    this.onNewSession,
    this.onBackToSetup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultState = ref.watch(resultProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B18),
      body: SafeArea(
        child: _buildBody(context, ref, resultState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ResultState state) {
    final setupConfig = ref.watch(setupProvider);

    switch (state.status) {
      case ResultStatus.idle:
        return const SizedBox.shrink();

      case ResultStatus.processing:
      case ResultStatus.uploading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  color: Color(0xFFFF4081),
                  strokeWidth: 5,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Menyiapkan foto...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );

      case ResultStatus.error:
        return Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ?? 'Terjadi kesalahan sistem',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(boothProvider.notifier).resetBoothSession();
                        ref.read(resultProvider.notifier).reset();
                        if (onNewSession != null) {
                          onNewSession!();
                        } else {
                          context.go('/booth');
                        }
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Coba Lagi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4081),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

      case ResultStatus.success:
        final qrData = state.driveViewLink ??
            (setupConfig.folderId != null && setupConfig.folderId!.isNotEmpty
                ? 'https://drive.google.com/drive/folders/${setupConfig.folderId}'
                : null);

        return Row(
          children: [
            // ─── SISI KIRI: Pratinjau Foto Hasil Komposit 1200 x 1800 ───────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 1200 / 1800,
                        child: Image.memory(
                          state.compositeImageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ─── SISI KANAN: Panel QR Code & Tombol Sesi Baru + Menu Setup ──
            Expanded(
              flex: 4,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Hitung tinggi tersedia dan tentukan ukuran QR secara dinamis
                  // Total fixed height: title ~32 + spacing*3 ~58 + 2 buttons ~102 = ~192
                  final availableForQr = constraints.maxHeight - 192;
                  final qrSize = availableForQr.clamp(80.0, 160.0);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Foto Selesai!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // QR Code / Uploading Indicator
                          if (state.isUploading)
                            Container(
                              height: qrSize + 20,
                              width: qrSize + 20,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1A2E),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFF4081).withValues(alpha: 0.3)),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Color(0xFFFF4081),
                                    strokeWidth: 3,
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    'Mengunggah ke Drive...',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            )
                          else if (qrData != null)
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF4081).withValues(alpha: 0.2),
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: qrSize,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Scan QR untuk buka Folder Foto di Drive',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              )
                          else
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1A2E),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.qr_code_scanner, size: 48, color: Colors.white30),
                                  SizedBox(height: 6),
                                  Text(
                                    'Link Google Drive belum diisi di Setup',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white60, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 14),

                          // Tombol Sesi Baru
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref.read(boothProvider.notifier).resetBoothSession();
                                ref.read(resultProvider.notifier).reset();
                                if (onNewSession != null) {
                                  onNewSession!();
                                } else {
                                  context.go('/booth');
                                }
                              },
                              icon: const Icon(Icons.replay_rounded, size: 20),
                              label: const Text(
                                'SESI BARU',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF4081),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Tombol Menu Setup — selalu terlihat penuh
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ref.read(boothProvider.notifier).resetBoothSession();
                                ref.read(resultProvider.notifier).reset();
                                if (onBackToSetup != null) {
                                  onBackToSetup!();
                                } else {
                                  context.go('/');
                                }
                              },
                              icon: const Icon(Icons.settings, size: 18, color: Colors.white),
                              label: const Text(
                                'Menu Setup',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2A243D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
    }
  }
}
