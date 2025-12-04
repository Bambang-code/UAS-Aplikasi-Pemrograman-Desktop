// screens/splash_screen.dart - FIXED: STABLE SPEED & CLEAN MEMORY
import 'package:flutter/material.dart';
import 'dart:async'; // Perlu untuk Timer yang lebih aman
import 'dart:math';
import 'guest_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showButton = false;

  // List kembang api
  final List<Firework> _fireworks = [];
  final Random _random = Random();

  // Timer untuk loop utama (supaya bisa distop/cancel saat pindah halaman)
  Timer? _fireworkLoopTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Show button logic
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() => _showButton = true);
      }
    });

    // Mulai loop kembang api
    _startFireworkLoop();
  }

  void _startFireworkLoop() {
    // Pastikan timer lama dimatikan dulu sebelum buat baru (mencegah double speed)
    _fireworkLoopTimer?.cancel();

    _fireworkLoopTimer =
        Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      // Luncurkan batch kembang api
      _launchBatch();
    });

    // Luncurkan batch pertama langsung
    _launchBatch();
  }

  void _launchBatch() {
    if (!mounted) return;

    // Batch size: 2-4 kembang api per gelombang
    int batchSize = 2 + _random.nextInt(3);

    for (int i = 0; i < batchSize; i++) {
      // Delay sedikit antar peluncuran dalam satu batch agar tidak menumpuk di satu titik
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _launchFirework();
      });
    }
  }

  void _launchFirework() {
    if (!mounted) return;

    final size = MediaQuery.of(context).size;
    final x = _random.nextDouble() * size.width;
    // Posisi ledakan di area tengah ke atas
    final y = (size.height * 0.15) + (_random.nextDouble() * size.height * 0.5);

    // ID Unik (Time based) untuk memastikan yang dihapus adalah yang benar
    final String uniqueId = DateTime.now().microsecondsSinceEpoch.toString() +
        _random.nextInt(1000).toString();

    setState(() {
      _fireworks.add(Firework(
        id: uniqueId,
        x: x,
        y: y,
        color: _getRandomColor(),
      ));
    });

    // Jadwalkan penghapusan TEPAT sesuai durasi animasi (3100ms)
    // Menggunakan ID untuk menghapus item yang spesifik, bukan index 0
    Future.delayed(const Duration(milliseconds: 3100), () {
      if (mounted) {
        setState(() {
          _fireworks.removeWhere((element) => element.id == uniqueId);
        });
      }
    });
  }

  Color _getRandomColor() {
    final colors = [
      const Color(0xFFFFD700), // Gold
      Colors.white,
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.lightBlueAccent,
      Colors.purpleAccent,
      Colors.greenAccent,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    // PENTING: Matikan timer saat keluar agar animasi tidak jalan di background
    _fireworkLoopTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToGuestMenu() {
    // Matikan timer sebelum pindah
    _fireworkLoopTimer?.cancel();

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GuestMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
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
            ..._buildStars(),

            // Render Fireworks
            // Menggunakan Key berdasarkan ID agar Flutter tidak bingung me-render ulang
            ..._fireworks.map((firework) =>
                FireworkWidget(key: ValueKey(firework.id), firework: firework)),

            // UI Content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        constraints: const BoxConstraints(maxWidth: 600),
                        padding: const EdgeInsets.all(60),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          border: Border.all(
                            color: const Color(0xFFD4AF37),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFD4AF37),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD4AF37)
                                        .withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.coffee,
                                size: 60,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                            const SizedBox(height: 30),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFD4AF37),
                                  Color(0xFFFFD700),
                                ],
                              ).createShader(bounds),
                              child: const Text(
                                'Welcome Back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 56,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Good Vibes! Great Coffee!',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[400],
                                fontStyle: FontStyle.italic,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 40),
                            AnimatedOpacity(
                              opacity: _showButton ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 800),
                              child: AnimatedScale(
                                scale: _showButton ? 1.0 : 0.8,
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutBack,
                                child: ElevatedButton(
                                  onPressed: _navigateToGuestMenu,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37),
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 60,
                                      vertical: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 8,
                                    shadowColor: const Color(0xFFD4AF37)
                                        .withOpacity(0.5),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'START',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
      child: FadeTransition(
        opacity: _fadeAnimation,
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
                    child: Icon(Icons.diamond,
                        size: 16, color: Color(0xFFD4AF37))),
              if (isTop && !isLeft)
                const Positioned(
                    top: -2,
                    right: -2,
                    child: Icon(Icons.diamond,
                        size: 16, color: Color(0xFFD4AF37))),
              if (!isTop && isLeft)
                const Positioned(
                    bottom: -2,
                    left: -2,
                    child: Icon(Icons.diamond,
                        size: 16, color: Color(0xFFD4AF37))),
              if (!isTop && !isLeft)
                const Positioned(
                    bottom: -2,
                    right: -2,
                    child: Icon(Icons.diamond,
                        size: 16, color: Color(0xFFD4AF37))),
            ],
          ),
        ),
      ),
    );
  }
}

// UPDATE: Added ID to ensure clean removal
class Firework {
  final String id;
  final double x;
  final double y;
  final Color color;
  Firework(
      {required this.id,
      required this.x,
      required this.y,
      required this.color});
}

class FireworkWidget extends StatefulWidget {
  final Firework firework;
  const FireworkWidget({super.key, required this.firework});

  @override
  State<FireworkWidget> createState() => _FireworkWidgetState();
}

class _FireworkWidgetState extends State<FireworkWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final List<FireworkParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _animation =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

    for (int i = 0; i < 50; i++) {
      final angle = (i / 50) * 2 * pi;
      final speed = 30 + _random.nextDouble() * 100;
      _particles.add(FireworkParticle(
        angle: angle,
        speed: speed,
        color: widget.firework.color,
      ));
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: FireworkPainter(
            x: widget.firework.x,
            y: widget.firework.y,
            particles: _particles,
            progress: _animation.value,
          ),
        );
      },
    );
  }
}

class FireworkParticle {
  final double angle;
  final double speed;
  final Color color;

  FireworkParticle({
    required this.angle,
    required this.speed,
    required this.color,
  });
}

class FireworkPainter extends CustomPainter {
  final double x;
  final double y;
  final List<FireworkParticle> particles;
  final double progress;

  FireworkPainter({
    required this.x,
    required this.y,
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final distance = particle.speed * progress * 1.2;
      final px = x + cos(particle.angle) * distance;
      // Gravity effect
      final py =
          y + sin(particle.angle) * distance + (progress * progress * 150);

      double opacity = 1.0;
      if (progress > 0.8) {
        opacity = (1.0 - progress) * 5;
      }
      opacity = opacity.clamp(0.0, 1.0);

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..strokeWidth = 2;

      final trailLength = 10.0 * (1.0 - progress);
      final trailStart = Offset(
        px - cos(particle.angle) * trailLength,
        py - sin(particle.angle) * trailLength - (progress * 5),
      );

      if (opacity > 0) {
        canvas.drawLine(trailStart, Offset(px, py), paint);
        paint.style = PaintingStyle.fill;
        double radius = 2.5 * (1.0 - (progress * 0.5));
        canvas.drawCircle(Offset(px, py), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(FireworkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
