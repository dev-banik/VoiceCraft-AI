import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import 'controller/auth_controller.dart';

/// Bottom sheet shown when the user taps "Backup my recordings" / the cloud
/// icon. Google Sign-In only becomes relevant here — everything else in the
/// app works without ever seeing this sheet.
void showSignInSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const SignInSheet(),
  );
}

class SignInSheet extends ConsumerWidget {
  const SignInSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = ref.watch(isSignedInProvider);
    final user = ref.watch(authStateProvider).valueOrNull;
    final authState = ref.watch(authControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSignedIn ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isSignedIn ? 'Cloud backup is on' : 'Backup my recordings',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              isSignedIn
                  ? 'Signed in as ${user?.email ?? ''}. Your recordings sync '
                      'automatically across devices using this Google account.'
                  : 'Sign in with Google to back up recordings to the cloud '
                      'and access them from any device. Everything still '
                      'works fully offline without this.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            if (authState.isLoading)
              const CircularProgressIndicator()
            else if (isSignedIn)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  child: const Text('Sign out'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: const Text('Continue with Google'),
                  onPressed: () async {
                    final result =
                        await ref.read(authControllerProvider.notifier).signIn();
                    if (context.mounted && result.isOk) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            if (authState.hasError) ...[
              const SizedBox(height: 12),
              Text(
                '${authState.error}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
