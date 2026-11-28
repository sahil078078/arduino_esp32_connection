import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../src/commons/btn/custom_btn.dart';
import '../src/commons/btn/custom_close_btn.dart';
import '../src/helper/app_toasting.dart';
import '../theme/app_colors.dart';

class Esp32WebViewerSheet extends StatefulWidget {
  final String ip;
  final int port;

  const Esp32WebViewerSheet({
    super.key,
    required this.ip,
    required this.port,
  });

  static Future<void> show(BuildContext context, {required String ip, required int port}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Esp32WebViewerSheet(ip: ip, port: port),
    );
  }

  @override
  State<Esp32WebViewerSheet> createState() => _Esp32WebViewerSheetState();
}

class _Esp32WebViewerSheetState extends State<Esp32WebViewerSheet> {
  bool _isLoading = false;
  String? _htmlContent;
  int? _statusCode;
  int? _latencyMs;
  String _activeEndpoint = '/';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEndpoint('/');
  }

  String get _baseUrl => 'http://${widget.ip}:${widget.port}';

  Future<void> _launchInAppBrowser() async {
    final uri = Uri.parse(_baseUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
      if (!launched) {
        // Fallback to external application
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching webview: $e');
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (err) {
        AppToasting.showErrorToast('Could not open browser: $err');
      }
    }
  }

  Future<void> _fetchEndpoint(String path) async {
    setState(() {
      _isLoading = true;
      _activeEndpoint = path;
      _errorMessage = null;
    });

    final sw = Stopwatch()..start();
    try {
      final url = Uri.parse('$_baseUrl$path');
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      sw.stop();

      setState(() {
        _isLoading = false;
        _statusCode = res.statusCode;
        _latencyMs = sw.elapsedMilliseconds;
        _htmlContent = res.body;
      });
    } catch (e) {
      sw.stop();
      setState(() {
        _isLoading = false;
        _statusCode = null;
        _latencyMs = sw.elapsedMilliseconds;
        _errorMessage = e.toString();
        _htmlContent = null;
      });
    }
  }

  void _copyToClipboard() {
    if (_htmlContent != null && _htmlContent!.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _htmlContent!));
      AppToasting.showSuccessToast('HTML code copied to clipboard!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header: Title, IP Badge, and Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.lightOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: AppColors.primaryOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ESP32 Web Server',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$_baseUrl$_activeEndpoint',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.secondaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const CustomCloseBtn(size: 28),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 12),

          // Primary Actions Row: In-App Browser & External Browser
          Row(
            children: [
              Expanded(
                flex: 3,
                child: CustomBtn(
                  onTap: _launchInAppBrowser,
                  text: 'Open In-App Browser',
                  prefix: const Icon(
                    Icons.open_in_browser_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                  bgColor: AppColors.primaryOrange,
                  borderColor: AppColors.primaryOrange,
                  radius: 10,
                  height: 42,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: CustomBtn(
                  onTap: () => _fetchEndpoint(_activeEndpoint),
                  isLoading: _isLoading,
                  text: 'Refresh',
                  prefix: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.primaryOrange,
                    size: 16,
                  ),
                  bgColor: AppColors.lightOrange.withAlpha(120),
                  borderColor: AppColors.primaryOrange,
                  borderWidth: 1,
                  radius: 10,
                  height: 42,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryOrange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick Endpoint Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildEndpointChip('/', 'Root HTML'),
                _buildEndpointChip('/ping', 'Ping API'),
                _buildEndpointChip('/status', 'Status'),
                _buildEndpointChip('/cmd?c=1', 'LED ON'),
                _buildEndpointChip('/cmd?c=0', 'LED OFF'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Status & Response Metadata Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusCode == 200
                          ? const Color(0xFFDCFCE7)
                          : (_statusCode != null
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusCode != null
                          ? 'HTTP $_statusCode ${_statusCode == 200 ? "OK" : ""}'
                          : (_isLoading ? 'CONNECTING...' : 'ERROR'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _statusCode == 200
                            ? const Color(0xFF15803D)
                            : (_statusCode != null
                                ? const Color(0xFFB45309)
                                : const Color(0xFFB91C1C)),
                      ),
                    ),
                  ),
                  if (_latencyMs != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '$_latencyMs ms',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),
              if (_htmlContent != null && _htmlContent!.isNotEmpty)
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      children: const [
                        Icon(Icons.copy_rounded, size: 14, color: AppColors.primaryOrange),
                        SizedBox(width: 4),
                        Text(
                          'Copy HTML',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // HTML Code / Response View
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryOrange,
                        strokeWidth: 2.5,
                      ),
                    )
                  : (_errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFF87171),
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    color: Color(0xFFFCA5A5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: SelectableText(
                            _htmlContent?.isNotEmpty == true
                                ? _htmlContent!
                                : '<!-- Empty Response Received from ESP32 Server -->',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Color(0xFFF8FAFC),
                              height: 1.45,
                            ),
                          ),
                        )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndpointChip(String path, String label) {
    final isSelected = _activeEndpoint == path;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.lightOrange,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.primaryOrange : AppColors.primaryText,
        ),
        side: BorderSide(
          color: isSelected ? AppColors.primaryOrange : AppColors.border,
        ),
        onSelected: (sel) {
          if (sel) _fetchEndpoint(path);
        },
      ),
    );
  }
}
