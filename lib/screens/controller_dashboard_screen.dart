import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dialogs/board_pinout_sheet.dart';
import '../dialogs/board_selection_dialog.dart';
import '../dialogs/pin_configuration_dialog.dart';
import '../providers/bluetooth_provider.dart';
import '../src/commons/btn/custom_btn.dart';
import '../theme/app_colors.dart';
import 'esp32_browser_screen.dart';
import '../widgets/char_sender_card.dart';
import '../widgets/led_control_card.dart';
import '../widgets/pwm_control_card.dart';
import '../widgets/rgb_led_control_card.dart';
import '../widgets/sensors_dac_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/text_sender_card.dart';
import '../widgets/voice_control_card.dart';

class ControllerDashboardScreen extends StatelessWidget {
  final VoidCallback onOpenConnect;

  const ControllerDashboardScreen({
    super.key,
    required this.onOpenConnect,
  });

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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.developer_board_rounded,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Arduino/Esp32 Controller',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              StatusBadge(
                isConnected: bt.isConnected,
                isConnecting: bt.isConnecting,
                label: bt.isConnected
                    ? (bt.connectionMedium == ConnectionMedium.wifi ? 'WIFI' : 'BT')
                    : 'OFFLINE',
              ),
              if (bt.isWifiConnected) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.public_rounded, size: 20),
                  tooltip: 'Open ESP32 Web Server',
                  color: AppColors.primaryOrange,
                  onPressed: () => Esp32BrowserScreen.open(
                    context,
                    ip: bt.wifiIp,
                    port: bt.wifiPort,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: 'Select Board',
                color: AppColors.primaryOrange,
                onPressed: () => BoardSelectionDialog.show(context),
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Connected via WiFi: Quick Web Server Banner
              if (bt.isWifiConnected)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withAlpha(90),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.public_rounded,
                        color: Color(0xFF16A34A),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESP32 Web Server Active',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            Text(
                              'http://${bt.wifiIp}:${bt.wifiPort}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CustomBtn(
                        onTap: () => Esp32BrowserScreen.open(
                          context,
                          ip: bt.wifiIp,
                          port: bt.wifiPort,
                        ),
                        text: 'Open Web',
                        prefix: const Icon(Icons.open_in_browser_rounded, size: 14, color: Colors.white),
                        bgColor: const Color(0xFF16A34A),
                        borderColor: const Color(0xFF16A34A),
                        radius: 8,
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              // Connection Status Banner
              if (!bt.isConnected)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightOrange,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryOrange.withAlpha(90),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bt.connectionMedium == ConnectionMedium.wifi
                            ? Icons.wifi_off_rounded
                            : Icons.bluetooth_searching_rounded,
                        color: AppColors.primaryOrange,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              bt.connectionMedium == ConnectionMedium.wifi
                                  ? 'WiFi Not Connected'
                                  : 'Bluetooth Not Connected',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                            Text(
                              bt.connectionMedium == ConnectionMedium.wifi
                                  ? 'Connect to ESP32 WiFi hotspot or local network.'
                                  : 'Connect to Arduino/ESP32 via Bluetooth.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onOpenConnect,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child:
                            const Text('Connect', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF22C55E).withAlpha(80),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        bt.connectionMedium == ConnectionMedium.wifi
                            ? Icons.wifi_rounded
                            : Icons.bluetooth_connected_rounded,
                        color: const Color(0xFF16A34A),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Connected: ${bt.activeConnectionTitle}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Board Selector & Pinout Quick Bar
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bt.selectedBoard.badgeText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => BoardSelectionDialog.show(context),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    bt.selectedBoard.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryText,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down,
                                    size: 18, color: AppColors.primaryOrange),
                              ],
                            ),
                            Text(
                              'LED: GPIO ${bt.builtinLedPin} • ${bt.selectedBoard.hasDac ? "2x DAC • " : ""}${bt.selectedBoard.hasTouch ? "${bt.selectedBoard.touchPins.length} Touch • " : ""}${bt.selectedBoard.pwmPins.length} PWM',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.secondaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, size: 19),
                      tooltip: 'Configure Pins',
                      color: AppColors.primaryOrange,
                      onPressed: () => PinConfigurationDialog.show(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline_rounded, size: 19),
                      tooltip: 'Board Pinout & Specs',
                      color: AppColors.secondaryText,
                      onPressed: () => BoardPinoutSheet.show(context),
                    ),
                  ],
                ),
              ),

              // 1. LED Control Card
              LedControlCard(
                isConnected: bt.isConnected,
                isBuiltinLedOn: bt.isBuiltinLedOn,
                onToggleBuiltin: (val) => bt.setBuiltinLed(val),
                channelStates: bt.channelStates,
                onToggleChannel: (ch) => bt.toggleChannel(ch),
                builtinLedPin: bt.builtinLedPin,
                boardName: bt.selectedBoard.shortName,
                onConfigurePins: () => PinConfigurationDialog.show(context),
              ),

              const SizedBox(height: 16),

              // 2. RGB LED Control Card (4-Pin Non-Addressable R, G, B)
              RgbLedControlCard(
                isConnected: bt.isConnected,
                isRgbOn: bt.isRgbOn,
                red: bt.rgbRed,
                green: bt.rgbGreen,
                blue: bt.rgbBlue,
                redPin: bt.rgbRedPin,
                greenPin: bt.rgbGreenPin,
                bluePin: bt.rgbBluePin,
                isCommonAnode: bt.isCommonAnode,
                isRgbBuiltin: bt.isRgbBuiltin,
                boardHasBuiltinRgb: bt.selectedBoard.builtinRgbPin != null,
                board: bt.selectedBoard,
                onTogglePower: (on) => bt.toggleRgbPower(on),
                onColorChanged: (r, g, b) => bt.setRgbColor(r, g, b),
                onConfigChanged: ({rPin, gPin, bPin, isCommonAnode, isRgbBuiltin}) {
                  bt.updateRgbPins(
                    rPin: rPin,
                    gPin: gPin,
                    bPin: bPin,
                    isCommonAnode: isCommonAnode,
                    isRgbBuiltin: isRgbBuiltin,
                  );
                },
              ),

              const SizedBox(height: 16),

              // 3. PWM Duty Cycle Control Card
              PwmControlCard(
                isConnected: bt.isConnected,
                pwmPin: bt.pwmPin,
                availablePins: bt.pwmAvailablePins,
                onPinChanged: (p) => bt.setPwmPin(p),
                pwmValue: bt.pwmValue,
                onPwmChanged: (val) => bt.setPwmValue(val),
                onPercentPreset: (pct) => bt.setPwmPercent(pct),
              ),

              const SizedBox(height: 16),

              // 3. DAC, ADC & Touch Sensors Card (ESP32 / ESP32-S3 / Arduino)
              SensorsDacCard(
                isConnected: bt.isConnected,
              ),

              const SizedBox(height: 16),

              // 4. Voice Command Controller Card
              VoiceControlCard(
                isConnected: bt.isConnected,
                isListening: bt.isListeningVoice,
                voiceStatus: bt.voiceStatus,
                lastVoiceSpoken: bt.lastVoiceSpoken,
                lastTransmittedCommand: bt.lastTransmittedVoiceCommand,
                onToggleListening: () => bt.toggleVoiceListening(),
                onOpenGoogleVoice: () => bt.openGoogleVoiceDialog(),
                onQuickVoiceCommand: (cmd) => bt.processAndSendVoiceCommand(cmd),
              ),

              const SizedBox(height: 16),

              // 4. Send Character Card (Single byte '1', '0', 'F', 'B', 'L', 'R', etc.)
              CharSenderCard(
                isConnected: bt.isConnected,
                onSendChar: (ch) => bt.sendSingleChar(ch),
              ),

              const SizedBox(height: 16),

              // 4. Send Text String Card
              TextSenderCard(
                isConnected: bt.isConnected,
                onSendText: (txt) => bt.sendCustomText(txt),
                selectedLineEnding: bt.selectedLineEnding,
                onLineEndingChanged: (val) => bt.setLineEnding(val),
                lineEndingOptions: bt.lineEndingOptions,
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
