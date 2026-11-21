import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class VoiceControlCard extends StatelessWidget {
  final bool isConnected;
  final bool isListening;
  final String voiceStatus;
  final String lastVoiceSpoken;
  final String lastTransmittedCommand;
  final VoidCallback onToggleListening;
  final VoidCallback? onOpenGoogleVoice;
  final ValueChanged<String> onQuickVoiceCommand;

  const VoiceControlCard({
    super.key,
    required this.isConnected,
    required this.isListening,
    required this.voiceStatus,
    required this.lastVoiceSpoken,
    required this.lastTransmittedCommand,
    required this.onToggleListening,
    this.onOpenGoogleVoice,
    required this.onQuickVoiceCommand,
  });

  static const List<Map<String, String>> _quickVoicePresets = [
    {'label': '1 (ONE)', 'icon': '1️⃣', 'cmd': 'one'},
    {'label': '0 (ZERO)', 'icon': '0️⃣', 'cmd': 'zero'},
    {'label': 'ON', 'icon': '💡', 'cmd': 'on'},
    {'label': 'OFF', 'icon': '🌑', 'cmd': 'off'},
    {'label': 'LIGHT ON', 'icon': '✨', 'cmd': 'light on'},
    {'label': 'LED ON', 'icon': '🟢', 'cmd': 'ledon'},
    {'label': 'ALL ON', 'icon': '⚡', 'cmd': 'all on'},
    {'label': 'ALL OFF', 'icon': '💤', 'cmd': 'all off'},
    {'label': 'FORWARD', 'icon': '▲', 'cmd': 'forward'},
    {'label': 'BACKWARD', 'icon': '▼', 'cmd': 'backward'},
    {'label': 'LEFT', 'icon': '◄', 'cmd': 'left'},
    {'label': 'RIGHT', 'icon': '►', 'cmd': 'right'},
    {'label': 'STOP', 'icon': '■', 'cmd': 'stop'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isListening
              ? AppColors.primaryOrange
              : AppColors.border,
          width: isListening ? 1.5 : 1,
        ),
        boxShadow: isListening
            ? [
                BoxShadow(
                  color: AppColors.primaryOrange.withAlpha(40),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon, Title & Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isListening
                            ? AppColors.primaryOrange
                            : AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.record_voice_over_rounded,
                        size: 20,
                        color: isListening
                            ? Colors.white
                            : AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Voice Command Control',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Speak ANY custom command — sent live to Arduino',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isListening
                      ? AppColors.primaryOrange.withAlpha(20)
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isListening
                        ? AppColors.primaryOrange
                        : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening
                            ? AppColors.primaryOrange
                            : AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isListening ? 'LISTENING...' : 'MIC READY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isListening
                            ? AppColors.primaryOrange
                            : AppColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Microphone Center Action & Transcript Display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.appBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              children: [
                // Animated Microphone Button
                GestureDetector(
                  onTap: isConnected ? onToggleListening : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isListening
                          ? AppColors.primaryOrange
                          : (isConnected
                              ? AppColors.cardBackground
                              : AppColors.surfaceMuted),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isConnected
                            ? AppColors.primaryOrange
                            : AppColors.border,
                        width: isListening ? 3 : 2,
                      ),
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: AppColors.primaryOrange.withAlpha(90),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withAlpha(8),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                    ),
                    child: Icon(
                      isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                      color: isListening
                          ? Colors.white
                          : (isConnected
                              ? AppColors.primaryOrange
                              : AppColors.secondaryText),
                      size: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Spoken Text / Status Label
                Text(
                  isListening
                      ? 'Listening... Speak now!'
                      : (lastVoiceSpoken.isNotEmpty
                          ? 'Heard: "$lastVoiceSpoken"'
                          : (isConnected
                              ? 'Tap microphone & speak command'
                              : 'Connect Bluetooth to use Voice Commands')),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isListening
                        ? FontWeight.w700
                        : (lastVoiceSpoken.isNotEmpty
                            ? FontWeight.w600
                            : FontWeight.w400),
                    color: isListening
                        ? AppColors.primaryOrange
                        : (lastVoiceSpoken.isNotEmpty
                            ? AppColors.primaryText
                            : AppColors.secondaryText),
                  ),
                ),

                // Transmitted String Confirmation
                if (lastTransmittedCommand.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.send_rounded,
                            size: 12, color: AppColors.primaryOrange),
                        const SizedBox(width: 6),
                        Text(
                          'Arduino RX: "$lastTransmittedCommand"',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 100% Accurate Google Voice AI Button
                if (onOpenGoogleVoice != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isConnected ? onOpenGoogleVoice : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryOrange,
                      side: const BorderSide(color: AppColors.primaryOrange, width: 1.2),
                      backgroundColor: AppColors.cardBackground,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.mic, size: 16, color: AppColors.primaryOrange),
                    label: const Text(
                      'Google Voice Input (100% Accurate AI)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Quick Keyword Preset Chips
          const Text(
            'Quick Tap Presets (or speak any custom command):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickVoicePresets.map((preset) {
              return ActionChip(
                backgroundColor: AppColors.cardBackground,
                side: const BorderSide(color: AppColors.border, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                avatar: Text(
                  preset['icon']!,
                  style: const TextStyle(fontSize: 12),
                ),
                label: Text(
                  preset['label']!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                onPressed: isConnected
                    ? () => onQuickVoiceCommand(preset['cmd']!)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
