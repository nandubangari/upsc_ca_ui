import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/vajiram_session_service.dart';
import '../services/vajiram_study_service.dart';

class VajiramLoginPage extends StatefulWidget {
  const VajiramLoginPage({super.key});

  @override
  State<VajiramLoginPage> createState() => _VajiramLoginPageState();
}

class _VajiramLoginPageState extends State<VajiramLoginPage> {
  late final WebViewController controller;
  final VajiramSessionService _sessionService = VajiramSessionService();
  final VajiramStudyService _studyService = VajiramStudyService();
  bool _isLoading = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
    _initController();
  }

  Future<void> _checkExistingSession() async {
    final cookies = await _sessionService.getCookies();
    if (cookies != null && cookies.isNotEmpty) {
      setState(() => _isVerifying = true);
      final isValid = await _studyService.verifySession(cookies);
      if (isValid && mounted) {
        Navigator.pop(context, cookies);
        return;
      }
      setState(() => _isVerifying = false);
    }
  }

  void _initController() {
    controller = WebViewController()
      ..setUserAgent('Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36')
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (url) async {
            if (!mounted || _isVerifying) return;
            setState(() => _isLoading = false);
            print('DEBUG: [VajiramLoginPage] Page finished: $url');
            
            // Auto-detect login success if user is on a dashboard page or MCQ page
            if (!url.contains("/accounts/login/") && 
                (url.contains("/daily-mcq/") || url.contains("/current-affairs/"))) {
              
              print('DEBUG: [VajiramLoginPage] Success URL detected. Attempting auto-login...');
              
              // Verify presence of "Logout" or other logged-in markers
              try {
                final Object loginStateObj = await controller.runJavaScriptReturningResult(
                  "document.body.innerText.toLowerCase().includes('logout') || "
                  "document.body.innerHTML.includes('/accounts/logout/')"
                );
                
                if (loginStateObj.toString().toLowerCase() == "true") {
                  await _scrapeQuizzesAndFinish();
                }
              } catch (e) {
                print('DEBUG: [VajiramLoginPage] Auto-detect error: $e');
              }
            }
          },
        ),
      )
      ..loadRequest(
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
      print('DEBUG: [VajiramLoginPage] Cookie Error: $e');
      return "";
    }
  }

  Future<void> _handleManualContinue() async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);

    try {
      print('DEBUG: [VajiramLoginPage] Manual Continue: Checking current URL and login state...');
      
      // 1. Check if we are already on a non-login page
      final currentUrl = await controller.currentUrl() ?? "";
      print('DEBUG: [VajiramLoginPage] Current URL: $currentUrl');
      
      // 2. Run JS to see if user is logged in (checking for "Logout" text or profile link)
      final Object loginStateObj = await controller.runJavaScriptReturningResult(
        "document.body.innerText.toLowerCase().includes('logout') || "
        "document.body.innerHTML.includes('/accounts/logout/') || "
        "document.body.innerHTML.includes('mcq_card')"
      );
      
      final bool looksLoggedIn = loginStateObj.toString().toLowerCase() == "true";
      print('DEBUG: [VajiramLoginPage] UI Login State check: $looksLoggedIn');

      if (looksLoggedIn || (!currentUrl.contains("/accounts/login/") && currentUrl.contains("vajiramias.com"))) {
        // Success! User is logged in within the WebView.
        await _scrapeQuizzesAndFinish();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You don't seem to be logged in yet. Please log in first.")),
          );
        }
      }
    } catch (e) {
      print('DEBUG: [VajiramLoginPage] Error during manual check: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _scrapeQuizzesAndFinish() async {
    if (!mounted) return;
    setState(() => _isVerifying = true);
    
    try {
      print('DEBUG: [VajiramLoginPage] === STARTING SESSION CAPTURE ===');
      
      // 1. Capture FULL native cookies (including HttpOnly)
      final cookies = await _sessionService.getNativeCookies("https://vajiramias.com");
      if (cookies != null && cookies.isNotEmpty) {
        await _sessionService.saveCookies(cookies);
        print('DEBUG: [VajiramLoginPage] Successfully captured native session.');
      } else {
        // Fallback to JS if native fails
        final jsCookies = await _getCookies();
        await _sessionService.saveCookies(jsCookies);
        print('DEBUG: [VajiramLoginPage] Native capture empty. Saved JS cookies as fallback.');
      }
      
      print('DEBUG: [VajiramLoginPage] === SESSION CAPTURE COMPLETE ===');
      
      if (mounted) {
        // We pop and return the cookies. Dashboard will trigger a fresh sync
        // from startDate to now in the background.
        final finalCookies = await _sessionService.getCookies();
        Navigator.pop(context, finalCookies);
      }
    } catch (e) {
      print('DEBUG: [VajiramLoginPage] Capture error: $e');
      if (mounted) Navigator.pop(context);
    }
  }

  void _showManualSessionDialog() {
    final TextEditingController cookieInput = TextEditingController();
    showDialog(
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
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context, cookies); // Exit login page with cookies
                }
              }
            },
            child: const Text("SAVE & CONTINUE"),
          ),
        ],
      ),
    );
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
            onPressed: () => _showManualSessionDialog(),
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
            onPressed: (_isLoading || _isVerifying) ? null : _handleManualContinue,
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
