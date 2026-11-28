import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../src/commons/btn/custom_btn.dart';
import '../src/helper/app_toasting.dart';
import '../theme/app_colors.dart';

class Esp32BrowserScreen extends StatefulWidget {
  final String ip;
  final int port;

  const Esp32BrowserScreen({
    super.key,
    required this.ip,
    required this.port,
  });

  static Future<void> open(BuildContext context, {required String ip, required int port}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Esp32BrowserScreen(ip: ip, port: port),
      ),
    );
  }

  @override
  State<Esp32BrowserScreen> createState() => _Esp32BrowserScreenState();
}

class _Esp32BrowserScreenState extends State<Esp32BrowserScreen> {
  late TextEditingController _urlController;
  bool _isLoading = false;
  String? _htmlContent;
  int? _statusCode;
  int? _latencyMs;
  String _activeEndpoint = '/';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _baseUrl + _activeEndpoint);
    _fetchEndpoint('/');
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String get _baseUrl => 'http://${widget.ip}:${widget.port}';

  Future<void> _launchInAppBrowser() async {
    final targetUrl = _urlController.text.trim().isNotEmpty
        ? _urlController.text.trim()
        : '$_baseUrl$_activeEndpoint';
    final uri = Uri.parse(targetUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching in-app browser: $e');
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
      _urlController.text = '$_baseUrl$path';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ESP32 Web Server',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.ip}:${widget.port}',
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.secondaryText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_statusCode != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusCode == 200
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'HTTP $_statusCode',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _statusCode == 200
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            onPressed: () => _fetchEndpoint(_activeEndpoint),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Refresh HTML',
            color: AppColors.primaryOrange,
          ),
          IconButton(
            onPressed: _launchInAppBrowser,
            icon: const Icon(Icons.open_in_browser_rounded, size: 20),
            tooltip: 'Open Browser',
            color: AppColors.primaryOrange,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          // 1. URL Navigation & Launch Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: AppColors.primaryText,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.public_rounded,
                            size: 18,
                            color: AppColors.primaryOrange,
                          ),
                          hintText: 'http://${widget.ip}:${widget.port}/',
                          filled: true,
                          fillColor: AppColors.appBackground,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onSubmitted: (url) {
                          final uri = Uri.tryParse(url);
                          if (uri != null && uri.path.isNotEmpty) {
                            _fetchEndpoint(uri.path + (uri.hasQuery ? '?${uri.query}' : ''));
                          } else {
                            _fetchEndpoint('/');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    CustomBtn(
                      onTap: () {
                        final uri = Uri.tryParse(_urlController.text.trim());
                        if (uri != null && uri.path.isNotEmpty) {
                          _fetchEndpoint(uri.path + (uri.hasQuery ? '?${uri.query}' : ''));
                        } else {
                          _fetchEndpoint('/');
                        }
                      },
                      text: 'Go',
                      bgColor: AppColors.primaryOrange,
                      borderColor: AppColors.primaryOrange,
                      radius: 10,
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CustomBtn(
                  onTap: _launchInAppBrowser,
                  text: 'Open Full Web Page (In-App Browser)',
                  prefix: const Icon(
                    Icons.open_in_browser_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  bgColor: const Color(0xFF16A34A),
                  borderColor: const Color(0xFF16A34A),
                  radius: 10,
                  height: 42,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Quick Endpoint Selector Chips
          const Text(
            'Quick Endpoint Selector',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildEndpointChip('/', 'GET / (Home HTML)'),
                _buildEndpointChip('/ping', 'GET /ping (Latency)'),
                _buildEndpointChip('/status', 'GET /status'),
                _buildEndpointChip('/cmd?c=1', 'GET /cmd?c=1 (ON)'),
                _buildEndpointChip('/cmd?c=0', 'GET /cmd?c=0 (OFF)'),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Response Status & Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
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
                            ? 'Status: $_statusCode ${_statusCode == 200 ? "OK" : ""}'
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
                      Flexible(
                        child: Text(
                          '$_latencyMs ms',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_htmlContent != null && _htmlContent!.isNotEmpty)
                InkWell(
                  onTap: _copyToClipboard,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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

          // 4. Live Rendered HTML / Response Box
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 320),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
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
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFF87171),
                                size: 36,
                              ),
                              const SizedBox(height: 10),
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
                    : SelectableText(
                        _htmlContent?.isNotEmpty == true
                            ? _htmlContent!
                            : '<!-- Empty Response Received from ESP32 Server -->',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Color(0xFFF8FAFC),
                          height: 1.45,
                        ),
                      )),
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
