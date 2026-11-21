class BluetoothMessage {
  final String content;
  final DateTime timestamp;
  final bool isTx;
  final bool isChar;

  BluetoothMessage({
    required this.content,
    required this.isTx,
    this.isChar = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = (timestamp.millisecond ~/ 10).toString().padLeft(2, '0');
    return '$h:$m:$s.$ms';
  }
}
