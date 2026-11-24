import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bluetooth_message.dart';
import '../providers/bluetooth_provider.dart';
import '../src/commons/btn/custom_btn.dart';
import '../theme/app_colors.dart';
import '../widgets/status_badge.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  }

  void _send(BluetoothProvider bt) {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      bt.sendCustomText(text);
      _inputController.clear();
      if (bt.autoScroll) _scrollToBottom();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bt, child) {
        if (bt.autoScroll) {
          _scrollToBottom();
        }

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
            title: const Text(
              'Bluetooth Terminal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
                letterSpacing: -0.3,
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => bt.toggleAutoScroll(),
                icon: Icon(
                  bt.autoScroll
                      ? Icons.vertical_align_bottom_rounded
                      : Icons.pause_rounded,
                  size: 20,
                  color: bt.autoScroll
                      ? AppColors.primaryOrange
                      : AppColors.secondaryText,
                ),
                tooltip: bt.autoScroll
                    ? 'Auto-scroll ON'
                    : 'Auto-scroll Paused',
              ),
              IconButton(
                onPressed: () => bt.clearLogs(),
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                tooltip: 'Clear Output',
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              // Top Status Bar
              Container(
                color: AppColors.cardBackground,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bluetooth_rounded,
                            size: 16, color: AppColors.primaryOrange),
                        const SizedBox(width: 6),
                        Text(
                          bt.connectedDevice?.name ?? 'No Device Connected',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryText,
                          ),
                        ),
                      ],
                    ),
                    StatusBadge(
                      isConnected: bt.isConnected,
                      isConnecting: bt.isConnecting,
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),

              // Terminal Output Area
              Expanded(
                child: Container(
                  color: AppColors.cardBackground,
                  child: bt.messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Terminal ready. Data sent or received will appear here.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          itemCount: bt.messages.length,
                          itemBuilder: (context, index) {
                            final msg = bt.messages[index];
                            return _buildMessageRow(msg);
                          },
                        ),
                ),
              ),

              const Divider(color: AppColors.border, height: 1),

              // Bottom Input Bar
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: AppColors.cardBackground,
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          focusNode: _focusNode,
                          enabled: bt.isConnected,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            color: AppColors.primaryText,
                          ),
                          decoration: InputDecoration(
                            hintText: bt.isConnected
                                ? 'Type message or command...'
                                : 'Connect Bluetooth to send...',
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            filled: true,
                            fillColor: AppColors.surfaceMuted,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: (_) => _send(bt),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CustomBtn(
                        onTap: bt.isConnected ? () => _send(bt) : null,
                        text: 'Send',
                        suffix: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                        bgColor: AppColors.primaryOrange,
                        borderColor: AppColors.primaryOrange,
                        radius: 10,
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageRow(BluetoothMessage msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            msg.formattedTime,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: msg.isTx ? AppColors.lightOrange : AppColors.lightGreen,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              msg.isTx ? 'TX' : 'RX',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: msg.isTx
                    ? AppColors.primaryOrange
                    : AppColors.successGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              msg.content,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: AppColors.primaryText,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
