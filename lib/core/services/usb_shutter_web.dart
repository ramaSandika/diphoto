import 'dart:js_interop';

@JS('window.DiPhotoUSB.connectCamera')
external JSPromise<JSBoolean> _jsConnectCamera();

@JS('window.DiPhotoUSB.disconnect')
external void _jsDisconnect();

@JS('window.DiPhotoUSB.onShutterPressed')
external void _jsOnShutterPressed(JSFunction callback);

@JS('window.DiPhotoUSB.onStatusChange')
external void _jsOnStatusChange(JSFunction callback);

/// Implementasi WebUSB untuk Browser
class UsbShutterService {
  void Function()? onShutter;
  void Function(String message, bool isConnected)? onStatus;

  Future<bool> connect() async {
    try {
      _jsOnShutterPressed((() {
        if (onShutter != null) {
          onShutter!();
        }
      }).toJS);

      _jsOnStatusChange(((JSString msg, JSBoolean connected) {
        if (onStatus != null) {
          onStatus!(msg.toDart, connected.toDart);
        }
      }).toJS);

      final jsPromise = _jsConnectCamera();
      final JSBoolean result = await jsPromise.toDart;
      return result.toDart;
    } catch (e) {
      if (onStatus != null) {
        onStatus!('Gagal menghubungkan USB: $e', false);
      }
      return false;
    }
  }

  void disconnect() {
    try {
      _jsDisconnect();
    } catch (_) {}
  }
}
