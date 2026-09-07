/// Implementasi dummy untuk Native platform (Windows/iOS/Android)
class UsbShutterService {
  void Function()? onShutter;
  void Function(String message, bool isConnected)? onStatus;

  Future<bool> connect() async {
    if (onStatus != null) {
      onStatus!('Modul hardware shutter aktif untuk versi Web via WebUSB.', false);
    }
    return false;
  }

  void disconnect() {}
}
