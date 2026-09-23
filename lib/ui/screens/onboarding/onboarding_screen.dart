import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  int _currentIndex = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      gradient: LinearGradient(
        colors: [Color(0xFF155E75), Color(0xFF0E7490)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconGradient: LinearGradient(
        colors: [Color(0xFF0E7490), Color(0xFF0284C7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFF0E7490),
      icon: Icons.watch_rounded,
      tag: 'SMARTWATCH TELEMETRY',
      title: 'Continuous Health\nMonitoring',
      desc:
          'Real-time tracking of Heart Rate, SpO₂, Sleep cycles, Activity & Stress levels — 24/7 for your loved ones.',
    ),
    _OnboardingPage(
      gradient: LinearGradient(
        colors: [Color(0xFF1E3A5F), Color(0xFF2B608A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconGradient: LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFF3B82F6),
      icon: Icons.hub_rounded,
      tag: 'IOT BEDSIDE HUB',
      title: 'Smart Room\nAwareness',
      desc:
          'ESP32 monitors room climate, human presence via radar, ambient lighting & instant SOS button alerts.',
    ),
    _OnboardingPage(
      gradient: LinearGradient(
        colors: [Color(0xFF164E63), Color(0xFF155E75)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      iconGradient: LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF38BDF8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      glowColor: Color(0xFF06B6D4),
      icon: Icons.psychology_rounded,
      tag: 'AI RISK INTELLIGENCE',
      title: 'Predictive\nHealth AI',
      desc:
          'Advanced ML models predict health risks, notify caregivers instantly, and guide medication schedules.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentIndex < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentIndex];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(gradient: page.gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Colors.white.withValues(alpha: 0.5),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) {
                    setState(() => _currentIndex = idx);
                    _animController.reset();
                    _animController.forward();
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: _fadeIn,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            // Animated icon orb
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              builder: (_, scale, child) =>
                                  Transform.scale(scale: scale, child: child),
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: page.iconGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: page.glowColor
                                          .withValues(alpha: 0.45),
                                      blurRadius: 50,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(page.icon,
                                    size: 80, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 48),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: page.glowColor.withValues(alpha: 0.5),
                                ),
                                color: page.glowColor.withValues(alpha: 0.12),
                              ),
                              child: Text(
                                page.tag,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: page.glowColor.withValues(alpha: 0.9),
                                  letterSpacing: 2.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              page.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.15,
                                fontFamily: 'Outfit',
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              page.desc,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.65,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
                  },
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: ExpandingDotsEffect(
                        activeDotColor: page.glowColor,
                        dotColor: Colors.white.withValues(alpha: 0.2),
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: _onNext,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              page.glowColor,
                              page.glowColor.withValues(alpha: 0.7)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: page.glowColor.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == _pages.length - 1
                                    ? 'Get Started'
                                    : 'Continue',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'Outfit',
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 20),
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
    );
  }
}

class _OnboardingPage {
  final LinearGradient gradient;
  final LinearGradient iconGradient;
  final Color glowColor;
  final IconData icon;
  final String tag;
  final String title;
  final String desc;

  const _OnboardingPage({
    required this.gradient,
    required this.iconGradient,
    required this.glowColor,
    required this.icon,
    required this.tag,
    required this.title,
    required this.desc,
  });
}
