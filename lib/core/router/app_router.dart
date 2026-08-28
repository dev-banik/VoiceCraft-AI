import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/editor/editor_screen.dart';
import '../../presentation/enhancement/enhancement_screen.dart';
import '../../presentation/noise_removal/noise_removal_screen.dart';
import '../../presentation/onboarding/app_gate.dart';
import '../../presentation/playback/playback_screen.dart';
import '../../presentation/recording/record_screen.dart';
import '../../presentation/search/search_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/voice_themes/voice_themes_screen.dart';
import 'route_names.dart';

final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.dashboard,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: RoutePaths.dashboard,
        builder: (context, state) => const AppGate(),
      ),
      GoRoute(
        path: RoutePaths.record,
        builder: (context, state) => const RecordScreen(),
      ),
      GoRoute(
        path: RoutePaths.playback,
        builder: (context, state) => PlaybackScreen(
          recordingId: state.pathParameters['recordingId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.noiseRemoval,
        builder: (context, state) => NoiseRemovalScreen(
          recordingId: state.pathParameters['recordingId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.voiceThemes,
        builder: (context, state) => VoiceThemesScreen(
          recordingId: state.pathParameters['recordingId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.enhancement,
        builder: (context, state) => EnhancementScreen(
          recordingId: state.pathParameters['recordingId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.editor,
        builder: (context, state) => EditorScreen(
          recordingId: state.pathParameters['recordingId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
