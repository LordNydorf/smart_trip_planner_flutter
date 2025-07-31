import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Set status bar style for splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1a1a1a),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    // Start animations
    _startAnimations();
  }

  void _startAnimations() async {
    // Start fade and scale animations
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();

    // Wait for animations to complete + additional display time
    await Future.delayed(const Duration(milliseconds: 2500));

    // Complete splash screen
    widget.onComplete();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7DD3C0), // Light green background
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: _buildLogo(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo() {
    // Try to load the custom logo, fallback to built-in design
    return SizedBox(
      width: 500,
      height: 500,
      child: Image.asset(
        'assets/images/itinera_logo.png',
        width: 800,
        height: 800,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to custom widget if image not found
          return _buildFallbackLogo();
        },
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Airplane icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFDC935),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFDC935).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.flight, size: 40, color: Color(0xFF1a1a1a)),
          ),

          // Text below
          Positioned(
            bottom: 20,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF4ECDC4), Color(0xFF44B3AC)],
              ).createShader(bounds),
              child: const Text(
                'AI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
