import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import 'controller/onboarding_controller.dart';
import 'widgets/onboarding_page.dart';

const List<OnboardingPageData> _pages = [
  OnboardingPageData(
    icon: Icons.mic_rounded,
    title: 'Record Audio',
    description:
        'Studio-quality recording in WAV, MP3 or AAC with a live waveform, '
        'duration counter and input meter.',
  ),
  OnboardingPageData(
    icon: Icons.graphic_eq_rounded,
    title: 'Remove Noise',
    description:
        'AI-powered noise removal clears traffic, wind and background chatter '
        'while keeping your voice natural — compare before/after anytime.',
  ),
  OnboardingPageData(
    icon: Icons.auto_awesome_rounded,
    title: 'Voice Themes',
    description:
        'Transform a take into a Child, Robot, Deep, Anime voice and more — '
        'your original recording is never touched.',
  ),
  OnboardingPageData(
    icon: Icons.cloud_sync_rounded,
    title: 'Cloud Sync',
    description:
        'Use VoiceCraft fully offline. Sign in with Google only when you want '
        'to back up and stream recordings across devices.',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingControllerProvider).complete();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip'),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => OnboardingPage(data: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLast) {
                      _finish();
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? 'Get Started' : 'Next'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
