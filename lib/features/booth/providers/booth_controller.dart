import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../setup/providers/setup_provider.dart';
import '../models/booth_state.dart';

class BoothController extends StateNotifier<BoothState> {
  CameraController? _cameraController;
  bool _isDisposed = false;
  bool _isInitializing = false;

  BoothController() : super(const BoothState());

  CameraController? get cameraController => _cameraController;

  /// Inisialisasi Kamera cepat tanpa looping berulang jika sudah aktif
  Future<void> initializeCamera({CameraDescription? preferredCamera}) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      if (mounted) {
        state = state.copyWith(errorMessage: null);
      }
      return;
    }

    if (_isInitializing) return;
    _isInitializing = true;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          state = state.copyWith(errorMessage: 'Tidak ada perangkat kamera yang terdeteksi pada sistem.');
        }
        return;
      }

      CameraDescription cameraToUse;
      if (preferredCamera != null) {
        cameraToUse = cameras.firstWhere(
          (cam) => cam.name == preferredCamera.name,
          orElse: () => cameras.first,
        );
      } else {
        cameraToUse = cameras.firstWhere(
          (cam) => cam.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      }

      CameraController controller = CameraController(
        cameraToUse,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      try {
        await controller.initialize();
      } catch (_) {
        await controller.dispose();
        controller = CameraController(
          cameraToUse,
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        await controller.initialize();
      }

      if (!_isDisposed) {
        _cameraController = controller;
        if (mounted) {
          state = state.copyWith(errorMessage: null);
        }
      } else {
        await controller.dispose();
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(errorMessage: 'Kamera gagal diinisialisasi: $e');
      }
    } finally {
      _isInitializing = false;
    }
  }

  /// Eksekusi State Machine: Sekuens Pengambilan Foto Berulang Fleksibel (1 atau 2 kali)
  Future<void> startCaptureSequence({
    required int totalPhotos,
    required void Function() onSequenceFinished,
  }) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      final List<Uint8List> captured = [];
      final int count = totalPhotos.clamp(1, 2);

      state = state.copyWith(
        totalPhotosNeeded: count,
        capturedPhotos: [],
        errorMessage: null,
      );

      for (int i = 0; i < count; i++) {
        state = state.copyWith(
          currentPhotoIndex: i,
          step: BoothStep.countdown,
        );

        // Hitung Mundur 3.. 2.. 1..
        for (int c = 3; c >= 1; c--) {
          state = state.copyWith(countdownNumber: c);
          await Future.delayed(const Duration(seconds: 1));
        }

        // Flash & Jepret Foto
        state = state.copyWith(
          step: BoothStep.flash,
          isFlashing: true,
          countdownNumber: 0,
        );

        final XFile shot = await _cameraController!.takePicture();
        final Uint8List shotBytes = await shot.readAsBytes();
        captured.add(shotBytes);

        await Future.delayed(AppConstants.flashDuration);
        state = state.copyWith(
          isFlashing: false,
          capturedPhotos: List.from(captured),
        );

        // Jika masih ada foto berikutnya, beri jeda interval
        if (i < count - 1) {
          state = state.copyWith(step: BoothStep.interval);
          await Future.delayed(AppConstants.intervalBetweenShots);
        }
      }

      state = state.copyWith(step: BoothStep.completed);
      onSequenceFinished();
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal mengambil gambar: $e');
    }
  }

  /// Update status USB Hardware Shutter
  void updateUsbStatus(String message, bool isConnected) {
    if (mounted) {
      state = state.copyWith(
        isUsbConnected: isConnected,
        usbStatusMessage: message,
      );
    }
  }

  /// Reset session foto booth tanpa membuang koneksi sensor kamera
  void resetBoothSession() {
    state = BoothState(
      isUsbConnected: state.isUsbConnected,
      usbStatusMessage: state.usbStatusMessage,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController?.dispose();
    _cameraController = null;
    super.dispose();
  }
}

final boothProvider = StateNotifierProvider<BoothController, BoothState>((ref) {
  final controller = BoothController();
  final selectedCamera = ref.watch(setupProvider.select((s) => s.selectedCamera));
  controller.initializeCamera(preferredCamera: selectedCamera);
  return controller;
});
