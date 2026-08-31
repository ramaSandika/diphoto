import 'dart:typed_data';

enum BoothStep {
  idle,
  countdown,
  flash,
  interval,
  completed,
}

class BoothState {
  final BoothStep step;
  final int countdownNumber;
  final bool isFlashing;
  final int currentPhotoIndex; // 0-based index: 0 = foto 1, 1 = foto 2
  final int totalPhotosNeeded; // 1 atau 2 foto
  final List<Uint8List> capturedPhotos;
  final String? errorMessage;

  const BoothState({
    this.step = BoothStep.idle,
    this.countdownNumber = 0,
    this.isFlashing = false,
    this.currentPhotoIndex = 0,
    this.totalPhotosNeeded = 2,
    this.capturedPhotos = const [],
    this.errorMessage,
  });

  BoothState copyWith({
    BoothStep? step,
    int? countdownNumber,
    bool? isFlashing,
    int? currentPhotoIndex,
    int? totalPhotosNeeded,
    List<Uint8List>? capturedPhotos,
    String? errorMessage,
  }) {
    return BoothState(
      step: step ?? this.step,
      countdownNumber: countdownNumber ?? this.countdownNumber,
      isFlashing: isFlashing ?? this.isFlashing,
      currentPhotoIndex: currentPhotoIndex ?? this.currentPhotoIndex,
      totalPhotosNeeded: totalPhotosNeeded ?? this.totalPhotosNeeded,
      capturedPhotos: capturedPhotos ?? this.capturedPhotos,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
