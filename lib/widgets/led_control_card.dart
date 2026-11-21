import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LedControlCard extends StatelessWidget {
  final bool isConnected;
  final bool isBuiltinLedOn;
  final ValueChanged<bool> onToggleBuiltin;
  final Map<String, bool> channelStates;
  final ValueChanged<String> onToggleChannel;

  const LedControlCard({
    super.key,
    required this.isConnected,
    required this.isBuiltinLedOn,
    required this.onToggleBuiltin,
    required this.channelStates,
    required this.onToggleChannel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBuiltinLedOn
              ? AppColors.primaryOrange.withAlpha(90)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isBuiltinLedOn
                          ? AppColors.lightOrange
                          : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      size: 20,
                      color: isBuiltinLedOn
                          ? AppColors.primaryOrange
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LED & Relay Control',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      Text(
                        'Transmits "1" (ON) and "0" (OFF)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: isBuiltinLedOn,
                  activeColor: Colors.white,
                  activeTrackColor: AppColors.primaryOrange,
                  inactiveThumbColor: AppColors.secondaryText,
                  inactiveTrackColor: AppColors.border,
                  onChanged: isConnected ? onToggleBuiltin : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Primary Built-in LED Card
          InkWell(
            onTap: isConnected ? () => onToggleBuiltin(!isBuiltinLedOn) : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isBuiltinLedOn
                    ? AppColors.lightOrange.withAlpha(160)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isBuiltinLedOn
                      ? AppColors.primaryOrange
                      : AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isBuiltinLedOn
                        ? Icons.lightbulb_rounded
                        : Icons.lightbulb_outline_rounded,
                    size: 28,
                    color: isBuiltinLedOn
                        ? AppColors.primaryOrange
                        : AppColors.secondaryText,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Arduino Built-in LED (Pin 13)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                        Text(
                          isBuiltinLedOn
                              ? 'Status: HIGH [Char "1" Sent]'
                              : 'Status: LOW [Char "0" Sent]',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isBuiltinLedOn
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isBuiltinLedOn
                                ? AppColors.primaryOrange
                                : AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isBuiltinLedOn
                          ? AppColors.primaryOrange
                          : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isBuiltinLedOn ? 'ON' : 'OFF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isBuiltinLedOn
                            ? Colors.white
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Multi-Channel Control Grid
          const Text(
            'Multi-Channel Hardware Outputs',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.2,
            children: channelStates.entries.map((entry) {
              final isChannelOn = entry.value;
              final channelTitle = entry.key;

              return InkWell(
                onTap: isConnected ? () => onToggleChannel(channelTitle) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isChannelOn
                        ? AppColors.lightOrange
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isChannelOn
                          ? AppColors.primaryOrange
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        channelTitle.contains('Relay')
                            ? Icons.power_rounded
                            : Icons.circle,
                        size: 14,
                        color: isChannelOn
                            ? AppColors.primaryOrange
                            : AppColors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              channelTitle,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isChannelOn ? 'Active (ON)' : 'Inactive (OFF)',
                              style: TextStyle(
                                fontSize: 10,
                                color: isChannelOn
                                    ? AppColors.primaryOrange
                                    : AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
