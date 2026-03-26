// ============================================================
// PriVault – Profile Repository (Firebase)
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository(this._firestore);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<Map<String, dynamic>> getMyProfile() async {
    final doc = await _firestore.collection('users').doc(_uid).get();
    final data = doc.data() ?? {};
    return {
      'id': _uid,
      'email': FirebaseAuth.instance.currentUser?.email,
      ...data,
    };
  }

  Future<Map<String, dynamic>> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? publicKey,
    String? salt,
  }) async {
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (publicKey != null) updates['public_key'] = publicKey;
    if (salt != null) updates['salt'] = salt;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(_uid).update(updates);
    }

    return getMyProfile();
  }
}
