import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bluetooth_device_model.dart';
import '../models/bluetooth_message.dart';
import '../services/bluetooth_service.dart';

class BluetoothProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService;
  StreamSubscription<List<BluetoothDeviceModel>>? _devicesSub;
  StreamSubscription<BluetoothMessage>? _messagesSub;
  StreamSubscription<String>? _speechSub;
  StreamSubscription<String>? _speechStatusSub;
  StreamSubscription<bool>? _btStateSub;

  BluetoothProvider({BluetoothService? bluetoothService, bool autoScan = false})
      : _bluetoothService = bluetoothService ?? DefaultBluetoothService() {
    _initStreams();
    if (autoScan) {
      scanDevices();
    }
  }

  // Device & Connection State
  List<BluetoothDeviceModel> _discoveredDevices = [];
  List<BluetoothDeviceModel> get discoveredDevices => _discoveredDevices;

  bool _isBluetoothEnabled = true;
  bool get isBluetoothEnabled => _isBluetoothEnabled;

  bool get isScanning => _bluetoothService.isScanning;
  bool get isConnected => _bluetoothService.isConnected;
  bool get isConnecting => _bluetoothService.isConnecting;
  BluetoothDeviceModel? get connectedDevice => _bluetoothService.connectedDevice;

  // LED Controls State
  bool _isBuiltinLedOn = false;
  bool get isBuiltinLedOn => _isBuiltinLedOn;

  final Map<String, bool> _channelStates = {
    'LED 1 (D12)': false,
    'LED 2 (D11)': false,
    'LED 3 (D10)': false,
    'Relay 1 (D7)': false,
  };
  Map<String, bool> get channelStates => Map.unmodifiable(_channelStates);

  // PWM Controls State
  int _pwmPin = 9;
  int get pwmPin => _pwmPin;
  final List<int> pwmAvailablePins = [3, 5, 6, 9, 10, 11];

  int _pwmValue = 0; // 0 to 255
  int get pwmValue => _pwmValue;
  int get pwmPercent => ((_pwmValue / 255) * 100).round();

  // Text & Character Controls State
  String _selectedLineEnding = '\n';
  String get selectedLineEnding => _selectedLineEnding;
  final List<String> lineEndingOptions = ['\\n (LF)', '\\r\\n (CRLF)', 'None'];

  // Messages / Terminal Log
  final List<BluetoothMessage> _messages = [];
  List<BluetoothMessage> get messages => List.unmodifiable(_messages);

  bool _autoScroll = true;
  bool get autoScroll => _autoScroll;

  // Voice Command State
  String _voiceStatus = 'IDLE'; // IDLE, LISTENING, PROCESSING
  String get voiceStatus => _voiceStatus;
  bool get isListeningVoice => _voiceStatus == 'LISTENING';

  String _lastVoiceSpoken = '';
  String get lastVoiceSpoken => _lastVoiceSpoken;

  String _lastTransmittedVoiceCommand = '';
  String get lastTransmittedVoiceCommand => _lastTransmittedVoiceCommand;

  void toggleAutoScroll() {
    _autoScroll = !_autoScroll;
    notifyListeners();
  }

  void _initStreams() {
    _discoveredDevices = List.from(_bluetoothService.discoveredDevices);
    _devicesSub = _bluetoothService.devicesStream.listen((devs) {
      _discoveredDevices = devs;
      notifyListeners();
    });

    _messagesSub = _bluetoothService.messageStream.listen((msg) {
      _messages.add(msg);
      if (_messages.length > 250) {
        _messages.removeAt(0);
      }
      notifyListeners();
    });

    _speechSub = _bluetoothService.speechResultStream.listen((text) {
      if (text.trim().isNotEmpty) {
        processAndSendVoiceCommand(text);
      }
    });

    _speechStatusSub = _bluetoothService.speechStatusStream.listen((status) {
      _voiceStatus = status;
      notifyListeners();
    });

    _btStateSub = _bluetoothService.bluetoothStateStream.listen((enabled) {
      _isBluetoothEnabled = enabled;
      notifyListeners();
    });

    _checkInitialBluetoothState();
  }

  Future<void> _checkInitialBluetoothState() async {
    _isBluetoothEnabled = await _bluetoothService.isBluetoothEnabled();
    notifyListeners();
  }

  Future<bool> enableBluetooth() async {
    final ok = await _bluetoothService.requestEnableBluetooth();
    _isBluetoothEnabled = ok;
    notifyListeners();
    return ok;
  }

  // Scan Actions
  Future<void> scanDevices() async {
    // 1. Check if phone's Bluetooth is ON first!
    var enabled = await _bluetoothService.isBluetoothEnabled();
    if (!enabled) {
      // 2. If OFF, trigger system process to turn it ON
      enabled = await enableBluetooth();
      if (!enabled) {
        _messages.add(
          BluetoothMessage(
            content:
                'Bluetooth is turned OFF. Please turn ON your phone Bluetooth to scan for Arduino/ESP32.',
            isTx: false,
          ),
        );
        notifyListeners();
        return;
      }
    }

    // 3. Bluetooth is confirmed ON -> proceed to scan
    _isBluetoothEnabled = true;
    notifyListeners();
    await _bluetoothService.startScan();
    notifyListeners();
  }

  Future<void> stopScan() async {
    await _bluetoothService.stopScan();
    notifyListeners();
  }

  // Connection Actions
  Future<bool> connectDevice(BluetoothDeviceModel device, {String? pin}) async {
    notifyListeners();
    final ok = await _bluetoothService.connect(device, pin: pin);
    notifyListeners();
    return ok;
  }

  Future<void> disconnectDevice() async {
    await _bluetoothService.disconnect();
    _isBuiltinLedOn = false;
    _channelStates.updateAll((key, val) => false);
    _pwmValue = 0;
    notifyListeners();
  }

  // LED Actions
  Future<void> toggleBuiltinLed() async {
    if (!isConnected) return;
    _isBuiltinLedOn = !_isBuiltinLedOn;
    final char = _isBuiltinLedOn ? '1' : '0';
    await _bluetoothService.sendChar(char);
    notifyListeners();
  }

  Future<void> setBuiltinLed(bool state) async {
    if (!isConnected) return;
    _isBuiltinLedOn = state;
    final char = state ? '1' : '0';
    await _bluetoothService.sendChar(char);
    notifyListeners();
  }

  Future<void> toggleChannel(String channelName) async {
    if (!isConnected) return;
    final currentState = _channelStates[channelName] ?? false;
    final newState = !currentState;
    _channelStates[channelName] = newState;

    String charToSend = '';
    if (channelName.contains('LED 1')) {
      charToSend = newState ? 'A' : 'a';
    } else if (channelName.contains('LED 2')) {
      charToSend = newState ? 'B' : 'b';
    } else if (channelName.contains('LED 3')) {
      charToSend = newState ? 'C' : 'c';
    } else if (channelName.contains('Relay')) {
      charToSend = newState ? 'R' : 'r';
    }

    if (charToSend.isNotEmpty) {
      await _bluetoothService.sendChar(charToSend);
    }
    notifyListeners();
  }

  // PWM Actions
  void setPwmPin(int pin) {
    _pwmPin = pin;
    notifyListeners();
  }

  Future<void> setPwmValue(int val) async {
    final clamped = val.clamp(0, 255);
    _pwmValue = clamped;
    notifyListeners();
    if (isConnected) {
      await _bluetoothService.sendPwm(_pwmPin, clamped);
    }
  }

  Future<void> setPwmPercent(int percent) async {
    final val = ((percent.clamp(0, 100) / 100) * 255).round();
    await setPwmValue(val);
  }

  // Text Actions
  void setLineEnding(String ending) {
    if (ending.contains('CRLF')) {
      _selectedLineEnding = '\r\n';
    } else if (ending.contains('None')) {
      _selectedLineEnding = '';
    } else {
      _selectedLineEnding = '\n';
    }
    notifyListeners();
  }

  Future<bool> sendCustomText(String text) async {
    if (text.trim().isEmpty) return false;
    return await _bluetoothService.sendText(text.trim(), newline: _selectedLineEnding);
  }

  // Character Actions
  Future<bool> sendSingleChar(String char) async {
    if (char.isEmpty) return false;
    return await _bluetoothService.sendChar(char[0]);
  }

  // Voice Command Actions
  Future<void> startVoiceListening() async {
    _lastVoiceSpoken = '';
    _voiceStatus = 'LISTENING';
    notifyListeners();
    final ok = await _bluetoothService.startSpeechRecognition();
    if (!ok) {
      _voiceStatus = 'IDLE';
      notifyListeners();
    }
  }

  Future<void> stopVoiceListening() async {
    _voiceStatus = 'IDLE';
    await _bluetoothService.stopSpeechRecognition();
    notifyListeners();
  }

  Future<void> toggleVoiceListening() async {
    if (isListeningVoice) {
      await stopVoiceListening();
    } else {
      await startVoiceListening();
    }
  }

  Future<void> openGoogleVoiceDialog() async {
    _lastVoiceSpoken = '';
    _voiceStatus = 'LISTENING';
    notifyListeners();
    final ok = await _bluetoothService.startGoogleVoiceDialog();
    if (!ok) {
      _voiceStatus = 'IDLE';
      notifyListeners();
    }
  }

  Future<bool> processAndSendVoiceCommand(String rawSpeech) async {
    final clean = rawSpeech.trim();
    if (clean.isEmpty) return false;

    _lastVoiceSpoken = clean;
    final lower = clean.toLowerCase();
    String cmdToSend = clean;

    // 1. SMART NUMBER & COMMON ARDUINO COMMAND NORMALIZATION:
    // When someone says "one" or "1" or "on" -> Turn ON LED 13
    if (lower == '1' ||
        lower == 'one' ||
        lower == 'van' ||
        lower == 'won' ||
        lower == 'ek' ||
        lower == 'on' ||
        lower == 'ledon' ||
        lower == 'lighton' ||
        lower.contains('light on') ||
        lower.contains('led on')) {
      _isBuiltinLedOn = true;
      // If user specifically said "1" or "one", transmit '1' (standard Arduino pin HIGH char/string)
      if (lower == '1' ||
          lower == 'one' ||
          lower == 'van' ||
          lower == 'won' ||
          lower == 'ek') {
        cmdToSend = '1';
      }
    }
    // When someone says "zero" or "0" or "off" -> Turn OFF LED 13
    else if (lower == '0' ||
        lower == 'zero' ||
        lower == 'shunya' ||
        lower == 'off' ||
        lower == 'ledoff' ||
        lower == 'lightoff' ||
        lower.contains('light off') ||
        lower.contains('led off')) {
      _isBuiltinLedOn = false;
      // If user specifically said "0" or "zero", transmit '0' (standard Arduino pin LOW char/string)
      if (lower == '0' || lower == 'zero' || lower == 'shunya') {
        cmdToSend = '0';
      }
    }
    // "all on"
    else if (lower == 'all on' || lower == 'allon' || lower.contains('all on')) {
      _isBuiltinLedOn = true;
      _channelStates.updateAll((key, val) => true);
      cmdToSend = 'ALL_ON';
    }
    // "all off"
    else if (lower == 'all off' || lower == 'alloff' || lower.contains('all off')) {
      _isBuiltinLedOn = false;
      _channelStates.updateAll((key, val) => false);
      cmdToSend = 'ALL_OFF';
    }
    // Other numbers (2, 3, 4, 5...)
    else if (lower == 'two' || lower == '2') {
      cmdToSend = '2';
    } else if (lower == 'three' || lower == '3') {
      cmdToSend = '3';
    } else if (lower == 'four' || lower == '4') {
      cmdToSend = '4';
    } else if (lower == 'five' || lower == '5') {
      cmdToSend = '5';
    }

    _lastTransmittedVoiceCommand = cmdToSend;
    notifyListeners();

    // Transmit string message to Arduino Bluetooth Terminal
    return await _bluetoothService.sendText(cmdToSend, newline: '\n');
  }

  // Terminal Logs
  void clearLogs() {
    _messages.clear();
    _messages.add(
      BluetoothMessage(
        content: 'Console cleared.',
        isTx: false,
      ),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _bluetoothService.stopScan();
    _devicesSub?.cancel();
    _messagesSub?.cancel();
    _speechSub?.cancel();
    _speechStatusSub?.cancel();
    _btStateSub?.cancel();
    super.dispose();
  }
}
