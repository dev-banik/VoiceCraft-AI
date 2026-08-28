import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/exceptions.dart';

/// Firebase Storage access for recording audio files, stored under
/// `users/{uid}/recordings/{recordingId}.<ext>`. Access is scoped per-uid by
/// firebase/storage.rules.
class StorageDatasource {
  final FirebaseStorage _storage;

  StorageDatasource({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> upload({
    required String uid,
    required String recordingId,
    required String localPath,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final file = File(localPath);
      final ext = localPath.split('.').last;
      final ref = _storage
          .ref()
          .child(AppConstants.userRecordingsPath(uid))
          .child('$recordingId.$ext');

      final task = ref.putFile(file);
      if (onProgress != null) {
        task.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            onProgress(snapshot.bytesTransferred / snapshot.totalBytes);
          }
        });
      }
      final snapshot = await task;
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      throw SyncException('Failed to upload audio: $e');
    }
  }

  Future<File> download({
    required String cloudUrl,
    required String destinationPath,
  }) async {
    try {
      final ref = _storage.refFromURL(cloudUrl);
      final file = File(destinationPath);
      await ref.writeToFile(file);
      return file;
    } catch (e) {
      throw SyncException('Failed to download audio: $e');
    }
  }

  Future<void> delete(String uid, String recordingId, String extension) async {
    try {
      final ref = _storage
          .ref()
          .child(AppConstants.userRecordingsPath(uid))
          .child('$recordingId.$extension');
      await ref.delete();
    } catch (_) {
      // Missing remote object is not fatal for a local delete flow.
    }
  }
}
