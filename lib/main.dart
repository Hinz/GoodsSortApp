import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const GoodsSortApp());
}

class GoodsSortApp extends StatelessWidget {
  const GoodsSortApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoodsSort',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE84060)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this);
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1800), _goToGame);
  }

  void _goToGame() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8DCC8),
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE84060), Color(0xFFFF9500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE84060).withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🛒', style: TextStyle(fontSize: 52)),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFFE84060),
                      Color(0xFFFF9500),
                      Color(0xFFF5C800),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'GoodsSort',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sort the shelf!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF999999),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFE84060),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Game Screen ──────────────────────────────────────────────────────────────

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  WebViewController? _controller;
  bool _loading = true;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final html = await _buildInlinedHtml();

    final controller = WebViewController();
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setBackgroundColor(const Color(0xFFE8DCC8));
    await controller.addJavaScriptChannel(
      'FlutterBridge',
      onMessageReceived: _onGameMessage,
    );
    await controller.setNavigationDelegate(NavigationDelegate(
      onPageFinished: (_) {
        // Override postMessage so game events reach Flutter
        controller.runJavaScript('''
          (function(){
            window.parent = {
              postMessage: function(data) {
                try { FlutterBridge.postMessage(JSON.stringify(data)); } catch(e){}
              }
            };
          })();
        ''');
        setState(() => _loading = false);
      },
    ));
    _controller = controller;
    if (mounted) setState(() {});
    await controller.loadHtmlString(html, baseUrl: 'https://localhost');
  }

  /// Inlines all product images as base64 data URIs so WebView works offline
  Future<String> _buildInlinedHtml() async {
    String html = await rootBundle.loadString('assets/game/index.html');

    const imageFiles = [
      'BH-38_700ml-medium.png',
      'MP0600-1-medium.png',
      'MP0610-1-medium.png',
      'MP0630-1-medium.png',
      'MP0641-1-medium.png',
      'MP1420-2-medium.png',
      'MP3010-2-medium.webp',
      'MP3052-2-medium.webp',
      'MP4600-2-medium.webp',
      'easy-BC-1.webp',
      'flash-1750-.webp',
      'flash-gel-label-green.webp',
      'flash-gel-label-purple.png',
      'manix-900x900-01-medium.png',
      'plus5-1L-low-1.webp',
      'rush-limescale-750ml.webp',
      'spartan_logo-3.webp',
    ];

    for (final file in imageFiles) {
      try {
        final bytes = await rootBundle.load('assets/game/images/$file');
        final b64 = base64Encode(bytes.buffer.asUint8List());
        final ext = file.split('.').last.toLowerCase();
        final mime = switch (ext) {
          'webp' => 'image/webp',
          'png'  => 'image/png',
          _      => 'image/jpeg',
        };
        html = html.replaceAll('images/$file', 'data:$mime;base64,$b64');
      } catch (_) {}
    }
    return html;
  }

  void _onGameMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      switch (type) {
        case 'LEVEL_START':
          setState(() =>
              _currentLevel = (data['level'] as int?) ?? _currentLevel);
          break;
        case 'LEVEL_COMPLETE':
          _showSnack(
            '🎉 Level ${data['level']} done!  ⭐ ${data['stars']}  👣 ${data['moves']} moves',
            const Color(0xFF4CAF50),
          );
          break;
        case 'LEVEL_FAILED':
          _showSnack('😓 Try again!', const Color(0xFFE84060));
          break;
        case 'GAME_COMPLETE':
          _showGameComplete(data);
          break;
      }
    } catch (_) {}
  }

  void _showSnack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  void _showGameComplete(Map<String, dynamic> data) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🏆 All Done!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        content: Text(
          'You sorted every shelf!\n\nTotal stars: ${data['stars'] ?? 0} ⭐',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _controller?.runJavaScript('startGame(0)');
            },
            child: const Text('Play Again',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Let game handle back (go to menu) before exiting
    await _controller?.runJavaScript(
        'if(typeof goMenu==="function") goMenu()');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, __) => _onWillPop(),
      child: Scaffold(
        backgroundColor: const Color(0xFF2A2A2A),
        body: SafeArea(
          child: Stack(
            children: [
              if (_controller != null)
                WebViewWidget(controller: _controller!),
              if (_loading)
                Container(
                  color: const Color(0xFFE8DCC8),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🛒', style: TextStyle(fontSize: 56)),
                        SizedBox(height: 20),
                        CircularProgressIndicator(
                          color: Color(0xFFE84060),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text('Loading...',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
