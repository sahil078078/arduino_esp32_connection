enum WifiProtocol {
  http,
  tcpSocket,
}

enum WifiMode {
  softAp,
  station,
}

class WifiDeviceModel {
  final String ip;
  final int port;
  final WifiMode mode;
  final WifiProtocol protocol;
  final bool isConnected;
  final int latencyMs;
  final String ssid;
  final DateTime? lastConnectedAt;

  const WifiDeviceModel({
    this.ip = '192.168.4.1',
    this.port = 80,
    this.mode = WifiMode.softAp,
    this.protocol = WifiProtocol.http,
    this.isConnected = false,
    this.latencyMs = 0,
    this.ssid = 'ESP32_Controller_AP',
    this.lastConnectedAt,
  });

  String get displayName {
    if (mode == WifiMode.softAp) {
      return 'ESP32 SoftAP ($ip:$port)';
    }
    return 'ESP32 Station ($ip:$port)';
  }

  String get endpointUrl => 'http://$ip:$port';

  WifiDeviceModel copyWith({
    String? ip,
    int? port,
    WifiMode? mode,
    WifiProtocol? protocol,
    bool? isConnected,
    int? latencyMs,
    String? ssid,
    DateTime? lastConnectedAt,
  }) {
    return WifiDeviceModel(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      mode: mode ?? this.mode,
      protocol: protocol ?? this.protocol,
      isConnected: isConnected ?? this.isConnected,
      latencyMs: latencyMs ?? this.latencyMs,
      ssid: ssid ?? this.ssid,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
    );
  }
}
