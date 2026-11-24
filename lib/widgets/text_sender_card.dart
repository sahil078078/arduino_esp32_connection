import 'package:flutter/material.dart';
import '../src/commons/btn/custom_btn.dart';
import '../src/commons/custom_drop_down_btn.dart';
import '../theme/app_colors.dart';

class TextSenderCard extends StatefulWidget {
  final bool isConnected;
  final ValueChanged<String> onSendText;
  final String selectedLineEnding;
  final ValueChanged<String> onLineEndingChanged;
  final List<String> lineEndingOptions;

  const TextSenderCard({
    super.key,
    required this.isConnected,
    required this.onSendText,
    required this.selectedLineEnding,
    required this.onLineEndingChanged,
    required this.lineEndingOptions,
  });

  @override
  State<TextSenderCard> createState() => _TextSenderCardState();
}

class _TextSenderCardState extends State<TextSenderCard> {
  final TextEditingController _textController = TextEditingController();

  final List<String> _quickMacros = ['PING', 'STATUS', 'START', 'STOP', 'RESET'];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendText(text);
      _textController.clear();
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
          // Header & Line Ending Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.text_fields_rounded,
                        size: 20,
                        color: AppColors.primaryOrange,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send String / Command',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                          ),
                          Text(
                            'Full text string transmission',
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
              // Line Ending Selector
              CustomDropdownBtn<String>(
                value: widget.selectedLineEnding == '\r\n'
                    ? r'\r\n (CRLF)'
                    : widget.selectedLineEnding.isEmpty
                        ? 'None'
                        : r'\n (LF)',
                btnDecoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                icon: const Icon(Icons.arrow_drop_down,
                    color: AppColors.secondaryText, size: 18),
                items: widget.lineEndingOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryText,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) widget.onLineEndingChanged(val);
                },
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 14),

          // Text Field & Primary Orange Send Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: widget.isConnected,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.isConnected
                        ? 'Type command (e.g. HELLO, SPEED:100)...'
                        : 'Connect Bluetooth to send text...',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: AppColors.secondaryText,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              CustomBtn(
                onTap: widget.isConnected ? _submit : null,
                text: 'Send',
                suffix: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                bgColor: AppColors.primaryOrange,
                borderColor: AppColors.primaryOrange,
                radius: 10,
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Macros
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _quickMacros.map((macro) {
              return InkWell(
                onTap: widget.isConnected ? () => widget.onSendText(macro) : null,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    macro,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: AppColors.primaryText,
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
