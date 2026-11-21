import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bluetooth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/char_sender_card.dart';
import '../widgets/led_control_card.dart';
import '../widgets/pwm_control_card.dart';
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
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.memory_rounded,
                      color: AppColors.primaryOrange,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Arduino/Esp32 Controller',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              StatusBadge(
                isConnected: bt.isConnected,
                isConnecting: bt.isConnecting,
                label: bt.connectedDevice?.name ?? 'CONNECTED',
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
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
                      const Icon(
                        Icons.bluetooth_searching_rounded,
                        color: AppColors.primaryOrange,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bluetooth Not Connected',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryOrange,
                              ),
                            ),
                            Text(
                              'Connect to your HC-05 / HC-06 to control hardware.',
                              style: TextStyle(
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
                ),

              // 1. LED Control Card
              LedControlCard(
                isConnected: bt.isConnected,
                isBuiltinLedOn: bt.isBuiltinLedOn,
                onToggleBuiltin: (val) => bt.setBuiltinLed(val),
                channelStates: bt.channelStates,
                onToggleChannel: (ch) => bt.toggleChannel(ch),
              ),

              const SizedBox(height: 16),

              // 2. PWM Duty Cycle Control Card
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

              // 3. Voice Command Controller Card
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
