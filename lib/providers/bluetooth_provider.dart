import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/board_model.dart';
import '../models/bluetooth_device_model.dart';
import '../models/bluetooth_message.dart';
import '../models/wifi_device_model.dart';
import '../services/bluetooth_service.dart';
import '../services/wifi_service.dart';

enum ConnectionMedium { bluetooth, wifi }

class BluetoothProvider extends ChangeNotifier {
  final BluetoothService _bluetoothService;
  final WifiService _wifiService;
  StreamSubscription<List<BluetoothDeviceModel>>? _devicesSub;
  StreamSubscription<BluetoothMessage>? _messagesSub;
  StreamSubscription<String>? _speechSub;
  StreamSubscription<String>? _speechStatusSub;
  StreamSubscription<bool>? _btStateSub;
  StreamSubscription<BluetoothMessage>? _wifiMessagesSub;
  StreamSubscription<bool>? _wifiStateSub;

  ConnectionMedium _connectionMedium = ConnectionMedium.bluetooth;
  ConnectionMedium get connectionMedium => _connectionMedium;

  void setConnectionMedium(ConnectionMedium medium) {
    _connectionMedium = medium;
    notifyListeners();
  }

  BluetoothProvider({
    BluetoothService? bluetoothService,
    WifiService? wifiService,
    bool autoScan = false,
  }) : _bluetoothService = bluetoothService ?? DefaultBluetoothService(),
       _wifiService = wifiService ?? DefaultWifiService() {
    _initStreams();
    _initChannelStates();
    if (autoScan) {
      scanDevices();
    }
  }

  // Microcontroller Board & Pin Configurations
  MicrocontrollerBoard _selectedBoard = MicrocontrollerBoard.esp32DevKitV1;
  MicrocontrollerBoard get selectedBoard => _selectedBoard;

  late BoardPinConfig _pinConfig = BoardPinConfig.fromBoard(_selectedBoard);
  BoardPinConfig get pinConfig => _pinConfig;

  int get builtinLedPin => _pinConfig.builtinLedPin;
  int get relay1Pin => _pinConfig.relay1Pin;
  int get relay2Pin => _pinConfig.relay2Pin;
  int get relay3Pin => _pinConfig.relay3Pin;
  int get relay4Pin => _pinConfig.relay4Pin;

  List<int> get pwmAvailablePins => _selectedBoard.pwmPins;
  List<int> get availableAdcPins => _selectedBoard.adcPins;
  List<int> get availableDacPins => _selectedBoard.dacPins;
  List<int> get availableTouchPins => _selectedBoard.touchPins;
  List<int> get availableGpioPins => _selectedBoard.availableGpioPins;

  // Device & Connection State
  List<BluetoothDeviceModel> _discoveredDevices = [];
  List<BluetoothDeviceModel> get discoveredDevices => _discoveredDevices;

  bool _isBluetoothEnabled = true;
  bool get isBluetoothEnabled => _isBluetoothEnabled;

  bool get isScanning => _bluetoothService.isScanning;
  bool get isConnected {
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      return _bluetoothService.isConnected;
    }
    return _wifiService.isConnected;
  }

  bool get isConnecting {
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      return _bluetoothService.isConnecting;
    }
    return _wifiService.isConnecting;
  }

  bool get isBluetoothConnected => _bluetoothService.isConnected;
  bool get isWifiConnected => _wifiService.isConnected;
  bool get isWifiConnecting => _wifiService.isConnecting;
  String get wifiIp => _wifiService.ip;
  int get wifiPort => _wifiService.port;
  int get wifiLatencyMs => _wifiService.latencyMs;
  WifiProtocol get wifiProtocol => _wifiService.protocol;
  WifiDeviceModel get currentWifiDevice => _wifiService.currentDevice;

  String get activeConnectionTitle {
    if (_connectionMedium == ConnectionMedium.wifi) {
      if (_wifiService.isConnected) {
        return 'ESP32 WiFi (${_wifiService.ip}:${_wifiService.port})';
      }
      return 'ESP32 WiFi (Disconnected)';
    }
    if (_bluetoothService.isConnected &&
        _bluetoothService.connectedDevice != null) {
      return _bluetoothService.connectedDevice!.name;
    }
    return 'Bluetooth (Disconnected)';
  }

  BluetoothDeviceModel? get connectedDevice =>
      _bluetoothService.connectedDevice;

  // RGB LED State (Non-Addressable 4-pin RGB LED)
  int _rgbRed = 0;
  int _rgbGreen = 0;
  int _rgbBlue = 0;
  bool _isRgbOn = false;

  int get rgbRed => _rgbRed;
  int get rgbGreen => _rgbGreen;
  int get rgbBlue => _rgbBlue;
  bool get isRgbOn => _isRgbOn;
  int get rgbRedPin => _pinConfig.rgbRedPin;
  int get rgbGreenPin => _pinConfig.rgbGreenPin;
  int get rgbBluePin => _pinConfig.rgbBluePin;
  bool get isCommonAnode => _pinConfig.isCommonAnode;
  bool get isRgbBuiltin => _pinConfig.isRgbBuiltin;

  // LED Controls State
  bool _isBuiltinLedOn = false;
  bool get isBuiltinLedOn => _isBuiltinLedOn;

  final Map<String, bool> _channelStates = {};
  Map<String, bool> get channelStates => Map.unmodifiable(_channelStates);

  void _initChannelStates() {
    _channelStates.clear();
    _channelStates['Relay 1 (GPIO ${_pinConfig.relay1Pin})'] = false;
    _channelStates['Relay 2 (GPIO ${_pinConfig.relay2Pin})'] = false;
    _channelStates['Relay 3 (GPIO ${_pinConfig.relay3Pin})'] = false;
    _channelStates['Relay 4 (GPIO ${_pinConfig.relay4Pin})'] = false;
  }

  // PWM Controls State
  late int _pwmPin = _pinConfig.pwmPin;
  int get pwmPin => _pwmPin;

  int _pwmValue = 0; // 0 to 255
  int get pwmValue => _pwmValue;
  int get pwmPercent => ((_pwmValue / 255) * 100).round();

  // DAC (Digital-to-Analog True 8-bit output)
  int _dacPin = 25;
  int get dacPin => _dacPin;
  int _dacValue = 0; // 0 to 255 (0V - 3.3V)
  int get dacValue => _dacValue;
  double get dacVoltage => (_dacValue / 255.0) * 3.3;

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

    _wifiMessagesSub = _wifiService.messagesStream.listen((msg) {
      _messages.add(msg);
      if (_messages.length > 250) {
        _messages.removeAt(0);
      }
      notifyListeners();
    });

    _wifiStateSub = _wifiService.connectionStateStream.listen((_) {
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

  Future<void> disconnect() async {
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      await disconnectDevice();
    } else {
      await disconnectWifi();
    }
  }

  // Board & Pin Configuration Methods
  void setBoard(BoardType type) {
    _selectedBoard = MicrocontrollerBoard.getByType(type);
    _pinConfig = BoardPinConfig.fromBoard(_selectedBoard);
    _pwmPin = _pinConfig.pwmPin;
    if (_selectedBoard.hasDac && _selectedBoard.dacPins.isNotEmpty) {
      _dacPin = _selectedBoard.dacPins.first;
    }
    _initChannelStates();
    _messages.add(
      BluetoothMessage(
        content:
            'Active board switched to ${_selectedBoard.name}. Default GPIO pins updated.',
        isTx: false,
      ),
    );
    notifyListeners();
  }

  void updatePinConfig({
    int? builtinLedPin,
    int? relay1Pin,
    int? relay2Pin,
    int? relay3Pin,
    int? relay4Pin,
    int? pwmPin,
    int? rgbRedPin,
    int? rgbGreenPin,
    int? rgbBluePin,
    bool? isCommonAnode,
    bool? isRgbBuiltin,
  }) {
    _pinConfig = _pinConfig.copyWith(
      builtinLedPin: builtinLedPin,
      relay1Pin: relay1Pin,
      relay2Pin: relay2Pin,
      relay3Pin: relay3Pin,
      relay4Pin: relay4Pin,
      pwmPin: pwmPin,
      rgbRedPin: rgbRedPin,
      rgbGreenPin: rgbGreenPin,
      rgbBluePin: rgbBluePin,
      isCommonAnode: isCommonAnode,
      isRgbBuiltin: isRgbBuiltin,
    );
    if (pwmPin != null) {
      _pwmPin = pwmPin;
    }
    _initChannelStates();
    notifyListeners();
  }

  void resetPinsToDefault() {
    _pinConfig = BoardPinConfig.fromBoard(_selectedBoard);
    _pwmPin = _pinConfig.pwmPin;
    if (_selectedBoard.hasDac && _selectedBoard.dacPins.isNotEmpty) {
      _dacPin = _selectedBoard.dacPins.first;
    }
    _initChannelStates();
    notifyListeners();
  }

  // WiFi Connection Actions
  Future<bool> connectWifi({
    required String ip,
    required int port,
    WifiProtocol protocol = WifiProtocol.http,
    WifiMode mode = WifiMode.softAp,
  }) async {
    _connectionMedium = ConnectionMedium.wifi;
    notifyListeners();
    final ok = await _wifiService.connect(
      ip: ip,
      port: port,
      protocol: protocol,
      mode: mode,
    );
    notifyListeners();
    return ok;
  }

  Future<void> disconnectWifi() async {
    await _wifiService.disconnect();
    notifyListeners();
  }

  Future<int?> testPingWifi({required String ip, required int port}) async {
    final latency = await _wifiService.testPing(ip: ip, port: port);
    notifyListeners();
    return latency;
  }

  // RGB LED Actions (4-pin Non-Addressable R, G, B + Common Anode/Cathode)
  void updateRgbPins({
    int? rPin,
    int? gPin,
    int? bPin,
    bool? isCommonAnode,
    bool? isRgbBuiltin,
  }) {
    _pinConfig = _pinConfig.copyWith(
      rgbRedPin: rPin,
      rgbGreenPin: gPin,
      rgbBluePin: bPin,
      isCommonAnode: isCommonAnode,
      isRgbBuiltin: isRgbBuiltin,
    );
    notifyListeners();
  }

  Future<void> setRgbColor(int r, int g, int b) async {
    final cr = r.clamp(0, 255);
    final cg = g.clamp(0, 255);
    final cb = b.clamp(0, 255);

    _rgbRed = cr;
    _rgbGreen = cg;
    _rgbBlue = cb;
    _isRgbOn = (cr > 0 || cg > 0 || cb > 0);
    notifyListeners();

    if (isConnected) {
      // In Common Anode mode, PWM is inverted (0 is max brightness, 255 is OFF)
      final txR = _pinConfig.isCommonAnode ? (255 - cr) : cr;
      final txG = _pinConfig.isCommonAnode ? (255 - cg) : cg;
      final txB = _pinConfig.isCommonAnode ? (255 - cb) : cb;

      final payload = 'RGB:$txR:$txG:$txB';
      if (_connectionMedium == ConnectionMedium.bluetooth) {
        await _bluetoothService.sendText(payload, newline: '\n');
      } else {
        await _wifiService.sendText(payload, newline: '\n');
      }
    }
  }

  Future<void> toggleRgbPower(bool state) async {
    if (state) {
      if (_rgbRed == 0 && _rgbGreen == 0 && _rgbBlue == 0) {
        // Default to Full White when powered on from off
        await setRgbColor(255, 255, 255);
      } else {
        await setRgbColor(_rgbRed, _rgbGreen, _rgbBlue);
      }
    } else {
      _isRgbOn = false;
      notifyListeners();
      if (isConnected) {
        final tx = _pinConfig.isCommonAnode ? 'RGB:255:255:255' : 'RGB:0:0:0';
        if (_connectionMedium == ConnectionMedium.bluetooth) {
          await _bluetoothService.sendText(tx, newline: '\n');
        } else {
          await _wifiService.sendText(tx, newline: '\n');
        }
      }
    }
  }

  // LED Actions
  Future<void> toggleBuiltinLed() async {
    if (!isConnected) return;
    _isBuiltinLedOn = !_isBuiltinLedOn;
    final char = _isBuiltinLedOn ? '1' : '0';
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      await _bluetoothService.sendChar(char);
    } else {
      await _wifiService.sendChar(char);
    }
    notifyListeners();
  }

  Future<void> setBuiltinLed(bool state) async {
    if (!isConnected) return;
    _isBuiltinLedOn = state;
    final char = state ? '1' : '0';
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      await _bluetoothService.sendChar(char);
    } else {
      await _wifiService.sendChar(char);
    }
    notifyListeners();
  }

  Future<void> toggleChannel(String channelName) async {
    if (!isConnected) return;
    final currentState = _channelStates[channelName] ?? false;
    final newState = !currentState;
    _channelStates[channelName] = newState;

    String charToSend = '';
    int pin = _pinConfig.relay1Pin;
    int relayNum = 1;

    if (channelName.contains('Relay 1') || channelName.contains('LED 1')) {
      charToSend = newState ? 'A' : 'a';
      pin = _pinConfig.relay1Pin;
      relayNum = 1;
    } else if (channelName.contains('Relay 2') ||
        channelName.contains('LED 2')) {
      charToSend = newState ? 'B' : 'b';
      pin = _pinConfig.relay2Pin;
      relayNum = 2;
    } else if (channelName.contains('Relay 3') ||
        channelName.contains('LED 3')) {
      charToSend = newState ? 'C' : 'c';
      pin = _pinConfig.relay3Pin;
      relayNum = 3;
    } else if (channelName.contains('Relay 4') ||
        channelName.contains('Relay')) {
      charToSend = newState ? 'D' : 'd';
      pin = _pinConfig.relay4Pin;
      relayNum = 4;
    }

    if (_connectionMedium == ConnectionMedium.bluetooth) {
      if (charToSend.isNotEmpty) {
        await _bluetoothService.sendChar(charToSend);
      }
      await _bluetoothService.sendText(
        'R$relayNum:${newState ? 1 : 0}',
        newline: '\n',
      );
      await _bluetoothService.sendText(
        'RELAY:$pin:${newState ? 1 : 0}',
        newline: '\n',
      );
    } else {
      if (charToSend.isNotEmpty) {
        await _wifiService.sendChar(charToSend);
      }
      await _wifiService.sendText(
        'R$relayNum:${newState ? 1 : 0}',
        newline: '\n',
      );
      await _wifiService.sendText(
        'RELAY:$pin:${newState ? 1 : 0}',
        newline: '\n',
      );
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
      if (_connectionMedium == ConnectionMedium.bluetooth) {
        await _bluetoothService.sendPwm(_pwmPin, clamped);
      } else {
        await _wifiService.sendPwm(_pwmPin, clamped);
      }
    }
  }

  Future<void> setPwmPercent(int percent) async {
    final val = ((percent.clamp(0, 100) / 100) * 255).round();
    await setPwmValue(val);
  }

  // DAC Actions (True 8-bit Analog Output on ESP32 GPIO 25 / 26)
  void setDacPin(int pin) {
    _dacPin = pin;
    notifyListeners();
  }

  Future<void> setDacValue(int val) async {
    final clamped = val.clamp(0, 255);
    _dacValue = clamped;
    notifyListeners();
    if (isConnected) {
      if (_connectionMedium == ConnectionMedium.bluetooth) {
        await _bluetoothService.sendText(
          'DAC:$_dacPin:$clamped',
          newline: '\n',
        );
      } else {
        await _wifiService.sendDac(_dacPin, clamped);
      }
    }
  }

  // ADC Sensor & Touch Reading Actions
  Future<void> requestAdcRead(int pin) async {
    if (!isConnected) return;
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      await _bluetoothService.sendText('READ:ADC:$pin', newline: '\n');
    } else {
      await _wifiService.requestAdc(pin);
    }
  }

  Future<void> requestTouchRead(int pin) async {
    if (!isConnected) return;
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      await _bluetoothService.sendText('READ:TOUCH:$pin', newline: '\n');
    } else {
      await _wifiService.requestTouch(pin);
    }
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
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      return await _bluetoothService.sendText(
        text.trim(),
        newline: _selectedLineEnding,
      );
    } else {
      return await _wifiService.sendText(
        text.trim(),
        newline: _selectedLineEnding,
      );
    }
  }

  // Character Actions
  Future<bool> sendSingleChar(String char) async {
    if (char.isEmpty) return false;
    if (_connectionMedium == ConnectionMedium.bluetooth) {
      return await _bluetoothService.sendChar(char[0]);
    } else {
      return await _wifiService.sendChar(char[0]);
    }
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
    else if (lower == 'all on' ||
        lower == 'allon' ||
        lower.contains('all on')) {
      _isBuiltinLedOn = true;
      _channelStates.updateAll((key, val) => true);
      cmdToSend = 'ALL_ON';
    }
    // "all off"
    else if (lower == 'all off' ||
        lower == 'alloff' ||
        lower.contains('all off')) {
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

    // Transmit message to active medium (Bluetooth or WiFi)
    return await sendCustomText(cmdToSend);
  }

  // Terminal Logs
  void clearLogs() {
    _messages.clear();
    _messages.add(BluetoothMessage(content: 'Console cleared.', isTx: false));
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
    _wifiMessagesSub?.cancel();
    _wifiStateSub?.cancel();
    _wifiService.dispose();
    super.dispose();
  }
}
