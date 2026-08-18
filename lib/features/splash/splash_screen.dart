import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/router/home_shell.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_screen.dart';

// Splash screen with a quick logo animation. After it plays we check whether
// onboarding was seen and whether the user is signed in, then route to the
// right screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration _minSplashDuration = Duration(milliseconds: 2500);
  static const String _onboardingKey = 'has_seen_onboarding';

  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _nameSlide;
  late final Animation<double> _nameOpacity;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _progressOpacity;

  bool _navigated = false;
  User? _authUser;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _nameSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.60, curve: Curves.easeOutCubic),
      ),
    );

    _nameOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.55, curve: Curves.easeIn),
      ),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.80, curve: Curves.easeIn),
      ),
    );

    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 0.90, curve: Curves.easeIn),
      ),
    );

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    final authFuture = ref.read(authServiceProvider).authStateChanges.first;

    final results = await Future.wait<dynamic>([
      _controller.forward(),
      Future.delayed(_minSplashDuration),
      authFuture,
    ]);

    _authUser = results[2] as User?;

    await _navigateBasedOnState();
  }

  Future<void> _navigateBasedOnState() async {
    if (!mounted || _navigated) return;
    _navigated = true;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool(_onboardingKey) ?? false;

    if (!mounted) return;

    final user = _authUser;

    Widget destination;
    if (!hasSeenOnboarding) {
      destination = const OnboardingScreen();
    } else if (user == null) {
      destination = const LoginScreen();
    } else if (!user.emailVerified) {
      destination = const LoginScreen(showVerificationPrompt: true);
    } else {
      destination = const HomeShell();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildLogo(),
              const SizedBox(height: 16),
              _buildName(theme, colors),
              const SizedBox(height: 8),
              _buildTagline(theme, colors),
              const Spacer(),
              _buildProgress(colors),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/images/acquirebase_icon.png',
        width: 180,
        height: 180,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildName(ThemeData theme, ColorScheme colors) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _nameOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _nameSlide.value),
            child: child,
          ),
        );
      },
      child: Text(
        'AcquireBase',
        style: theme.textTheme.headlineMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildTagline(ThemeData theme, ColorScheme colors) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _taglineOpacity.value,
          child: child,
        );
      },
      child: Text(
        'Discover digital products worth your attention.',
        style: theme.textTheme.bodyLarge?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildProgress(ColorScheme colors) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _progressOpacity.value,
          child: child,
        );
      },
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colors.primary,
        ),
      ),
    );
  }
}
