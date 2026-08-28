import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';

/// Whether the user has swiped through onboarding at least once. Onboarding
/// never blocks app usage on subsequent launches, and Google Sign-In is
/// still not required afterwards — see spec's "no login required" flow.
final FutureProvider<bool> onboardingCompleteProvider =
    FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;
});

class OnboardingController {
  final Ref ref;
  OnboardingController(this.ref);

  Future<void> complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    ref.invalidate(onboardingCompleteProvider);
  }
}

final Provider<OnboardingController> onboardingControllerProvider =
    Provider((ref) => OnboardingController(ref));
