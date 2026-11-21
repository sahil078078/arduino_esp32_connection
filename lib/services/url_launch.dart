// Source - https://stackoverflow.com/a/77357132
// Posted by sahil prajapati, modified by community.
// Retrieved 2026-11-21, License - CC BY-SA 4.0

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLaunch {
  /// Default function -> This will handle all try of launch activity
  /// if its possible to launch then launch otherwise it logs an error
  Future<bool> _myUriLaunch({
    required String url,
    LaunchMode mode = LaunchMode.platformDefault,
    WebViewConfiguration webViewConfiguration = const WebViewConfiguration(
      enableJavaScript: true,
    ),
    BuildContext? context,
    String notLaunchMsg = "Unable to open url",
    String errorMsg = "Something went wrong",
  }) async {
    try {
      final uri = Uri.parse(url);
      final willLaunch = await canLaunchUrl(uri);
      if (willLaunch) {
        return await launchUrl(
          uri,
          mode: mode,
          webViewConfiguration: webViewConfiguration,
        );
      } else {
        debugPrint(notLaunchMsg);
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(notLaunchMsg)),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('catchError : $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
      return false;
    }
  }

  /// Launch a web URL
  Future<bool> urlLaunch({
    required String url,
    LaunchMode mode = LaunchMode.externalApplication,
    BuildContext? context,
    String notLaunchMsg = "Unable to open url",
    String errorMsg = "Failed to open url",
  }) async =>
      await _myUriLaunch(
        url: url,
        mode: mode,
        context: context,
        notLaunchMsg: notLaunchMsg,
        errorMsg: errorMsg,
      );

  /// Send email
  Future<bool> mail({
    required String email,
    String? subject,
    String? body,
    BuildContext? context,
    String notLaunchMsg = "Unable to send mail",
    String errorMsg = "Failed to send mail",
  }) async =>
      await _myUriLaunch(
        url: Uri(
          scheme: 'mailto',
          path: email,
          query: 'subject=${Uri.encodeComponent(subject ?? '')}&body=${Uri.encodeComponent(body ?? '')}',
        ).toString(),
        mode: LaunchMode.externalApplication,
        context: context,
        notLaunchMsg: notLaunchMsg,
        errorMsg: errorMsg,
      );

  /// Send SMS
  Future<bool> sms({
    required String mobile,
    String? body,
    BuildContext? context,
    String notLaunchMsg = "Unable to send sms",
    String errorMsg = "Failed to send sms",
  }) async =>
      await _myUriLaunch(
        url: Uri(
          scheme: 'sms',
          path: mobile,
          query: 'body=${Uri.encodeComponent(body ?? '')}',
        ).toString(),
        mode: LaunchMode.externalApplication,
        context: context,
        notLaunchMsg: notLaunchMsg,
        errorMsg: errorMsg,
      );

  /// Make phone call
  Future<bool> call({
    required String mobile,
    BuildContext? context,
    String notLaunchMsg = "Unable to dial call",
    String errorMsg = "Failed to call",
  }) async =>
      await _myUriLaunch(
        url: Uri(
          scheme: "tel",
          path: mobile,
        ).toString(),
        mode: LaunchMode.externalApplication,
        context: context,
        notLaunchMsg: notLaunchMsg,
        errorMsg: errorMsg,
      );

  /// Open WhatsApp chat
  Future<bool> whatsApp({
    required String mobile,
    String? msg,
    String countryCode = '91',
    BuildContext? context,
    String notLaunchMsg = "Unable to open WhatsApp",
    String errorMsg = "Failed to open WhatsApp",
  }) async =>
      await _myUriLaunch(
        url: Uri.parse(
          "https://api.whatsapp.com/send/?phone=$countryCode$mobile&text=${Uri.encodeComponent(msg ?? '')}",
        ).toString(),
        mode: LaunchMode.externalApplication,
        context: context,
        notLaunchMsg: notLaunchMsg,
        errorMsg: errorMsg,
      );
}
