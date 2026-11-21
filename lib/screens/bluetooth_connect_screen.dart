import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bluetooth_device_model.dart';
import '../providers/bluetooth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/pin_dialog.dart';
import '../widgets/status_badge.dart';

class BluetoothConnectScreen extends StatelessWidget {
  const BluetoothConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bt, child) {
        return Scaffold(
          backgroundColor: AppColors.appBackground,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            scrolledUnderElevation: 1,
            surfaceTintColor: Colors.transparent,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(color: AppColors.border, height: 1),
            ),
            title: const Row(
              children: [
                Icon(Icons.bluetooth_rounded,
                    color: AppColors.primaryOrange, size: 22),
                SizedBox(width: 8),
                Text(
                  'Bluetooth Devices',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              StatusBadge(
                isConnected: bt.isConnected,
                isConnecting: bt.isConnecting,
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // 1. Active Connected Device Card (if connected)
              if (bt.isConnected && bt.connectedDevice != null) ...[
                _buildConnectedCard(context, bt, bt.connectedDevice!),
                const SizedBox(height: 16),
              ],

              // 2. Bluetooth Disabled Alert Banner (If phone Bluetooth is OFF)
              if (!bt.isBluetoothEnabled) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withAlpha(60),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626).withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bluetooth_disabled_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phone Bluetooth is OFF',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Turn ON Bluetooth to scan & connect',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => bt.enableBluetooth(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Turn ON',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 3. Scan Header & Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bluetooth_searching_rounded,
                        color: AppColors.primaryOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scan Arduino Modules',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            bt.isScanning
                                ? 'Scanning for nearby HC-05/06...'
                                : '${bt.discoveredDevices.length} devices discovered',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: bt.isScanning ? null : () => bt.scanDevices(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: bt.isScanning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, size: 16),
                      label: Text(
                        bt.isScanning ? 'Scanning...' : 'Scan',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Discovered Devices List
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Available Arduino & Bluetooth Devices',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (bt.discoveredDevices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.bluetooth_disabled_rounded,
                          size: 36,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No Bluetooth devices found yet',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ensure your HC-05/HC-06 module is powered ON and blinking, then tap Scan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => bt.scanDevices(),
                          child: const Text('Start Scan'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...bt.discoveredDevices.map((device) {
                  return _buildDeviceTile(context, bt, device);
                }),

              const SizedBox(height: 20),

              // 4. HC-05 / HC-06 Connection & Pairing Guide Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: AppColors.primaryOrange),
                        SizedBox(width: 8),
                        Text(
                          'HC-05 & HC-06 Pairing Guide',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Default PIN: Enter "1234" or "0000" when pairing.\n'
                      '• Fast Blinking: Ready to pair and discoverable.\n'
                      '• Slow Blinking (2 sec): Connected successfully.\n'
                      '• Wiring: Arduino TX -> HC-05 RX (via voltage divider) & Arduino RX -> HC-05 TX.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectedCard(
      BuildContext context, BluetoothProvider bt, BluetoothDeviceModel device) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryOrange, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lightOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bluetooth_connected_rounded,
              color: AppColors.primaryOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  device.address,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => bt.disconnectDevice(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.errorRed,
              side: const BorderSide(color: AppColors.errorRed, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            child: const Text('Disconnect', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(
      BuildContext context, BluetoothProvider bt, BluetoothDeviceModel device) {
    final isThisConnected =
        bt.isConnected && bt.connectedDevice?.address == device.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isThisConnected
              ? AppColors.primaryOrange
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isThisConnected
                  ? AppColors.lightOrange
                  : AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.bluetooth_rounded,
              size: 20,
              color: isThisConnected
                  ? AppColors.primaryOrange
                  : AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (device.isPaired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lightOrange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PAIRED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      device.address,
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${device.rssi} dBm',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isThisConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Connected',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryOrange,
                ),
              ),
            )
          else
            ElevatedButton(
              onPressed: bt.isConnecting
                  ? null
                  : () {
                      if (!device.isPaired && device.requiresPin) {
                        showDialog(
                          context: context,
                          builder: (ctx) => PinDialog(
                            device: device,
                            onConnect: (pin) {
                              bt.connectDevice(device, pin: pin);
                            },
                          ),
                        );
                      } else {
                        bt.connectDevice(device);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Connect', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
