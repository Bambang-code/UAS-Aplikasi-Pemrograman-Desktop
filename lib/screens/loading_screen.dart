// screens/loading_screen.dart - NEW FILE
import 'package:flutter/material.dart';
import 'dart:async';
import 'splash_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  int _currentProgress = 0;
  late Timer _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for logo
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start loading counter
    _startLoading();
  }

  void _startLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        if (_currentProgress < 100) {
          _currentProgress++;
        } else {
          timer.cancel();
          _navigateToSplash();
        }
      });
    });
  }

  void _navigateToSplash() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SplashScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a1a),
              Color(0xFF000000),
              Color(0xFF1a1a1a),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Animated stars background
            ..._buildStars(),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated logo
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.5),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.coffee,
                        size: 80,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // App title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFD4AF37),
                        Color(0xFFFFD700),
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'Cafe Management',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Progress counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        // Large counter number
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: _currentProgress),
                          duration: const Duration(milliseconds: 100),
                          builder: (context, value, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFD4AF37),
                                ],
                              ).createShader(bounds),
                              child: Text(
                                '$value%',
                                style: const TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Progress bar
                        Container(
                          width: 300,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                width: 300 * (_currentProgress / 100),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFD4AF37),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37)
                                          .withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Loading text
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                            letterSpacing: 3,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Corner decorations
            _buildCornerDecoration(Alignment.topLeft),
            _buildCornerDecoration(Alignment.topRight),
            _buildCornerDecoration(Alignment.bottomLeft),
            _buildCornerDecoration(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStars() {
    return List.generate(50, (index) {
      return Positioned(
        left: (index * 37) % MediaQuery.of(context).size.width,
        top: (index * 23) % MediaQuery.of(context).size.height,
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 1000 + (index * 50)),
          builder: (context, double value, child) {
            return Opacity(
              opacity: (value * 0.8).clamp(0.2, 1.0),
              child: Container(
                width: 2 + (index % 3).toDouble(),
                height: 2 + (index % 3).toDouble(),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4AF37),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildCornerDecoration(Alignment alignment) {
    final isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;
    final isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;

    return Positioned(
      top: isTop ? 20 : null,
      bottom: !isTop ? 20 : null,
      left: isLeft ? 20 : null,
      right: !isLeft ? 20 : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: Color(0xFFD4AF37), width: 3)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: Color(0xFFD4AF37), width: 3)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: Color(0xFFD4AF37), width: 3)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: Color(0xFFD4AF37), width: 3)
                : BorderSide.none,
          ),
        ),
        child: Stack(
          children: [
            if (isTop && isLeft)
              const Positioned(
                top: -2,
                left: -2,
                child: Icon(
                  Icons.diamond,
                  size: 16,
                  color: Color(0xFFD4AF37),
                ),
              ),
            if (isTop && !isLeft)
              const Positioned(
                top: -2,
                right: -2,
                child: Icon(
                  Icons.diamond,
                  size: 16,
                  color: Color(0xFFD4AF37),
                ),
              ),
            if (!isTop && isLeft)
              const Positioned(
                bottom: -2,
                left: -2,
                child: Icon(
                  Icons.diamond,
                  size: 16,
                  color: Color(0xFFD4AF37),
                ),
              ),
            if (!isTop && !isLeft)
              const Positioned(
                bottom: -2,
                right: -2,
                child: Icon(
                  Icons.diamond,
                  size: 16,
                  color: Color(0xFFD4AF37),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
