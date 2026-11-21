import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideInfoAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideInfoAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animController.forward();

    // Auto-navigate to MainScreen after animation completes
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      _goToMainScreen();
    });
  }

  void _goToMainScreen() {
    if (!mounted) return;
    _navigationTimer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: GestureDetector(
          onTap: _goToMainScreen,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Subtle background decoration circles
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightOrange.withAlpha(120),
                  ),
                ),
              ),
              Positioned(
                bottom: -100,
                left: -60,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightOrange.withAlpha(90),
                  ),
                ),
              ),

              // Main Centered Content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),

                      // Animated App Icon with glow and soft border
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryOrange.withAlpha(45),
                                  blurRadius: 26,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.primaryOrange.withAlpha(70),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppColors.lightOrange,
                                    child: const Icon(
                                      Icons.memory_rounded,
                                      size: 70,
                                      color: AppColors.primaryOrange,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // App Title & Tagline
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const Text(
                              'Arduino/Esp32 Controller',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryText,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.lightOrange,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primaryOrange.withAlpha(70),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'BLUETOOTH CONTROL HUB',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryOrange,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sleek progress indicator
                            SizedBox(
                              width: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: const LinearProgressIndicator(
                                  minHeight: 3,
                                  backgroundColor: AppColors.border,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryOrange),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 3),

                      // Developer Info Card (Bottom)
                      SlideTransition(
                        position: _slideInfoAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: AppColors.border, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Creator Name Row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightOrange,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person_rounded,
                                        size: 16,
                                        color: AppColors.primaryOrange,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Created by ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    const Text(
                                      'Sahil Prajapati',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(color: AppColors.border, height: 1),
                                const SizedBox(height: 10),

                                // Contact Info (Email Only)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 14,
                                      color: AppColors.primaryOrange,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'sahil078078@gmail.com',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
