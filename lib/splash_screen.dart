import 'package:flutter/material.dart';
import 'hello_screen.dart';
import 'main_menu_screen.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String? _splashAssetError;

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Tạo fade animation
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    // Tạo scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Bắt đầu animation
    _animationController.forward();

    // Chuyển màn hình sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainMenuScreen()),
        );
      }
    });

    // Probe splash asset presence and store any error message
    _probeSplashAsset();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // Background image with fallback if asset missing
            Image.asset(
              'assets/starting.png',
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
                return const SizedBox.shrink();
              },
            ),
            Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Loading indicator
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3.0,
                      ),
                      const SizedBox(height: 20),
                      // Loading text
                      Text(
                        _splashAssetError == null
                            ? 'Loading...'
                            : 'Không load được assets/starting.png',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _probeSplashAsset() async {
    try {
      await rootBundle.load('assets/starting.png');
      if (mounted) {
        setState(() {
          _splashAssetError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _splashAssetError = e.toString();
        });
      }
    }
  }
}
