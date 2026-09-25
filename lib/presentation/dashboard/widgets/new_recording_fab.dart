import 'package:flutter/material.dart';

/// The landing screen's + button, which opens into two choices rather than
/// going straight to the recorder: capture something new, or bring in audio
/// that already exists on the device.
///
/// Built as an expanding speed dial instead of a bottom sheet so the two
/// options appear next to the thumb that just tapped +, and a second tap on
/// the same spot closes it again.
class NewRecordingFab extends StatefulWidget {
  final VoidCallback onRecord;
  final VoidCallback onUpload;

  const NewRecordingFab({
    super.key,
    required this.onRecord,
    required this.onUpload,
  });

  @override
  State<NewRecordingFab> createState() => _NewRecordingFabState();
}

class _NewRecordingFabState extends State<NewRecordingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _expand = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutBack,
    reverseCurve: Curves.easeIn,
  );

  bool _open = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    if (_open) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _choose(VoidCallback action) {
    _toggle();
    action();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Action(
          animation: _expand,
          icon: Icons.library_music_rounded,
          label: 'Upload a recording',
          onPressed: () => _choose(widget.onUpload),
        ),
        const SizedBox(height: 12),
        _Action(
          animation: _expand,
          icon: Icons.mic_rounded,
          label: 'Record a new one',
          onPressed: () => _choose(widget.onRecord),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            // + rotates into ×, so the button says what a second tap does.
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 220),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
      ],
    );
  }
}

class _Action extends StatelessWidget {
  final Animation<double> animation;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _Action({
    required this.animation,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: animation,
      alignment: Alignment.bottomRight,
      child: FadeTransition(
        opacity: animation,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              elevation: 2,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              heroTag: label,
              onPressed: onPressed,
              child: Icon(icon),
            ),
          ],
        ),
      ),
    );
  }
}
