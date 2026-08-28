import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../shared/widgets/static_waveform.dart';
import '../controller/editor_controller.dart';

/// Waveform editor surface: pinch-to-zoom, horizontal scroll once zoomed,
/// tap-to-seek, and drag handles at the edges of the current selection —
/// the primitives every operation in [EditorController] (trim/split/
/// delete/copy/fade/volume) reads its start/end from.
class InteractiveWaveform extends StatefulWidget {
  final List<double> samples;
  final EditorSelection selection;
  final double zoom;
  final double playbackProgress;
  final ValueChanged<EditorSelection> onSelectionChanged;
  final ValueChanged<double> onZoomChanged;
  final ValueChanged<double> onSeek;

  const InteractiveWaveform({
    super.key,
    required this.samples,
    required this.selection,
    required this.zoom,
    required this.playbackProgress,
    required this.onSelectionChanged,
    required this.onZoomChanged,
    required this.onSeek,
  });

  @override
  State<InteractiveWaveform> createState() => _InteractiveWaveformState();
}

class _InteractiveWaveformState extends State<InteractiveWaveform> {
  double _zoomStart = 1.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final contentWidth = viewportWidth * widget.zoom;

        return GestureDetector(
          onScaleStart: (_) => _zoomStart = widget.zoom,
          onScaleUpdate: (details) {
            widget.onZoomChanged(_zoomStart * details.scale);
          },
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: contentWidth,
              height: 140,
              child: Stack(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (details) {
                      widget.onSeek(
                        (details.localPosition.dx / contentWidth).clamp(0, 1),
                      );
                    },
                    child: StaticWaveform(
                      samples: widget.samples,
                      progress: widget.playbackProgress,
                      selection: (widget.selection.start, widget.selection.end),
                      height: 140,
                    ),
                  ),
                  _Handle(
                    x: widget.selection.start * contentWidth,
                    onDrag: (dx) {
                      final frac = ((widget.selection.start * contentWidth) + dx) /
                          contentWidth;
                      widget.onSelectionChanged(
                        widget.selection.copyWith(start: frac.clamp(0, 1)),
                      );
                    },
                  ),
                  _Handle(
                    x: widget.selection.end * contentWidth,
                    onDrag: (dx) {
                      final frac = ((widget.selection.end * contentWidth) + dx) /
                          contentWidth;
                      widget.onSelectionChanged(
                        widget.selection.copyWith(end: frac.clamp(0, 1)),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Handle extends StatelessWidget {
  final double x;
  final ValueChanged<double> onDrag;

  const _Handle({required this.x, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - 10,
      top: 0,
      bottom: 0,
      width: 20,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Center(
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
