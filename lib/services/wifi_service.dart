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
  Future<int?> testPing({
    required String ip,
    required int port,
    WifiProtocol protocol = WifiProtocol.http,
  });
  Future<bool> sendChar(String char);
  Future<bool> sendText(String text, {String newline = '\n'});
  Future<bool> sendPwm(int pin, int value);
  Future<bool> sendDac(int pin, int value);
  Future<bool> requestAdc(int pin);
  Future<bool> requestTouch(int pin);
  void dispose();
}

class DefaultWifiService implements WifiService {
  DefaultWifiService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

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

  final http.Client _httpClient;

  @override
  Future<int?> testPing({
    required String ip,
    required int port,
    WifiProtocol protocol = WifiProtocol.http,
  }) async {
    final sw = Stopwatch()..start();
    try {
      if (protocol == WifiProtocol.tcpSocket) {
        final socket = await Socket.connect(
          ip.trim(),
          port,
          timeout: const Duration(seconds: 2),
        );
        socket.destroy();
      } else {
        var response = await _httpClient
            .get(Uri.http(_authority(ip, port), '/ping'))
            .timeout(const Duration(seconds: 3));
        if (response.statusCode == 404) {
          response = await _httpClient
              .get(Uri.http(_authority(ip, port), '/'))
              .timeout(const Duration(seconds: 3));
        }
        if (!_isSuccessful(response)) return null;
      }
      return sw.elapsedMilliseconds;
    } catch (error) {
      debugPrint('WiFi probe failed: $error');
      return null;
    }
  }

  String _authority(String ip, int port) {
    final host = ip.trim();
    return host.contains(':') && !host.startsWith('[')
        ? '[$host]:$port'
        : '$host:$port';
  }

  bool _isSuccessful(http.Response response) =>
      response.statusCode >= 200 && response.statusCode < 300;

  @override
  Future<bool> connect({
    required String ip,
    required int port,
    WifiProtocol protocol = WifiProtocol.http,
    WifiMode mode = WifiMode.softAp,
  }) async {
    if (_isConnecting) return false;
    _isConnecting = true;
    _isConnected = false;
    _latencyMs = 0;
    _connectionStateController.add(false);

    _ip = ip.trim();
    _port = port;
    _protocol = protocol;
    _mode = mode;

    try {
      if (protocol == WifiProtocol.tcpSocket) {
        await _connectTcpSocket();
      } else {
        await _disconnectTcp();
        final latency = await testPing(ip: _ip, port: _port);
        if (latency == null) {
          throw StateError('No successful HTTP response from /ping or /');
        }
        _latencyMs = latency;
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
    final sw = Stopwatch()..start();
    final socket = await Socket.connect(
      _ip,
      _port,
      timeout: const Duration(seconds: 4),
    );
    _latencyMs = sw.elapsedMilliseconds;
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
  Future<bool> sendChar(String char) =>
      _send(char, '/cmd', {'c': char}, write: true, isChar: true);

  @override
  Future<bool> sendText(String text, {String newline = '\n'}) =>
      _send(text, '/text', {'t': text}, write: true, newline: newline);

  @override
  Future<bool> sendPwm(int pin, int value) => _send('PWM:$pin:$value', '/pwm', {
    'pin': '$pin',
    'val': '$value',
  }, write: true);

  @override
  Future<bool> sendDac(int pin, int value) => _send('DAC:$pin:$value', '/dac', {
    'pin': '$pin',
    'val': '$value',
  }, write: true);

  @override
  Future<bool> requestAdc(int pin) =>
      _send('READ:ADC:$pin', '/adc', {'pin': '$pin'});

  @override
  Future<bool> requestTouch(int pin) =>
      _send('READ:TOUCH:$pin', '/touch', {'pin': '$pin'});

  Future<bool> _send(
    String command,
    String path,
    Map<String, String> arguments, {
    bool write = false,
    bool isChar = false,
    String newline = '\n',
  }) async {
    if (!_isConnected) return false;

    _messagesController.add(
      BluetoothMessage(content: command, isTx: true, isChar: isChar),
    );
    try {
      if (_protocol == WifiProtocol.tcpSocket) {
        final socket = _tcpSocket;
        if (socket == null) return false;
        socket.write('$command$newline');
        return true;
      }

      final uri = Uri.http(_authority(_ip, _port), path);
      const timeout = Duration(seconds: 3);
      http.Response response;
      if (write) {
        response = await _httpClient
            .post(uri, body: arguments)
            .timeout(timeout);
        // Older sketches only register GET handlers.
        if (response.statusCode == 404 || response.statusCode == 405) {
          response = await _httpClient
              .get(uri.replace(queryParameters: arguments))
              .timeout(timeout);
        }
      } else {
        response = await _httpClient
            .get(uri.replace(queryParameters: arguments))
            .timeout(timeout);
      }
      _handleHttpResponse(response);
      return _isSuccessful(response);
    } catch (error) {
      debugPrint('WiFi command $path failed: $error');
      if (!_messagesController.isClosed) {
        _messagesController.add(
          BluetoothMessage(content: 'ERROR: $path ($error)', isTx: false),
        );
      }
      return false;
    }
  }

  void _handleHttpResponse(http.Response response) {
    if (!_messagesController.isClosed && response.body.trim().isNotEmpty) {
      final body = response.body.trim();
      _messagesController.add(BluetoothMessage(content: body, isTx: false));
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
