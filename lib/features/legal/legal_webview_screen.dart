import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../places/external_links.dart';

/// 인앱 웹뷰로 약관·개인정보처리방침을 보여준다. 웹에서는 새 탭으로 연다.
class LegalWebViewScreen extends StatefulWidget {
  const LegalWebViewScreen({super.key, required this.title, required this.url});

  final String title;
  final String url;

  static Future<void> open(BuildContext context, {required String title, required String url}) {
    if (kIsWeb) return ExternalLinks.open(url);
    return context.pushPage(LegalWebViewScreen(title: title, url: url));
  }

  @override
  State<LegalWebViewScreen> createState() => _LegalWebViewScreenState();
}

class _LegalWebViewScreenState extends State<LegalWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
        onWebResourceError: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3))),
        ],
      ),
    );
  }
}
