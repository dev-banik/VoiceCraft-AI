import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/providers.dart';
import '../../core/utils/formatters.dart';
import '../auth/sign_in_sheet.dart';
import 'controller/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final isSignedIn = ref.watch(isSignedInProvider);
    final storageAsync = ref.watch(_localStorageBytesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SectionHeader('Recording'),
          ListTile(
            title: const Text('Recording format'),
            subtitle: Text(settings.recordingFormat.toUpperCase()),
            trailing: DropdownButton<String>(
              value: settings.recordingFormat,
              underline: const SizedBox.shrink(),
              items: RecordingFormat.values
                  .map((f) => DropdownMenuItem(
                        value: f.name,
                        child: Text(f.name.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  controller.setRecordingFormat(RecordingFormat.values.byName(v));
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Sample rate'),
            subtitle: Text('${settings.sampleRate} Hz'),
            trailing: DropdownButton<int>(
              value: settings.sampleRate,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 44100, child: Text('44100 Hz')),
                DropdownMenuItem(value: 48000, child: Text('48000 Hz')),
              ],
              onChanged: (v) {
                if (v != null) controller.setSampleRate(v);
              },
            ),
          ),
          ListTile(
            title: const Text('Recording quality'),
            subtitle: Text(settings.recordingQuality),
            trailing: DropdownButton<String>(
              value: settings.recordingQuality,
              underline: const SizedBox.shrink(),
              items: RecordingQuality.values
                  .map((q) => DropdownMenuItem(
                        value: q.name,
                        child: Text(q.name),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  controller
                      .setRecordingQuality(RecordingQuality.values.byName(v));
                }
              },
            ),
          ),
          const Divider(),
          _SectionHeader('Voice Themes'),
          ListTile(
            title: const Text('Default theme'),
            subtitle: Text(
              VoiceTheme.values.byName(settings.defaultVoiceTheme).label,
            ),
            trailing: DropdownButton<String>(
              value: settings.defaultVoiceTheme,
              underline: const SizedBox.shrink(),
              items: VoiceTheme.values
                  .map((t) => DropdownMenuItem(
                        value: t.name,
                        child: Text(t.label),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  controller.setDefaultVoiceTheme(VoiceTheme.values.byName(v));
                }
              },
            ),
          ),
          const Divider(),
          _SectionHeader('Backup & Sync'),
          ListTile(
            title: const Text('Cloud backup'),
            subtitle: Text(isSignedIn ? 'Signed in with Google' : 'Not signed in'),
            trailing: TextButton(
              onPressed: () => showSignInSheet(context),
              child: Text(isSignedIn ? 'Manage' : 'Sign in'),
            ),
          ),
          SwitchListTile(
            title: const Text('Automatic background backup'),
            value: settings.autoBackupEnabled,
            onChanged: controller.setAutoBackup,
          ),
          SwitchListTile(
            title: const Text('Back up on Wi-Fi only'),
            value: settings.backupOnWifiOnly,
            onChanged: controller.setBackupOnWifiOnly,
          ),
          const Divider(),
          _SectionHeader('Storage'),
          ListTile(
            title: const Text('Local storage used'),
            subtitle: Text(
              storageAsync.when(
                data: (bytes) => Formatters.fileSize(bytes),
                loading: () => 'Calculating…',
                error: (_, __) => 'Unknown',
              ),
            ),
          ),
          const Divider(),
          _SectionHeader('Appearance'),
          ListTile(
            title: const Text('Theme'),
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'system', label: Text('Auto')),
                ButtonSegment(value: 'light', label: Text('Light')),
                ButtonSegment(value: 'dark', label: Text('Dark')),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (selection) {
                final mode = switch (selection.first) {
                  'light' => ThemeMode.light,
                  'dark' => ThemeMode.dark,
                  _ => ThemeMode.system,
                };
                controller.setThemeMode(mode);
              },
            ),
          ),
          const Divider(),
          _SectionHeader('About'),
          const ListTile(
            title: Text('VoiceCraft AI'),
            subtitle: Text('Version 1.0.0'),
          ),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text('Privacy Policy'),
                  content: SingleChildScrollView(
                    child: Text(
                      'VoiceCraft AI processes audio entirely on-device. '
                      'Recordings are never uploaded unless you sign in with '
                      'Google and enable cloud backup, in which case audio is '
                      'stored in Firebase Storage and metadata in Firestore, '
                      'both scoped to your account. See the full policy at '
                      'your published Privacy Policy URL before release.',
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

final FutureProvider<int> _localStorageBytesProvider =
    FutureProvider<int>((ref) {
  return ref.read(storageUsageServiceProvider).recordingsDirectoryBytes();
});

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
