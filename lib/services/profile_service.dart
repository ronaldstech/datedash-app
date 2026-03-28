import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Fetches a UserProfile from Firestore
  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return UserProfile.fromMap(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Saves or updates a UserProfile in Firestore
  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    try {
      await _usersCollection.doc(uid).set(
        profile.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  /// Listens for changes to a UserProfile from Firestore
  Stream<UserProfile?> getUserProfileStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        data['uid'] = doc.id;
        return UserProfile.fromMap(data);
      }
      return null;
    });
  }

  /// Fetches a list of other users for swiping, excluding those already swiped on
  Future<List<UserProfile>> getSwipeProfiles(String currentUserId) async {
    try {
      debugPrint('Fetching swipe profiles for user: $currentUserId');
      
      // Get UIDs of users already swiped on (likes/dislikes)
      final swipedQuery = await _firestore
          .collection('swipes')
          .where('fromId', isEqualTo: currentUserId)
          .get();
      
      final swipedIds = swipedQuery.docs.map((doc) => doc['toId'] as String).toSet();
      debugPrint('Users already swiped on: ${swipedIds.length}');

      // Basic implementation: fetch all users (ideal for this scale)
      QuerySnapshot snapshot = await _usersCollection.get();
      
      final filteredDocs = snapshot.docs.where((doc) {
        return doc.id != currentUserId && !swipedIds.contains(doc.id);
      }).toList();
      
      debugPrint('Users after filtering: ${filteredDocs.length}');

      List<UserProfile> profiles = [];
      for (var doc in filteredDocs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id;
          profiles.add(UserProfile.fromMap(data));
        } catch (e) {
          debugPrint('Error parsing user ${doc.id}: $e');
        }
      }
      
      return profiles;
    } catch (e) {
      debugPrint('Error fetching swipe profiles globally: $e');
      return [];
    }
  }

  /// Records a swipe (like/dislike) in Firestore
  Future<void> swipeUser(String fromId, String toId, String type) async {
    try {
      await _firestore.collection('swipes').add({
        'fromId': fromId,
        'toId': toId,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error recording swipe: $e');
    }
  }

  /// Returns a stream of profiles who liked the current user
  Stream<List<UserProfile>> getReceivedLikesStream(String userId) {
    return _firestore
        .collection('swipes')
        .where('toId', isEqualTo: userId)
        .where('type', isEqualTo: 'like')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((swipedSnapshot) async {
      List<UserProfile> profiles = [];
      for (var doc in swipedSnapshot.docs) {
        final fromId = doc['fromId'] as String;
        final profile = await getUserProfile(fromId);
        if (profile != null) {
          profiles.add(profile);
        }
      }
      return profiles;
    });
  }
}
