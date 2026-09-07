import 'dart:typed_data';

enum ResultStatus {
  idle,
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
  final bool isUploading;
  final String? uploadError;

  const ResultState({
    this.status = ResultStatus.idle,
    this.compositeImageBytes,
    this.driveViewLink,
    this.errorMessage,
    this.isUploading = false,
    this.uploadError,
  });

  ResultState copyWith({
    ResultStatus? status,
    Uint8List? compositeImageBytes,
    String? driveViewLink,
    String? errorMessage,
    bool? isUploading,
    String? uploadError,
  }) {
    return ResultState(
      status: status ?? this.status,
      compositeImageBytes: compositeImageBytes ?? this.compositeImageBytes,
      driveViewLink: driveViewLink ?? this.driveViewLink,
      errorMessage: errorMessage ?? this.errorMessage,
      isUploading: isUploading ?? this.isUploading,
      uploadError: uploadError ?? this.uploadError,
    );
  }
}
