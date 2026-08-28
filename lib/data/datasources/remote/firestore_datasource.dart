import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/error/exceptions.dart';
import '../../models/recording_model.dart';

/// Firestore access for recording metadata. Schema:
///   users/{uid}/recordings/{recordingId} -> RecordingModel.toFirestore()
/// See docs/FIRESTORE_SCHEMA.md for the full field reference and
/// firebase/firestore.rules for the access-control rules.
class FirestoreDatasource {
  final FirebaseFirestore _firestore;

  FirestoreDatasource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _recordings(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection(AppConstants.recordingsSubcollection);
  }

  Future<void> upsertMetadata(String uid, RecordingModel model) async {
    try {
      await _recordings(uid).doc(model.id).set(model.toFirestore());
    } catch (e) {
      throw SyncException('Failed to upload metadata: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAll(String uid) async {
    try {
      final snapshot = await _recordings(uid).get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (e) {
      throw SyncException('Failed to fetch metadata: $e');
    }
  }

  Future<void> deleteMetadata(String uid, String recordingId) async {
    try {
      await _recordings(uid).doc(recordingId).delete();
    } catch (e) {
      throw SyncException('Failed to delete metadata: $e');
    }
  }

  Future<void> ensureUserProfile(
    String uid,
    Map<String, dynamic> profile,
  ) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(profile, SetOptions(merge: true));
    } catch (e) {
      throw SyncException('Failed to create user profile: $e');
    }
  }
}
