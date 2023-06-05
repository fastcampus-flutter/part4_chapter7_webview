import 'package:fast_app_base/common/widget/loading.dart';
import 'package:fk_user_agent/fk_user_agent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';

// ignore: depend_on_referenced_packages
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'navigation_decision.dart';

class Notice extends StatefulWidget {
  const Notice({
    Key? key,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _NoticeState createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  late final WebViewController _controller;

  final List<UrlNavigationDecision> decisions = [
    CustomerServiceDecision(),
  ];

  double progress = 0;
  bool _isShowLoadingIndicator = true;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();
  }

  Future<void> _initializeWebViewController() async {
    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            setState(() {
              _isShowLoadingIndicator = true;
            });
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');

            setState(() {
              _isShowLoadingIndicator = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');

            setState(() {
              _isShowLoadingIndicator = false;
            });
          },
          onNavigationRequest: _navigationDecision,
        ),
      );

    /// User-Agent
    await FkUserAgent.init();
    final packageInfo = await PackageInfo.fromPlatform();
    await _controller
        .setUserAgent('${FkUserAgent.webViewUserAgent} fastcampus(${packageInfo.version})');

    // #docregion platform_features
    if (_controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller.loadRequest(Uri.parse('https://fastcampus.co.kr/info/notices'));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('공지사항'),
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          leading: const BackButton(
            color: Colors.black87,
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        ),
        body: Stack(
          children: <Widget>[
            WebViewWidget(controller: _controller),
            if (_isShowLoadingIndicator) LoadingIndicator.small(),
          ],
        ),
      ),
    );
  }

  Future<NavigationDecision> _navigationDecision(NavigationRequest request) async {
    final uri = Uri.parse(request.url);
    final bool isMainFrame = request.isMainFrame;

    debugPrint('url: $uri, isForMainFrame: $isMainFrame');

    /// 고객센터 바로가기
    /// 외부 브라우저로 처리
    /// 1번
    if (uri.host.contains('day1fastcampussupport.zendesk.com')) {
      launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      return NavigationDecision.prevent;
    }

    /// 2번
    // for (final decision in decisions) {
    //   if (decision.isMatch(uri)) {
    //     return decision.decide(context, _controller, uri, isMainFrame);
    //   }
    // }

    return NavigationDecision.navigate;
  }
}