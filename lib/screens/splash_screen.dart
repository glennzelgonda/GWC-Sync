import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../mock_data/inventory_store.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import 'login_screen.dart';
import 'nav_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _initialize();
  }

  Future<void> _initialize() async {
    // Keep splash visible for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    Widget destination = const LoginScreen();

    if (user != null) {
      try {
        await InventoryStore.instance.login();
        destination = const NavShell();
      } catch (_) {
        await FirebaseAuth.instance.signOut();
        destination = const LoginScreen();
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      FadeSlideRoute(page: destination),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF151515),
              Color(0xFF090909),
              Color(0xFF000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final glow = 0.20 + (_controller.value * 0.30);
                    final offset =
                        sin(_controller.value * pi * 2) * 3;

                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 700),
                        opacity: 1,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(glow),
                                    blurRadius: 90,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                "assets/images/gwc_logo.png",
                                width: 260,
                              ),
                            ),

                            const SizedBox(height: 35),

                            const Text(
                              "SMARTER STOCK.",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              "STRONGER PERFORMANCE.",
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 45),

                            const SizedBox(
                              width: 34,
                              height: 34,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Version 1.0.0",
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
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