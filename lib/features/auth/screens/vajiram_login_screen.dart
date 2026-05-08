import 'dart:async';
import 'package:upsc_ca_ui/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:upsc_ca_ui/data/services/vajiram_session_service.dart';
import 'package:upsc_ca_ui/data/services/vajiram_study_service.dart';

class VajiramLoginScreen extends StatefulWidget {
  const VajiramLoginScreen({super.key});

  @override
  State<VajiramLoginScreen> createState() => _VajiramLoginScreenState();
}

class _VajiramLoginScreenState extends State<VajiramLoginScreen> {
  late final WebViewController controller;
  final VajiramSessionService _sessionService = VajiramSessionService();
  final VajiramStudyService _studyService = VajiramStudyService();
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkExistingSession());
    unawaited(_initController());
  }

  Future<void> _checkExistingSession() async {
    final cookies = await _sessionService.getCookies();
    if (cookies != null && cookies.isNotEmpty) {
      setState(() => _isVerifying = true);
      final isValid = await _studyService.verifySession(cookies);
      if (isValid && mounted) {
        if (!mounted) return;
        Navigator.pop(context, cookies);
        return;
      }
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _initController() async {
    controller = WebViewController();
    await controller.setUserAgent('Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36');
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (url) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (url) async {
          if (!mounted || _isVerifying) return;
          setState(() => _isLoading = false);
          AppLogger.d('DEBUG: [VajiramLoginScreen] Page finished: $url');
          
          // Auto-detect login success if user is on a dashboard page or MCQ page
          if (!url.contains("/accounts/login/") && 
              (url.contains("/daily-mcq/") || url.contains("/current-affairs/"))) {
            
            AppLogger.d('DEBUG: [VajiramLoginScreen] Success URL detected. Attempting auto-login...');
            
            // Verify presence of "Logout" or other logged-in markers
            try {
              final Object loginStateObj = await controller.runJavaScriptReturningResult(
                "document.body.innerText.toLowerCase().includes('logout') || "
                "document.body.innerHTML.includes('/accounts/logout/')"
              );
              
              if (loginStateObj.toString().toLowerCase() == "true") {
                unawaited(_captureSessionAndFinish());
              }
            } catch (e) {
              AppLogger.d('DEBUG: [VajiramLoginScreen] Auto-detect error: $e');
            }
          }
        },
      ),
    );
    await controller.loadRequest(
      Uri.parse("https://vajiramias.com/accounts/login/"),
    );
  }

  Future<String> _getCookies() async {
    if (!mounted) return "";
    try {
      final Object result = await controller.runJavaScriptReturningResult("document.cookie");
      String cookieStr = result.toString();
      
      if (cookieStr.isEmpty || cookieStr.toLowerCase() == "null") return "";
      
      if (cookieStr.startsWith('"') && cookieStr.endsWith('"')) {
        cookieStr = cookieStr.substring(1, cookieStr.length - 1);
      }
      
      cookieStr = cookieStr.replaceAll('\\"', '"');
      return cookieStr;
    } catch (e) {
      AppLogger.d('DEBUG: [VajiramLoginScreen] Cookie Error: $e');
      return "";
    }
  }

  Future<void> _handleManualContinue() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      AppLogger.d('DEBUG: [VajiramLoginScreen] Manual Continue: Checking current URL and login state...');
      
      // 1. Check if we are already on a non-login page
      final currentUrl = await controller.currentUrl() ?? "";
      AppLogger.d('DEBUG: [VajiramLoginScreen] Current URL: $currentUrl');
      
      // 2. Run JS to see if user is logged in (checking for "Logout" text or profile link)
      final Object loginStateObj = await controller.runJavaScriptReturningResult(
        "document.body.innerText.toLowerCase().includes('logout') || "
        "document.body.innerHTML.includes('/accounts/logout/') || "
        "document.body.innerHTML.includes('mcq_card')"
      );
      
      final bool looksLoggedIn = loginStateObj.toString().toLowerCase() == "true";
      AppLogger.d('DEBUG: [VajiramLoginScreen] UI Login State check: $looksLoggedIn');

      if (looksLoggedIn || (!currentUrl.contains("/accounts/login/") && currentUrl.contains("vajiramias.com"))) {
        // Success! User is logged in within the WebView.
        await _captureSessionAndFinish();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You don't seem to be logged in yet. Please log in first.")),
          );
        }
      }
    } catch (e) {
      AppLogger.d('DEBUG: [VajiramLoginScreen] Error during manual check: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _captureSessionAndFinish() async {
    if (!mounted) return;
    setState(() => _isVerifying = true);
    
    try {
      AppLogger.d('DEBUG: [VajiramLoginScreen] === STARTING SESSION CAPTURE ===');
      
      // 1. Capture FULL native cookies (including HttpOnly)
      final cookies = await _sessionService.getNativeCookies("https://vajiramias.com");
      if (cookies != null && cookies.isNotEmpty) {
        await _sessionService.saveCookies(cookies);
        AppLogger.d('DEBUG: [VajiramLoginScreen] Successfully captured native session.');
      } else {
        // Fallback to JS if native fails
        final jsCookies = await _getCookies();
        await _sessionService.saveCookies(jsCookies);
        AppLogger.d('DEBUG: [VajiramLoginScreen] Native capture empty. Saved JS cookies as fallback.');
      }
      
      AppLogger.d('DEBUG: [VajiramLoginScreen] === SESSION CAPTURE COMPLETE ===');
      
      if (mounted) {
        // We pop and return the cookies. Dashboard will trigger a fresh sync
        // from startDate to now in the background.
        final finalCookies = await _sessionService.getCookies();
        if (mounted) {
          Navigator.pop(context, finalCookies);
        }
      }
    } catch (e) {
      AppLogger.d('DEBUG: [VajiramLoginScreen] Capture error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  void _showManualSessionDialog() {
    final TextEditingController cookieInput = TextEditingController();
    unawaited(showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Session Cookies"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("If auto-login fails, paste the full cookie string from your browser (including sessionid) here."),
            const SizedBox(height: 16),
            TextField(
              controller: cookieInput,
              maxLines: 5,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "sessionid=...; csrftoken=...;",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              final cookies = cookieInput.text.trim();
              if (cookies.isNotEmpty) {
                await _sessionService.saveCookies(cookies);
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  if (context.mounted) {
                    Navigator.of(context).pop(cookies); // Exit login page with cookies
                  }
                }
              }
            },
            child: const Text("SAVE & CONTINUE"),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login to Vajiram"),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined),
            tooltip: "Manual Session",
            onPressed: _showManualSessionDialog,
          ),
          if (_isLoading || _isVerifying)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          TextButton(
            onPressed: (_isLoading || _isVerifying) ? null : () => unawaited(_handleManualContinue()),
            child: const Text(
              "CONTINUE",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _isVerifying 
        ? const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Verifying session..."),
            ],
          ))
        : WebViewWidget(controller: controller),
    );
  }
}





