import 'dart:async';
import 'package:flutter/services.dart';
import '../../data/local/models/bluetooth_peer_model.dart';

abstract class BluetoothTransport {
  Future<bool> isSupported();
  Future<bool> isEnabled();
  Future<bool> requestPermissions();
  Stream<BluetoothPeerModel> discoverDevices();
  Future<void> stopDiscovery();
  Future<bool> connect(String deviceAddress);
  Future<void> disconnect();
  Future<void> sendData(String rawJson);
  Stream<String> get incomingDataStream;
  bool get isConnected;
  String? get connectedDeviceAddress;
}

/// Native implementation communicating with Android Bluetooth stack via MethodChannel
class NativeBluetoothTransport implements BluetoothTransport {
  static const MethodChannel _channel = MethodChannel('com.disasterready.app/bluetooth');

  final StreamController<String> _incomingController = StreamController<String>.broadcast();
  bool _connected = false;
  String? _connectedAddress;

  NativeBluetoothTransport() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onDataReceived':
        final data = call.arguments as String?;
        if (data != null) {
          _incomingController.add(data);
        }
        break;
      case 'onDisconnected':
        _connected = false;
        _connectedAddress = null;
        break;
    }
  }

  @override
  Future<bool> isSupported() async {
    try {
      final res = await _channel.invokeMethod<bool>('isSupported');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isEnabled');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      final res = await _channel.invokeMethod<bool>('requestPermissions');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<BluetoothPeerModel> discoverDevices() {
    final controller = StreamController<BluetoothPeerModel>();
    _channel.invokeMethod<List<dynamic>>('getDiscoveredDevices').then((devices) {
      if (devices != null) {
        for (final d in devices) {
          if (d is Map) {
            controller.add(BluetoothPeerModel(
              id: d['address'] as String? ?? 'dev-unknown',
              deviceName: d['name'] as String? ?? 'DisasterReady Device',
              deviceAddress: d['address'] as String? ?? '00:00:00:00:00:00',
              lastSeen: DateTime.now().toIso8601String(),
            ));
          }
        }
      }
      controller.close();
    }).catchError((e) {
      controller.close();
    });
    return controller.stream;
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod('stopDiscovery');
    } catch (_) {}
  }

  @override
  Future<bool> connect(String deviceAddress) async {
    try {
      final success = await _channel.invokeMethod<bool>('connect', {'address': deviceAddress});
      if (success == true) {
        _connected = true;
        _connectedAddress = deviceAddress;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod('disconnect');
      _connected = false;
      _connectedAddress = null;
    } catch (_) {}
  }

  @override
  Future<void> sendData(String rawJson) async {
    await _channel.invokeMethod('sendData', {'data': rawJson});
  }

  @override
  Stream<String> get incomingDataStream => _incomingController.stream;

  @override
  bool get isConnected => _connected;

  @override
  String? get connectedDeviceAddress => _connectedAddress;
}

/// In-memory transport for deterministic testing and simulated dual-device environments
class InMemoryBluetoothTransport implements BluetoothTransport {
  InMemoryBluetoothTransport? pairedPeer;
  final StreamController<String> _incomingController = StreamController<String>.broadcast();
  final List<BluetoothPeerModel> simulatedNearbyDevices;

  bool _connected = false;
  String? _connectedAddress;
  bool supported;
  bool enabled;

  InMemoryBluetoothTransport({
    this.simulatedNearbyDevices = const [],
    this.supported = true,
    this.enabled = true,
  });

  /// Pair two transports together to simulate Device A ↔ Device B
  static void pair(InMemoryBluetoothTransport a, InMemoryBluetoothTransport b) {
    a.pairedPeer = b;
    b.pairedPeer = a;
    a._connected = true;
    b._connected = true;
    a._connectedAddress = 'PEER-B-ADDR';
    b._connectedAddress = 'PEER-A-ADDR';
  }

  @override
  Future<bool> isSupported() async => supported;

  @override
  Future<bool> isEnabled() async => enabled;

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Stream<BluetoothPeerModel> discoverDevices() async* {
    for (final dev in simulatedNearbyDevices) {
      yield dev;
    }
  }

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<bool> connect(String deviceAddress) async {
    _connected = true;
    _connectedAddress = deviceAddress;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    _connectedAddress = null;
  }

  @override
  Future<void> sendData(String rawJson) async {
    if (pairedPeer != null && pairedPeer!.isConnected) {
      pairedPeer!._incomingController.add(rawJson);
    }
  }

  @override
  Stream<String> get incomingDataStream => _incomingController.stream;

  @override
  bool get isConnected => _connected;

  @override
  String? get connectedDeviceAddress => _connectedAddress;
}
