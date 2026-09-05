import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.favorite_rounded,
      iconColor: AuraColors.critical,
      title: 'Welcome to AURA',
      subtitle: 'Your AI-powered personal health companion for real-time monitoring and early warning.',
    ),
    _OnboardingPage(
      icon: Icons.sensors_rounded,
      iconColor: AuraColors.healthy,
      title: 'Real-Time Monitoring',
      subtitle: 'AURA continuously monitors your vitals and environment through connected IoT sensors via Bluetooth.',
    ),
    _OnboardingPage(
      icon: Icons.psychology_rounded,
      iconColor: AuraColors.techBlue,
      title: 'Intelligent Analysis',
      subtitle: 'Our AI engine learns your personal baseline and detects unusual patterns before they become serious.',
    ),
    _OnboardingPage(
      icon: Icons.shield_rounded,
      iconColor: AuraColors.healthy,
      title: 'Privacy First',
      subtitle: 'All risk analysis runs on your device. Your health data stays under your control.',
    ),
    _OnboardingPage(
      icon: Icons.watch_rounded,
      iconColor: AuraColors.warning,
      title: 'Wearable Alerts',
      subtitle: 'Receive instant alerts on your wearable device when your health risk changes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 20, 0),
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Skip'),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _page ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _page ? AuraColors.healthy : (AuraColors.glassBorder),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),

            // Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page < _pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    } else {
                      context.go('/');
                    }
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: Text(_page < _pages.length - 1 ? 'Continue' : 'Get Started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    
    final textColor = AuraColors.textPrimary;
    final subtextColor = AuraColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 56),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            style: TextStyle(color: textColor, fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: TextStyle(color: subtextColor, fontSize: 15, height: 1.6),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
