import 'usb_shutter_io.dart' if (dart.library.js_interop) 'usb_shutter_web.dart' as impl;

/// Facade Universal untuk Layanan Shutter USB Hardware Kamera (Sony ZV-E10 dsb)
class CameraUsbShutterService {
  final impl.UsbShutterService _service = impl.UsbShutterService();

  set onShutter(void Function()? callback) {
    _service.onShutter = callback;
  }

  set onStatus(void Function(String message, bool isConnected)? callback) {
    _service.onStatus = callback;
  }

  Future<bool> connect() => _service.connect();
  void disconnect() => _service.disconnect();
}
