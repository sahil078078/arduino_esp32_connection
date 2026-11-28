import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'esp32_browser_screen.dart';
import '../models/bluetooth_device_model.dart';
import '../models/wifi_device_model.dart';
import '../providers/bluetooth_provider.dart';
import '../src/commons/btn/custom_btn.dart';
import '../src/commons/custom_drop_down_btn.dart';
import '../src/commons/custom_form_field.dart';
import '../src/helper/app_toasting.dart';
import '../src/helper/app_validator.dart';
import '../theme/app_colors.dart';
import '../widgets/pin_dialog.dart';
import '../widgets/status_badge.dart';

class BluetoothConnectScreen extends StatefulWidget {
  final VoidCallback? onOpenCodeScreen;

  const BluetoothConnectScreen({super.key, this.onOpenCodeScreen});

  @override
  State<BluetoothConnectScreen> createState() => _BluetoothConnectScreenState();
}

class _BluetoothConnectScreenState extends State<BluetoothConnectScreen> {
  final TextEditingController _ipController = TextEditingController(
    text: '192.168.4.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '80',
  );

  WifiMode _wifiMode = WifiMode.softAp;
  WifiProtocol _wifiProtocol = WifiProtocol.http;
  int? _pingResult;
  bool _isPinging = false;
  int _selectedPortPreset = 80;

  static const List<Map<String, dynamic>> _commonPorts = [
    {'port': 80, 'label': 'Port 80 (HTTP WebServer)'},
    {'port': 8080, 'label': 'Port 8080 (TCP Socket / Web)'},
    {'port': 8000, 'label': 'Port 8000 (Alt Web HTTP)'},
    {'port': 23, 'label': 'Port 23 (Telnet / Serial)'},
    {'port': -1, 'label': 'Custom Port (Manual)'},
  ];

  @override
  void initState() {
    super.initState();
    final bt = Provider.of<BluetoothProvider>(context, listen: false);
    if (bt.wifiIp.isNotEmpty) {
      _ipController.text = bt.wifiIp;
      _portController.text = bt.wifiPort.toString();
      _wifiProtocol = bt.wifiProtocol;
      _selectedPortPreset = bt.wifiPort;
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _applyMode(WifiMode mode) {
    setState(() {
      _wifiMode = mode;
      if (mode == WifiMode.softAp) {
        _ipController.text = '192.168.4.1';
        _portController.text = _wifiProtocol == WifiProtocol.http ? '80' : '8080';
        _selectedPortPreset = _wifiProtocol == WifiProtocol.http ? 80 : 8080;
      } else {
        _ipController.text = '192.168.1.184';
        _portController.text = _wifiProtocol == WifiProtocol.http ? '80' : '8080';
        _selectedPortPreset = _wifiProtocol == WifiProtocol.http ? 80 : 8080;
      }
    });
  }

  Future<void> _handleTestPing(BluetoothProvider bt) async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final validation = AppValidator.notEmptyValidator(
      ip,
      'Please enter ESP32 IP address',
    );
    if (validation != null) {
      AppToasting.showErrorToast(validation);
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      AppToasting.showErrorToast('Enter a port between 1 and 65535.');
      return;
    }

    setState(() {
      _isPinging = true;
      _pingResult = null;
    });

    final latency = await bt.testPingWifi(
      ip: ip,
      port: port,
      protocol: _wifiProtocol,
    );
    if (!mounted) return;
    setState(() {
      _isPinging = false;
      _pingResult = latency;
    });

    if (latency != null) {
      AppToasting.showSuccessToast('ESP32 reached! Latency: $latency ms');
    } else {
      AppToasting.showErrorToast('Ping failed. Check IP & WiFi connection.');
    }
  }

  Future<void> _handleWifiConnect(BluetoothProvider bt) async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final validation = AppValidator.notEmptyValidator(
      ip,
      'Please enter ESP32 IP address',
    );
    if (validation != null) {
      AppToasting.showErrorToast(validation);
      return;
    }
    if (port == null || port < 1 || port > 65535) {
      AppToasting.showErrorToast('Enter a port between 1 and 65535.');
      return;
    }

    final ok = await bt.connectWifi(
      ip: ip,
      port: port,
      protocol: _wifiProtocol,
      mode: _wifiMode,
    );

    if (!mounted) return;
    if (ok) {
      AppToasting.showSuccessToast('Connected to ESP32 WiFi ($ip:$port)!');
    } else {
      AppToasting.showErrorToast('Failed to connect to ESP32 at $ip:$port');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bt, child) {
        final isWifi = bt.connectionMedium == ConnectionMedium.wifi;

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
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWifi ? Icons.wifi_rounded : Icons.bluetooth_rounded,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isWifi ? 'ESP32 WiFi Setup' : 'Bluetooth Setup',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            actions: [
              StatusBadge(
                isConnected: bt.isConnected,
                isConnecting: bt.isConnecting,
                label: bt.isConnected
                    ? (isWifi ? 'WIFI' : 'BT')
                    : 'OFFLINE',
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Medium Selector Segment (Bluetooth vs WiFi)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            bt.setConnectionMedium(ConnectionMedium.bluetooth),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: !isWifi
                                ? AppColors.primaryOrange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_rounded,
                                size: 17,
                                color: !isWifi
                                    ? Colors.white
                                    : AppColors.secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bluetooth',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: !isWifi
                                      ? Colors.white
                                      : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            bt.setConnectionMedium(ConnectionMedium.wifi),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isWifi
                                ? AppColors.primaryOrange
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_rounded,
                                size: 17,
                                color: isWifi
                                    ? Colors.white
                                    : AppColors.secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'WiFi (ESP32)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isWifi
                                      ? Colors.white
                                      : AppColors.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content based on Medium
              if (isWifi) ...[
                _buildWifiSection(context, bt),
              ] else ...[
                _buildBluetoothSection(context, bt),
              ],
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // WIFI SECTION WIDGETS
  // ==========================================
  Widget _buildWifiSection(BuildContext context, BluetoothProvider bt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Active WiFi Connection Card (if connected)
        if (bt.isWifiConnected) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF22C55E).withAlpha(90),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.wifi_rounded,
                            color: Color(0xFF16A34A),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Connected via WiFi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            Text(
                              '${bt.wifiIp}:${bt.wifiPort}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    CustomBtn(
                      onTap: () => bt.disconnectWifi(),
                      text: 'Disconnect',
                      bgColor: const Color(0xFFEF4444),
                      borderColor: const Color(0xFFEF4444),
                      radius: 8,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFDCFCE7), height: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Protocol: ${bt.wifiProtocol == WifiProtocol.http ? "HTTP WebServer" : "TCP Socket"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    Text(
                      'Latency: ${bt.wifiLatencyMs} ms',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomBtn(
                  onTap: () => Esp32BrowserScreen.open(
                    context,
                    ip: bt.wifiIp,
                    port: bt.wifiPort,
                  ),
                  text: 'Open ESP32 Web Server (Dedicated Browser Screen)',
                  prefix: const Icon(
                    Icons.public_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  bgColor: const Color(0xFF16A34A),
                  borderColor: const Color(0xFF16A34A),
                  radius: 10,
                  height: 40,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 2. WiFi Configuration & Connection Card
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
              const Text(
                'ESP32 WiFi Network Settings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage TCP, HTTP, IP & Port setup for ESP32 microcontrollers.',
                style: TextStyle(fontSize: 11, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 14),

              // Mode Selector (SoftAP vs Station)
              const Text(
                '1. Network Mode',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('SoftAP Hotspot (192.168.4.1)'),
                    selected: _wifiMode == WifiMode.softAp,
                    selectedColor: AppColors.lightOrange,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: _wifiMode == WifiMode.softAp
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _wifiMode == WifiMode.softAp
                          ? AppColors.primaryOrange
                          : AppColors.primaryText,
                    ),
                    side: BorderSide(
                      color: _wifiMode == WifiMode.softAp
                          ? AppColors.primaryOrange
                          : AppColors.border,
                    ),
                    onSelected: (sel) {
                      if (sel) _applyMode(WifiMode.softAp);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Station (Router IP)'),
                    selected: _wifiMode == WifiMode.station,
                    selectedColor: AppColors.lightOrange,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: _wifiMode == WifiMode.station
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _wifiMode == WifiMode.station
                          ? AppColors.primaryOrange
                          : AppColors.primaryText,
                    ),
                    side: BorderSide(
                      color: _wifiMode == WifiMode.station
                          ? AppColors.primaryOrange
                          : AppColors.border,
                    ),
                    onSelected: (sel) {
                      if (sel) _applyMode(WifiMode.station);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Protocol Selector
              const Text(
                '2. Communication Protocol',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('HTTP WebServer (Port 80)'),
                    selected: _wifiProtocol == WifiProtocol.http,
                    selectedColor: AppColors.lightOrange,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: _wifiProtocol == WifiProtocol.http
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _wifiProtocol == WifiProtocol.http
                          ? AppColors.primaryOrange
                          : AppColors.primaryText,
                    ),
                    side: BorderSide(
                      color: _wifiProtocol == WifiProtocol.http
                          ? AppColors.primaryOrange
                          : AppColors.border,
                    ),
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _wifiProtocol = WifiProtocol.http;
                          _portController.text = '80';
                          _selectedPortPreset = 80;
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('TCP Socket (Port 8080)'),
                    selected: _wifiProtocol == WifiProtocol.tcpSocket,
                    selectedColor: AppColors.lightOrange,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: _wifiProtocol == WifiProtocol.tcpSocket
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _wifiProtocol == WifiProtocol.tcpSocket
                          ? AppColors.primaryOrange
                          : AppColors.primaryText,
                    ),
                    side: BorderSide(
                      color: _wifiProtocol == WifiProtocol.tcpSocket
                          ? AppColors.primaryOrange
                          : AppColors.border,
                    ),
                    onSelected: (sel) {
                      if (sel) {
                        setState(() {
                          _wifiProtocol = WifiProtocol.tcpSocket;
                          _portController.text = '8080';
                          _selectedPortPreset = 8080;
                        });
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 3. Port Preset Dropdown & Direct Port Setting
              const Text(
                '3. Port Setup',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryText),
              ),
              const SizedBox(height: 6),
              CustomDropdownBtn<int>(
                value: _selectedPortPreset,
                btnDecoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                items: _commonPorts.map((item) {
                  return DropdownMenuItem<int>(
                    value: item['port'] as int,
                    child: Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedPortPreset = val;
                      if (val != -1) {
                        _portController.text = val.toString();
                        if (val == 80) _wifiProtocol = WifiProtocol.http;
                        if (val == 8080) _wifiProtocol = WifiProtocol.tcpSocket;
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: 12),

              // IP Address & Port Input Fields
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomFormField(
                      label: 'ESP32 IP Address',
                      controller: _ipController,
                      keyboardType: TextInputType.url,
                      hintText: '192.168.4.1',
                      prefix: const Icon(
                        Icons.lan_rounded,
                        size: 18,
                        color: AppColors.primaryOrange,
                      ),
                      fillColor: AppColors.cardBackground,
                      borderColor: AppColors.border,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomFormField(
                      label: 'Custom Port',
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      hintText: '80',
                      fillColor: AppColors.cardBackground,
                      borderColor: AppColors.border,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Preset IP Quick Chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('192.168.4.1 (SoftAP)'),
                    labelStyle: const TextStyle(fontSize: 10.5),
                    onPressed: () {
                      setState(() {
                        _ipController.text = '192.168.4.1';
                        _portController.text = '80';
                        _selectedPortPreset = 80;
                        _wifiProtocol = WifiProtocol.http;
                        _wifiMode = WifiMode.softAp;
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('192.168.1.184 (Station)'),
                    labelStyle: const TextStyle(fontSize: 10.5),
                    onPressed: () {
                      setState(() {
                        _ipController.text = '192.168.1.184';
                        _wifiMode = WifiMode.station;
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('192.168.1.100'),
                    labelStyle: const TextStyle(fontSize: 10.5),
                    onPressed: () {
                      setState(() {
                        _ipController.text = '192.168.1.100';
                        _wifiMode = WifiMode.station;
                      });
                    },
                  ),
                  ActionChip(
                    label: const Text('Port 8080 (TCP)'),
                    labelStyle: const TextStyle(fontSize: 10.5),
                    onPressed: () {
                      setState(() {
                        _portController.text = '8080';
                        _selectedPortPreset = 8080;
                        _wifiProtocol = WifiProtocol.tcpSocket;
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action Buttons: Test Ping & Connect Button
              Row(
                children: [
                  Expanded(
                    child: CustomBtn(
                      onTap: _isPinging ? null : () => _handleTestPing(bt),
                      isLoading: _isPinging,
                      text: _pingResult != null ? '$_pingResult ms' : 'Test Ping',
                      prefix: const Icon(
                        Icons.network_check_rounded,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      bgColor: Colors.transparent,
                      borderColor: AppColors.primaryOrange,
                      borderWidth: 1.2,
                      radius: 10,
                      height: 42,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomBtn(
                      onTap: () {
                        final ip = _ipController.text.trim();
                        final port = int.tryParse(_portController.text.trim()) ?? 80;
                        Esp32BrowserScreen.open(context, ip: ip, port: port);
                      },
                      text: 'Web Browser',
                      prefix: const Icon(
                        Icons.public_rounded,
                        size: 16,
                        color: AppColors.primaryOrange,
                      ),
                      bgColor: AppColors.lightOrange.withAlpha(120),
                      borderColor: AppColors.primaryOrange,
                      borderWidth: 1,
                      radius: 10,
                      height: 42,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomBtn(
                onTap: bt.isWifiConnecting
                    ? null
                    : () => _handleWifiConnect(bt),
                isLoading: bt.isWifiConnecting,
                text: bt.isWifiConnecting
                    ? 'Connecting to ESP32...'
                    : (bt.isWifiConnected
                          ? 'Reconnect WiFi'
                          : 'Connect via WiFi'),
                prefix: const Icon(
                  Icons.wifi_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                bgColor: AppColors.primaryOrange,
                borderColor: AppColors.primaryOrange,
                radius: 10,
                height: 44,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. Step-by-Step WiFi Instructions Guide Card
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
                  Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.primaryOrange,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'How to Connect ESP32 via WiFi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildGuideStep(
                '1',
                'Go to the "Code" tab and select the "ESP32 WiFi" sketch.',
              ),
              _buildGuideStep(
                '2',
                'Upload the sketch to your ESP32 board using Arduino IDE.',
              ),
              _buildGuideStep(
                '3',
                'On your phone, open Settings > WiFi and connect to "ESP32_Controller_AP" (Password: 12345678).',
              ),
              _buildGuideStep(
                '4',
                'Return here and tap "Connect via WiFi" (Default IP 192.168.4.1).',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: AppColors.lightOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryOrange,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BLUETOOTH SECTION WIDGETS
  // ==========================================
  Widget _buildBluetoothSection(BuildContext context, BluetoothProvider bt) {
    final paired = bt.discoveredDevices.where((d) => d.isPaired).toList();
    final available = bt.discoveredDevices.where((d) => !d.isPaired).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Active Connected Device Card (if connected)
        if (bt.isConnected && bt.connectedDevice != null) ...[
          _buildConnectedCard(context, bt, bt.connectedDevice!),
          const SizedBox(height: 16),
        ],

        // 2. Bluetooth Disabled Alert Banner
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
                        'Turn on Bluetooth to discover and connect to Arduino/ESP32.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F1D1D),
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
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Turn ON', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],

        // 3. Scan Header & Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Available Modules',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  bt.isScanning
                      ? 'Scanning for HC-05 / HC-06 / ESP32...'
                      : '${bt.discoveredDevices.length} devices found',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            CustomBtn(
              onTap: bt.isScanning ? null : () => bt.scanDevices(),
              isLoading: bt.isScanning,
              text: bt.isScanning ? 'Scanning...' : 'Scan',
              prefix: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.white,
              ),
              bgColor: AppColors.primaryOrange,
              borderColor: AppColors.primaryOrange,
              radius: 10,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Paired Devices
        if (paired.isNotEmpty) ...[
          const Text(
            'PAIRED DEVICES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...paired.map((dev) => _buildDeviceCard(context, bt, dev)),
          const SizedBox(height: 16),
        ],

        // Available Devices
        if (available.isNotEmpty) ...[
          const Text(
            'DISCOVERED NEARBY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          ...available.map((dev) => _buildDeviceCard(context, bt, dev)),
        ],

        if (paired.isEmpty && available.isEmpty && !bt.isScanning) ...[
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.bluetooth_searching_rounded,
                    size: 40,
                    color: AppColors.secondaryText,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No Bluetooth Devices Found',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Make sure your HC-05/HC-06 or ESP32 Bluetooth is powered ON and in pairing mode.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => bt.scanDevices(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start Scan'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConnectedCard(
    BuildContext context,
    BluetoothProvider bt,
    BluetoothDeviceModel device,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryOrange.withAlpha(120),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    device.address,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          CustomBtn(
            onTap: () => bt.disconnectDevice(),
            text: 'Disconnect',
            bgColor: const Color(0xFFEF4444),
            borderColor: const Color(0xFFEF4444),
            radius: 8,
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    BluetoothProvider bt,
    BluetoothDeviceModel device,
  ) {
    final isThisConnected =
        bt.isConnected && bt.connectedDevice?.address == device.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isThisConnected ? AppColors.primaryOrange : AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                  color: isThisConnected
                      ? AppColors.primaryOrange
                      : AppColors.secondaryText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    device.address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
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
            CustomBtn(
              onTap: bt.isConnecting
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
              text: 'Connect',
              bgColor: AppColors.primaryOrange,
              borderColor: AppColors.primaryOrange,
              radius: 8,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
