import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/bluetooth_device_model.dart';
import '../models/bluetooth_message.dart';

abstract class BluetoothService {
  Stream<List<BluetoothDeviceModel>> get devicesStream;
  Stream<BluetoothMessage> get messageStream;
  Stream<String> get speechResultStream;
  Stream<String> get speechStatusStream;
  Stream<bool> get bluetoothStateStream;
  List<BluetoothDeviceModel> get discoveredDevices;
  bool get isScanning;
  bool get isConnected;
  bool get isConnecting;
  BluetoothDeviceModel? get connectedDevice;

  Future<bool> isBluetoothEnabled();
  Future<bool> requestEnableBluetooth();
  Future<void> startScan();
  Future<void> stopScan();
  Future<bool> connect(BluetoothDeviceModel device, {String? pin});
  Future<void> disconnect();
  Future<bool> sendText(String text, {String newline = '\n'});
  Future<bool> sendChar(String char);
  Future<bool> sendPwm(int pin, int value);
  Future<bool> startSpeechRecognition();
  Future<void> stopSpeechRecognition();
  Future<bool> startGoogleVoiceDialog();
}

class DefaultBluetoothService implements BluetoothService {
  static const MethodChannel _channel =
      MethodChannel('app.arduino.esp32.controller.com/bluetooth');

  final StreamController<List<BluetoothDeviceModel>> _devicesController =
      StreamController<List<BluetoothDeviceModel>>.broadcast();
  final StreamController<BluetoothMessage> _messageController =
      StreamController<BluetoothMessage>.broadcast();
  final StreamController<String> _speechResultController =
      StreamController<String>.broadcast();
  final StreamController<String> _speechStatusController =
      StreamController<String>.broadcast();
  final StreamController<bool> _bluetoothStateController =
      StreamController<bool>.broadcast();

  bool _isScanning = false;
  bool _isConnected = false;
  bool _isConnecting = false;
  BluetoothDeviceModel? _connectedDevice;

  final List<BluetoothDeviceModel> _discoveredDevices = [];
  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  DefaultBluetoothService() {
    if (_isAndroid) {
      _initAndroidChannel();
    }
  }

  void _initAndroidChannel() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onDeviceDiscovered':
          if (call.arguments is Map) {
            final map = Map<String, dynamic>.from(call.arguments as Map);
            _addDiscoveredDevice(map);
          }
          break;
        case 'onDiscoveryFinished':
          _isScanning = false;
          _devicesController.add(List.unmodifiable(_discoveredDevices));
          break;
        case 'onDataReceived':
          final text = call.arguments as String? ?? '';
          _messageController.add(
            BluetoothMessage(
              content: text.trimRight(),
              isTx: false,
            ),
          );
          break;
        case 'onConnectionStateChanged':
          if (call.arguments is Map) {
            final map = Map<String, dynamic>.from(call.arguments as Map);
            final connected = map['connected'] as bool? ?? false;
            _isConnected = connected;
            if (!connected) {
              _connectedDevice = null;
              final err = map['error'] as String? ?? 'Disconnected';
              _messageController.add(
                BluetoothMessage(
                  content: 'Bluetooth: $err',
                  isTx: false,
                ),
              );
            }
          }
          break;
        case 'onSpeechResult':
          final text = call.arguments as String? ?? '';
          _speechResultController.add(text);
          break;
        case 'onSpeechPartial':
          final text = call.arguments as String? ?? '';
          _speechResultController.add(text);
          break;
        case 'onSpeechStatus':
          final status = call.arguments as String? ?? 'IDLE';
          _speechStatusController.add(status);
          break;
        case 'onSpeechError':
          final err = call.arguments as String? ?? 'Speech Error';
          _messageController.add(
            BluetoothMessage(
              content: 'Voice: $err',
              isTx: false,
            ),
          );
          _speechStatusController.add('IDLE');
          break;
        case 'onBluetoothStateChanged':
          final isEnabled = call.arguments as bool? ?? false;
          _bluetoothStateController.add(isEnabled);
          if (!isEnabled) {
            _isConnected = false;
            _connectedDevice = null;
            _messageController.add(
              BluetoothMessage(
                content: 'Bluetooth was turned OFF on this phone.',
                isTx: false,
              ),
            );
          }
          break;
      }
    });

    _loadBondedDevices();
  }

  Future<void> _loadBondedDevices() async {
    try {
      await _channel.invokeMethod('requestPermissions');
      final list = await _channel.invokeMethod<List>('getBondedDevices');
      if (list != null) {
        for (final item in list) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            _addDiscoveredDevice(map);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading bonded devices: $e');
    }
  }

  void _addDiscoveredDevice(Map<String, dynamic> map) {
    final addr = map['address'] as String? ?? '';
    if (addr.isEmpty) return;
    final name = map['name'] as String? ?? 'Arduino BT';
    final isPaired = map['isPaired'] as bool? ?? false;
    final rssi = map['rssi'] as int? ?? -60;

    final index = _discoveredDevices.indexWhere((d) => d.address == addr);
    final model = BluetoothDeviceModel(
      name: name,
      address: addr,
      isPaired: isPaired,
      rssi: rssi,
      requiresPin: !isPaired,
      defaultPin: '1234',
    );

    if (index >= 0) {
      _discoveredDevices[index] = model;
    } else {
      _discoveredDevices.add(model);
    }
    _devicesController.add(List.unmodifiable(_discoveredDevices));
  }

  @override
  Stream<List<BluetoothDeviceModel>> get devicesStream =>
      _devicesController.stream;

  @override
  Stream<BluetoothMessage> get messageStream => _messageController.stream;

  @override
  Stream<String> get speechResultStream => _speechResultController.stream;

  @override
  Stream<String> get speechStatusStream => _speechStatusController.stream;

  @override
  Stream<bool> get bluetoothStateStream => _bluetoothStateController.stream;

  @override
  List<BluetoothDeviceModel> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  @override
  bool get isScanning => _isScanning;

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isConnecting => _isConnecting;

  @override
  BluetoothDeviceModel? get connectedDevice => _connectedDevice;

  @override
  Future<bool> isBluetoothEnabled() async {
    if (_isAndroid) {
      try {
        final isEnabled =
            await _channel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
        _bluetoothStateController.add(isEnabled);
        return isEnabled;
      } catch (e) {
        debugPrint('isBluetoothEnabled error: $e');
        return false;
      }
    }
    return true; // For desktop preview/tests
  }

  @override
  Future<bool> requestEnableBluetooth() async {
    if (_isAndroid) {
      try {
        final ok =
            await _channel.invokeMethod<bool>('requestEnableBluetooth') ?? false;
        _bluetoothStateController.add(ok);
        return ok;
      } catch (e) {
        debugPrint('requestEnableBluetooth error: $e');
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;

    if (_isAndroid) {
      try {
        // 1. Immediately reload and emit all paired/bonded devices
        await _loadBondedDevices();
        // 2. Start hardware discovery for nearby unpaired Arduino/ESP32 modules
        await _channel.invokeMethod('startDiscovery');
      } catch (e) {
        _isScanning = false;
        _messageController.add(
          BluetoothMessage(
            content: 'Scan Error: $e',
            isTx: false,
          ),
        );
      }
    } else {
      _isScanning = false;
      _devicesController.add(List.unmodifiable(_discoveredDevices));
    }
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('stopDiscovery');
      } catch (e) {
        debugPrint('Stop discovery error: $e');
      }
    }
  }

  @override
  Future<bool> connect(BluetoothDeviceModel device, {String? pin}) async {
    _isConnecting = true;

    if (_isAndroid) {
      try {
        final ok = await _channel.invokeMethod<bool>('connect', {
              'address': device.address,
              'pin': pin,
            }) ??
            false;

        _isConnecting = false;
        if (ok) {
          _isConnected = true;
          _connectedDevice =
              device.copyWith(isConnected: true, isPaired: true);
          _messageController.add(
            BluetoothMessage(
              content:
                  'Connected to ${device.name} [${device.address}] via SPP.',
              isTx: false,
            ),
          );
          return true;
        } else {
          _messageController.add(
            BluetoothMessage(
              content:
                  'Failed to connect to ${device.name}. Please ensure HC-05 is powered on.',
              isTx: false,
            ),
          );
          return false;
        }
      } catch (e) {
        _isConnecting = false;
        _messageController.add(
          BluetoothMessage(
            content: 'Connection Error: $e',
            isTx: false,
          ),
        );
        return false;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      _isConnecting = false;
      _isConnected = true;
      _connectedDevice =
          device.copyWith(isConnected: true, isPaired: true);
      _messageController.add(
        BluetoothMessage(
          content: 'Connected to ${device.name} [${device.address}] via SPP.',
          isTx: false,
        ),
      );
      return true;
    }
  }

  @override
  Future<void> disconnect() async {
    if (!_isConnected) return;
    final name = _connectedDevice?.name ?? 'Device';
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('disconnect');
      } catch (e) {
        debugPrint('Disconnect error: $e');
      }
    }
    _isConnected = false;
    _connectedDevice = null;

    _messageController.add(
      BluetoothMessage(
        content: 'Disconnected from $name.',
        isTx: false,
      ),
    );
  }

  @override
  Future<bool> sendText(String text, {String newline = '\n'}) async {
    if (!_isConnected) {
      _messageController.add(
        BluetoothMessage(
          content: 'Error: Cannot send - Bluetooth is not connected.',
          isTx: false,
        ),
      );
      return false;
    }

    final payload = '$text$newline';

    if (_isAndroid) {
      try {
        await _channel.invokeMethod('sendData', {'data': payload});
      } catch (e) {
        _messageController.add(
          BluetoothMessage(content: 'Send Failed: $e', isTx: false),
        );
        return false;
      }
    }

    _messageController.add(
      BluetoothMessage(
        content: payload.trimRight(),
        isTx: true,
        isChar: false,
      ),
    );

    return true;
  }

  @override
  Future<bool> sendChar(String char) async {
    if (!_isConnected) {
      _messageController.add(
        BluetoothMessage(
          content: 'Error: Cannot send - Bluetooth is not connected.',
          isTx: false,
        ),
      );
      return false;
    }

    final toSend = char.isNotEmpty ? char.substring(0, 1) : '';
    if (toSend.isEmpty) return false;

    if (_isAndroid) {
      try {
        await _channel.invokeMethod('sendData', {'data': toSend});
      } catch (e) {
        _messageController.add(
          BluetoothMessage(content: 'Send Failed: $e', isTx: false),
        );
        return false;
      }
    }

    _messageController.add(
      BluetoothMessage(
        content: toSend,
        isTx: true,
        isChar: true,
      ),
    );

    return true;
  }

  @override
  Future<bool> sendPwm(int pin, int value) async {
    if (!_isConnected) return false;

    final clampedVal = value.clamp(0, 255);
    final cmd = 'PWM:$pin:$clampedVal\n';

    if (_isAndroid) {
      try {
        await _channel.invokeMethod('sendData', {'data': cmd});
      } catch (e) {
        _messageController.add(
          BluetoothMessage(content: 'PWM Send Failed: $e', isTx: false),
        );
        return false;
      }
    }

    _messageController.add(
      BluetoothMessage(
        content: cmd.trim(),
        isTx: true,
        isChar: false,
      ),
    );

    return true;
  }

  @override
  Future<bool> startSpeechRecognition() async {
    if (_isAndroid) {
      try {
        final ok =
            await _channel.invokeMethod<bool>('startSpeechRecognition') ?? false;
        return ok;
      } catch (e) {
        _messageController.add(
          BluetoothMessage(
            content: 'Voice Recognition Error: $e',
            isTx: false,
          ),
        );
        return false;
      }
    } else {
      _speechStatusController.add('LISTENING');
      return true;
    }
  }

  @override
  Future<void> stopSpeechRecognition() async {
    if (_isAndroid) {
      try {
        await _channel.invokeMethod('stopSpeechRecognition');
      } catch (e) {
        debugPrint('Stop speech error: $e');
      }
    }
    _speechStatusController.add('IDLE');
  }

  @override
  Future<bool> startGoogleVoiceDialog() async {
    if (_isAndroid) {
      try {
        final ok = await _channel.invokeMethod<bool>('startGoogleVoiceDialog') ?? false;
        return ok;
      } catch (e) {
        _messageController.add(
          BluetoothMessage(
            content: 'Google Voice Error: $e',
            isTx: false,
          ),
        );
        return false;
      }
    } else {
      _speechResultController.add('light on');
      return true;
    }
  }
}
