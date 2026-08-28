import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dashboard/dashboard_screen.dart';
import 'controller/onboarding_controller.dart';
import 'onboarding_screen.dart';

/// Root route ("/"): shows onboarding on first launch only, then the
/// Dashboard on every subsequent launch. This is a conditional render
/// rather than a router redirect so completing onboarding doesn't require
/// any navigation-stack gymnastics — it just flips which widget this one
/// route renders.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingComplete = ref.watch(onboardingCompleteProvider);

    return onboardingComplete.when(
      data: (complete) =>
          complete ? const DashboardScreen() : const OnboardingScreen(),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const DashboardScreen(),
    );
  }
}
