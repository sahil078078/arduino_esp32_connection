class BluetoothDeviceModel {
  final String name;
  final String address;
  final int rssi; // Signal strength in dBm (e.g. -60)
  final bool isPaired;
  bool isConnected;
  final bool requiresPin;
  final String defaultPin;

  BluetoothDeviceModel({
    required this.name,
    required this.address,
    this.rssi = -65,
    this.isPaired = false,
    this.isConnected = false,
    this.requiresPin = true,
    this.defaultPin = '1234',
  });

  /// 1 to 4 signal strength bars
  int get signalStrengthBars {
    if (rssi >= -60) return 4;
    if (rssi >= -75) return 3;
    if (rssi >= -85) return 2;
    return 1;
  }

  BluetoothDeviceModel copyWith({
    String? name,
    String? address,
    int? rssi,
    bool? isPaired,
    bool? isConnected,
    bool? requiresPin,
    String? defaultPin,
  }) {
    return BluetoothDeviceModel(
      name: name ?? this.name,
      address: address ?? this.address,
      rssi: rssi ?? this.rssi,
      isPaired: isPaired ?? this.isPaired,
      isConnected: isConnected ?? this.isConnected,
      requiresPin: requiresPin ?? this.requiresPin,
      defaultPin: defaultPin ?? this.defaultPin,
    );
  }
}
