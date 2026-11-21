import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CharSenderCard extends StatefulWidget {
  final bool isConnected;
  final ValueChanged<String> onSendChar;

  const CharSenderCard({
    super.key,
    required this.isConnected,
    required this.onSendChar,
  });

  @override
  State<CharSenderCard> createState() => _CharSenderCardState();
}

class _CharSenderCardState extends State<CharSenderCard> {
  final TextEditingController _singleCharController = TextEditingController();

  final List<String> _quickChars = ['0', '1', 'A', 'B', 'C', 'D', 'X', 'Y', 'Z'];
  final List<Map<String, dynamic>> _motionChars = [
    {'char': 'F', 'label': 'Forward', 'icon': Icons.arrow_upward_rounded},
    {'char': 'L', 'label': 'Left', 'icon': Icons.arrow_back_rounded},
    {'char': 'S', 'label': 'Stop', 'icon': Icons.stop_rounded},
    {'char': 'R', 'label': 'Right', 'icon': Icons.arrow_forward_rounded},
    {'char': 'B', 'label': 'Reverse', 'icon': Icons.arrow_downward_rounded},
  ];

  @override
  void dispose() {
    _singleCharController.dispose();
    super.dispose();
  }

  void _submitCustomChar() {
    final text = _singleCharController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendChar(text[0]);
      _singleCharController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightOrange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.keyboard_outlined,
                  size: 20,
                  color: AppColors.primaryOrange,
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send Character (1 Byte)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  Text(
                    'Instant single ASCII byte transmission',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Custom single char input row
          Row(
            children: [
              SizedBox(
                width: 65,
                child: TextField(
                  controller: _singleCharController,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  enabled: widget.isConnected,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: AppColors.primaryText,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'A',
                    hintStyle: const TextStyle(color: AppColors.mutedText),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onSubmitted: (_) => _submitCustomChar(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.isConnected ? _submitCustomChar : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Send Char'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Quick Character Grid: '0', '1', 'A', 'B', 'C', 'D'
          const Text(
            'Quick Character Keys',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickChars.map((ch) {
              return InkWell(
                onTap: widget.isConnected ? () => widget.onSendChar(ch) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 44,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    ch,
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Direction / Bot Navigation Keys
          const Text(
            'Robot Navigation Keys (F, B, L, R, S)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _motionChars.map((m) {
              final String ch = m['char'] as String;
              final String label = m['label'] as String;
              final IconData icon = m['icon'] as IconData;
              final isStop = ch == 'S';

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: widget.isConnected ? () => widget.onSendChar(ch) : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isStop
                            ? AppColors.lightRed
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isStop
                              ? AppColors.errorRed.withAlpha(90)
                              : AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: isStop
                                ? AppColors.errorRed
                                : AppColors.primaryOrange,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ch,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: isStop
                                  ? AppColors.errorRed
                                  : AppColors.primaryText,
                            ),
                          ),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 9,
                              color: AppColors.secondaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
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
