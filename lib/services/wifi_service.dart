import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/bluetooth_message.dart';
import '../models/wifi_device_model.dart';

abstract class WifiService {
  bool get isConnected;
  bool get isConnecting;
  String get ip;
  int get port;
  int get latencyMs;
  WifiProtocol get protocol;
  WifiDeviceModel get currentDevice;

  Stream<BluetoothMessage> get messagesStream;
  Stream<bool> get connectionStateStream;

  Future<bool> connect({
    required String ip,
    required int port,
    WifiProtocol protocol = WifiProtocol.http,
    WifiMode mode = WifiMode.softAp,
  });

  Future<void> disconnect();
  Future<int?> testPing({required String ip, required int port});
  Future<bool> sendChar(String char);
  Future<bool> sendText(String text, {String newline = '\n'});
  Future<bool> sendPwm(int pin, int value);
  Future<bool> sendDac(int pin, int value);
  Future<bool> requestAdc(int pin);
  Future<bool> requestTouch(int pin);
  void dispose();
}

class DefaultWifiService implements WifiService {
  bool _isConnected = false;
  bool _isConnecting = false;
  String _ip = '192.168.4.1';
  int _port = 80;
  int _latencyMs = 0;
  WifiProtocol _protocol = WifiProtocol.http;
  WifiMode _mode = WifiMode.softAp;

  Socket? _tcpSocket;
  StreamSubscription<String>? _socketSub;

  final StreamController<BluetoothMessage> _messagesController =
      StreamController<BluetoothMessage>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  @override
  bool get isConnected => _isConnected;

  @override
  bool get isConnecting => _isConnecting;

  @override
  String get ip => _ip;

  @override
  int get port => _port;

  @override
  int get latencyMs => _latencyMs;

  @override
  WifiProtocol get protocol => _protocol;

  @override
  WifiDeviceModel get currentDevice => WifiDeviceModel(
        ip: _ip,
        port: _port,
        mode: _mode,
        protocol: _protocol,
        isConnected: _isConnected,
        latencyMs: _latencyMs,
      );

  @override
  Stream<BluetoothMessage> get messagesStream => _messagesController.stream;

  @override
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  final http.Client _httpClient = http.Client();

  @override
  Future<int?> testPing({required String ip, required int port}) async {
    final sw = Stopwatch()..start();
    try {
      final uri = Uri.parse('http://$ip:$port/ping');
      final res = await _httpClient.get(uri).timeout(
            const Duration(seconds: 3),
          );
      sw.stop();
      if (res.statusCode == 200 || res.statusCode == 204) {
        _latencyMs = sw.elapsedMilliseconds;
        return _latencyMs;
      }
      return null;
    } catch (_) {
      sw.stop();
      // Also try raw socket probe if HTTP endpoint wasn't reached
      try {
        final socket = await Socket.connect(
          ip,
          port,
          timeout: const Duration(seconds: 2),
        );
        socket.destroy();
        _latencyMs = sw.elapsedMilliseconds;
        return _latencyMs;
      } catch (e) {
        return null;
      }
    }
  }

  @override
  Future<bool> connect({
    required String ip,
    required int port,
    WifiProtocol protocol = WifiProtocol.http,
    WifiMode mode = WifiMode.softAp,
  }) async {
    _isConnecting = true;
    _connectionStateController.add(false);

    _ip = ip.trim();
    _port = port;
    _protocol = protocol;
    _mode = mode;

    try {
      if (protocol == WifiProtocol.tcpSocket) {
        // TCP Raw Socket Mode
        await _connectTcpSocket();
      } else {
        // HTTP WebServer Mode: Ping verification
        final pingLatency = await testPing(ip: _ip, port: _port);
        if (pingLatency == null) {
          // If ping path not implemented, try root /
          final sw = Stopwatch()..start();
          final rootUri = Uri.parse('http://$_ip:$_port/');
          final res = await _httpClient.get(rootUri).timeout(
                const Duration(seconds: 3),
              );
          sw.stop();
          if (res.statusCode == 200 || res.statusCode == 404) {
            _latencyMs = sw.elapsedMilliseconds;
          } else {
            throw Exception('ESP32 returned status ${res.statusCode}');
          }
        }
      }

      _isConnected = true;
      _isConnecting = false;
      _connectionStateController.add(true);

      _messagesController.add(
        BluetoothMessage(
          content: 'CONNECTED: ESP32 WiFi at $_ip:$_port ($_latencyMs ms)',
          isTx: false,
        ),
      );
      return true;
    } catch (e) {
      debugPrint('WiFi connection error: $e');
      _isConnected = false;
      _isConnecting = false;
      _connectionStateController.add(false);

      _messagesController.add(
        BluetoothMessage(
          content: 'ERROR: Unable to connect to ESP32 at $_ip:$_port ($e)',
          isTx: false,
        ),
      );
      return false;
    }
  }

  Future<void> _connectTcpSocket() async {
    await _disconnectTcp();
    final socket = await Socket.connect(
      _ip,
      _port,
      timeout: const Duration(seconds: 4),
    );
    _tcpSocket = socket;

    _socketSub = socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
      (line) {
        if (line.isNotEmpty) {
          _messagesController.add(
            BluetoothMessage(content: line, isTx: false),
          );
        }
      },
      onError: (err) {
        debugPrint('TCP socket error: $err');
        disconnect();
      },
      onDone: () {
        debugPrint('TCP socket closed');
        disconnect();
      },
      cancelOnError: true,
    );
  }

  Future<void> _disconnectTcp() async {
    await _socketSub?.cancel();
    _socketSub = null;
    _tcpSocket?.destroy();
    _tcpSocket = null;
  }

  @override
  Future<void> disconnect() async {
    await _disconnectTcp();
    _isConnected = false;
    _isConnecting = false;
    _connectionStateController.add(false);

    _messagesController.add(
      BluetoothMessage(
        content: 'DISCONNECTED: ESP32 WiFi ($_ip:$_port)',
        isTx: false,
      ),
    );
  }

  @override
  Future<bool> sendChar(String char) async {
    if (!_isConnected) return false;

    _messagesController.add(
      BluetoothMessage(content: char, isTx: true, isChar: true),
    );

    if (_protocol == WifiProtocol.tcpSocket && _tcpSocket != null) {
      _tcpSocket!.write('$char\n');
      return true;
    }

    try {
      final uri = Uri.parse('http://$_ip:$_port/cmd?c=${Uri.encodeComponent(char)}');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 2));
      _handleHttpResponse(res);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP sendChar error: $e');
      return false;
    }
  }

  @override
  Future<bool> sendText(String text, {String newline = '\n'}) async {
    if (!_isConnected) return false;

    _messagesController.add(
      BluetoothMessage(content: text, isTx: true, isChar: false),
    );

    if (_protocol == WifiProtocol.tcpSocket && _tcpSocket != null) {
      _tcpSocket!.write('$text$newline');
      return true;
    }

    try {
      final uri = Uri.parse('http://$_ip:$_port/text?msg=${Uri.encodeComponent(text)}');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 2));
      _handleHttpResponse(res);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP sendText error: $e');
      return false;
    }
  }

  @override
  Future<bool> sendPwm(int pin, int value) async {
    if (!_isConnected) return false;

    final cmd = 'PWM:$pin:$value';
    _messagesController.add(
      BluetoothMessage(content: cmd, isTx: true, isChar: false),
    );

    if (_protocol == WifiProtocol.tcpSocket && _tcpSocket != null) {
      _tcpSocket!.write('$cmd\n');
      return true;
    }

    try {
      final uri = Uri.parse('http://$_ip:$_port/pwm?pin=$pin&val=$value');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 2));
      _handleHttpResponse(res);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP sendPwm error: $e');
      return false;
    }
  }

  @override
  Future<bool> sendDac(int pin, int value) async {
    if (!_isConnected) return false;

    final cmd = 'DAC:$pin:$value';
    _messagesController.add(
      BluetoothMessage(content: cmd, isTx: true, isChar: false),
    );

    if (_protocol == WifiProtocol.tcpSocket && _tcpSocket != null) {
      _tcpSocket!.write('$cmd\n');
      return true;
    }

    try {
      final uri = Uri.parse('http://$_ip:$_port/dac?pin=$pin&val=$value');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 2));
      _handleHttpResponse(res);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP sendDac error: $e');
      return false;
    }
  }

  @override
  Future<bool> requestAdc(int pin) async {
    if (!_isConnected) return false;

    final cmd = 'READ:ADC:$pin';
    _messagesController.add(
      BluetoothMessage(content: cmd, isTx: true, isChar: false),
    );

    if (_protocol == WifiProtocol.tcpSocket && _tcpSocket != null) {
      _tcpSocket!.write('$cmd\n');
      return true;
    }

    try {
      final uri = Uri.parse('http://$_ip:$_port/adc?pin=$pin');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 2));
      _handleHttpResponse(res);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP requestAdc error: $e');
      return false;
    }
  }

  @override
  Future<bool> requestTouch(int pin) async {
    if (!_isConnected) return false;

    final cmd = 'READ:TOUCH:$pin';
    _messagesController.add(
      BluetoothMessage(content: cmd, isTx: true, isChar: false),
    );

    if (_protocol == WifiProtocol.tcpSocket && _tcpSocket != null) {
      _tcpSocket!.write('$cmd\n');
      return true;
    }

    try {
      final uri = Uri.parse('http://$_ip:$_port/touch?pin=$pin');
      final res = await _httpClient.get(uri).timeout(const Duration(seconds: 2));
      _handleHttpResponse(res);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('HTTP requestTouch error: $e');
      return false;
    }
  }

  void _handleHttpResponse(http.Response response) {
    if (response.body.isNotEmpty) {
      final body = response.body.trim();
      _messagesController.add(
        BluetoothMessage(content: body, isTx: false),
      );
    }
  }

  @override
  void dispose() {
    _disconnectTcp();
    _httpClient.close();
    _messagesController.close();
    _connectionStateController.close();
  }
}
