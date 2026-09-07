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

        final templateW = setupConfig.templateWidth > 0 ? setupConfig.templateWidth.toDouble() : 1200.0;
        final templateH = setupConfig.templateHeight > 0 ? setupConfig.templateHeight.toDouble() : 1800.0;
        final aspectRatio = templateW / templateH;

        return OrientationBuilder(
          builder: (context, orientation) {
            final isPortrait = orientation == Orientation.portrait;

            if (isPortrait) {
              // ─── TAMPILAN PORTRAIT 1 SLIDE FULL (PAS DI UKURAN DEVICE, NO SCROLL) ───
              return LayoutBuilder(
                builder: (context, constraints) {
                  final totalH = constraints.maxHeight;
                  // Alokasikan tinggi: ~62-65% untuk foto, sisanya untuk barcode & tombol
                  final photoMaxH = (totalH * 0.62).clamp(260.0, 680.0);

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      children: [
                        // 1. Pratinjau Foto Hasil Komposit Full di Bagian Atas
                        Expanded(
                          child: Center(
                            child: Container(
                              constraints: BoxConstraints(maxHeight: photoMaxH),
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
                                  aspectRatio: aspectRatio,
                                  child: Image.memory(
                                    state.compositeImageBytes!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // 2. Panel Bawah: Barcode di Kiri & 2 Tombol di Kanan (Horizontal agar ringkas & 1 slide pas)
                        Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF161224),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Sisi Kiri Bawah: Barcode / QR Code
                              _buildQrWidget(
                                state,
                                qrData,
                                qrSize: 96,
                                showLabel: false,
                              ),

                              const SizedBox(width: 16),

                              // Sisi Kanan Bawah: Teks & 2 Tombol Aksi
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Scan QR Folder Drive',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Tombol Aksi 1: SESI BARU
                                    SizedBox(
                                      height: 44,
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
                                        icon: const Icon(Icons.replay_rounded, size: 18),
                                        label: const Text(
                                          'SESI BARU',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFFF4081),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 3,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    // Tombol Aksi 2: Menu Setup
                                    SizedBox(
                                      height: 38,
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
                                        icon: const Icon(Icons.settings, size: 16, color: Colors.white),
                                        label: const Text(
                                          'Menu Setup',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2A243D),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: const BorderSide(color: Color(0xFF7C4DFF), width: 1.2),
                                          ),
                                          elevation: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }

            // ─── TAMPILAN LANDSCAPE: KIRI FOTO, KANAN BARCODE + 2 OPSI ────────
            return Row(
              children: [
                // Sisi Kiri: Foto Hasil Komposit
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
                            aspectRatio: aspectRatio,
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

                // Sisi Kanan: Barcode & 2 Tombol
                Expanded(
                  flex: 4,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
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
                              _buildQrWidget(state, qrData, qrSize: qrSize),

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

                              // Tombol Menu Setup
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
          },
        );
    }
  }

  Widget _buildQrWidget(
    ResultState state,
    String? qrData, {
    required double qrSize,
    bool showLabel = true,
  }) {
    if (qrData != null) {
      // TAMPILKAN BARCODE / QR CODE LANGSUNG (INSTANT 0ms, BERSIH TANPA OVERLAY)
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
          if (showLabel) ...[
            const SizedBox(height: 8),
            const Text(
              'Scan QR untuk buka Folder Foto di Drive',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      );
    } else if (state.isUploading) {
      return Container(
        height: qrSize + (showLabel ? 20 : 0),
        width: qrSize + (showLabel ? 20 : 0),
        padding: const EdgeInsets.all(12),
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
            SizedBox(height: 8),
            Text(
              'Mengunggah...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner, size: showLabel ? 48 : 36, color: Colors.white30),
            if (showLabel) ...[
              const SizedBox(height: 6),
              const Text(
                'Link Google Drive belum diisi di Setup',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ],
        ),
      );
    }
  }
}
