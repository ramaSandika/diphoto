import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../setup/providers/setup_provider.dart';
import '../models/booth_state.dart';
import '../providers/booth_controller.dart';
import '../../result/providers/result_controller.dart';

class BoothView extends ConsumerWidget {
  const BoothView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boothState = ref.watch(boothProvider);
    final boothCtrl = ref.read(boothProvider.notifier);
    final setupConfig = ref.watch(setupProvider);
    final cameraController = boothCtrl.cameraController;

    if (boothState.errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0B18),
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 550),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1A2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off, color: Colors.redAccent, size: 64),
                const SizedBox(height: 18),
                const Text(
                  'Kamera Tidak Dapat Diakses',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  boothState.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Buka Menu Setup & Ganti Kamera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4081),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0B18),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFFFF4081), strokeWidth: 4),
              SizedBox(height: 20),
              Text(
                'Menghubungkan Sensor Kamera...',
                style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 1),
              ),
            ],
          ),
        ),
      );
    }

    // Hanya cermin jika kamera depan
    final isFrontCamera = setupConfig.selectedCamera?.lensDirection == CameraLensDirection.front;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Pratinjau Kamera Layar Penuh
          Center(
            child: Transform.scale(
              scaleX: isFrontCamera ? -1.0 : 1.0,
              child: AspectRatio(
                aspectRatio: cameraController.value.aspectRatio,
                child: CameraPreview(cameraController),
              ),
            ),
          ),

          // 2. Tombol Kembali ke Setup (Pojok Kiri Atas)
          if (boothState.step == BoothStep.idle)
            Positioned(
              top: 24,
              left: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Kembali ke Setup',
                  onPressed: () => context.go('/'),
                ),
              ),
            ),

          // 3. Status Progress Jepretan (Foto X dari Y)
          if (boothState.step != BoothStep.idle && boothState.step != BoothStep.completed)
            Positioned(
              top: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF4081), width: 1.5),
                ),
                child: Text(
                  'Foto ${boothState.currentPhotoIndex + 1} / ${boothState.totalPhotosNeeded}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 4. Indikator Hitung Mundur Raksasa Animasi
          if (boothState.countdownNumber > 0)
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Container(
                  key: ValueKey<int>(boothState.countdownNumber),
                  width: 220,
                  height: 220,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.5),
                    border: Border.all(color: const Color(0xFFFF4081), width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4081).withValues(alpha: 0.6),
                        blurRadius: 50,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    '${boothState.countdownNumber}',
                    style: const TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // 5. Tombol Shutter Mulai Sekuens Foto
          if (boothState.step == BoothStep.idle)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    final neededPhotos = setupConfig.photoCount;
                    boothCtrl.startCaptureSequence(
                      totalPhotos: neededPhotos,
                      onSequenceFinished: () {
                        final stateNow = ref.read(boothProvider);
                        if (stateNow.capturedPhotos.isNotEmpty && setupConfig.templatePngBytes != null) {
                          ref.read(resultProvider.notifier).processAndUpload(
                                photos: stateNow.capturedPhotos,
                                template: setupConfig.templatePngBytes!,
                                detectedSlots: setupConfig.detectedSlots,
                                templateWidth: setupConfig.templateWidth,
                                templateHeight: setupConfig.templateHeight,
                                scriptUrl: setupConfig.scriptUrl,
                                folderId: setupConfig.folderId,
                              );
                          context.go('/result');
                        }
                      },
                    );
                  },
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF4081), Color(0xFF7C4DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4081).withValues(alpha: 0.6),
                          blurRadius: 28,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(Icons.camera_alt, color: Color(0xFFFF4081), size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 6. Efek Layar Kilat Putih (Flash 100ms)
          if (boothState.isFlashing)
            Container(
              color: Colors.white,
              width: double.infinity,
              height: double.infinity,
            ),
        ],
      ),
    );
  }
}
