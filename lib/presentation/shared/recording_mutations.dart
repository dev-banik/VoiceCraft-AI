import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di/providers.dart';
import '../../domain/entities/recording_entity.dart';
import '../playback/controller/playback_controller.dart';

/// Applies [patch] to the freshest stored copy of the recording [id] and
/// persists the result.
///
/// Every screen that attaches a derivative to a recording (noise removal,
/// voice themes, enhancement, editor) goes through here, for two reasons:
///
///  * the patch is applied to what is in storage *now*, not to the entity the
///    screen happened to be built with. Screens hold onto a recording for as
///    long as they are open, so patching that copy would silently roll back
///    any derivative saved from another screen in the meantime.
///  * [recordingByIdProvider] is invalidated afterwards. It has no
///    `autoDispose`, so without this every screen keeps rendering the entity
///    from the very first read — which is how a saved noise-removed version
///    could show up on the dashboard (backed by a live Hive stream) while the
///    playback screen still offered nothing but the original.
///
/// Returns the persisted entity, or `null` if the recording is gone or the
/// write failed.
Future<RecordingEntity?> saveRecordingPatch(
  Ref ref,
  String id,
  RecordingEntity Function(RecordingEntity current) patch,
) async {
  final usecases = ref.read(recordingUsecasesProvider);
  final current = (await usecases.getById(id)).valueOrNull;
  if (current == null) return null;

  final updated = patch(current);
  final result = await usecases.save(updated);
  if (result.isErr) return null;

  ref.invalidate(recordingByIdProvider(id));
  return updated;
}
