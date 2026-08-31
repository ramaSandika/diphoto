import 'dart:typed_data';

enum ResultStatus {
  processing,
  uploading,
  success,
  error,
}

class ResultState {
  final ResultStatus status;
  final Uint8List? compositeImageBytes;
  final String? driveViewLink;
  final String? errorMessage;

  const ResultState({
    this.status = ResultStatus.processing,
    this.compositeImageBytes,
    this.driveViewLink,
    this.errorMessage,
  });

  ResultState copyWith({
    ResultStatus? status,
    Uint8List? compositeImageBytes,
    String? driveViewLink,
    String? errorMessage,
  }) {
    return ResultState(
      status: status ?? this.status,
      compositeImageBytes: compositeImageBytes ?? this.compositeImageBytes,
      driveViewLink: driveViewLink ?? this.driveViewLink,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
