import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile_model.dart';
import '../services/notification_service.dart';

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
      debugPrint('Total users in Firestore: ${snapshot.docs.length}');
      
      final filteredDocs = snapshot.docs.where((doc) {
        final isSelf = doc.id == currentUserId;
        final isSwiped = swipedIds.contains(doc.id);
        
        if (isSelf) debugPrint('Filtering out self: ${doc.id}');
        if (isSwiped) debugPrint('Filtering out swiped: ${doc.id}');
        
        return !isSelf && !isSwiped;
      }).toList();
      
      debugPrint('Users after filtering: ${filteredDocs.length}');

      List<UserProfile> profiles = [];
      for (var doc in filteredDocs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id;
          final profile = UserProfile.fromMap(data);
          
          // Debugging: check if profile is being parsed correctly
          if (profile.firstName == null) {
            debugPrint('Warning: User ${doc.id} has no firstName');
          }
          
          profiles.add(profile);
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
  Future<void> swipeUser(String fromId, String toId, String type,
      {String? senderName}) async {
    try {
      final swipeId = '${fromId}_$toId';
      await _firestore.collection('swipes').doc(swipeId).set({
        'fromId': fromId,
        'toId': toId,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (type == 'like') {
        // Check for mutual like (a "Match")
        final reverseLike = await _firestore
            .collection('swipes')
            .where('fromId', isEqualTo: toId)
            .where('toId', isEqualTo: fromId)
            .where('type', isEqualTo: 'like')
            .limit(1)
            .get();

        if (reverseLike.docs.isNotEmpty) {
          // It's a MATCH!
          debugPrint('ProfileService: IT\'S A MATCH between $fromId and $toId!');
          final matchId = fromId.compareTo(toId) < 0 ? '${fromId}_$toId' : '${toId}_$fromId';
          
          final matchDoc = await _firestore.collection('matches').doc(matchId).get();
          
          if (!matchDoc.exists) {
            await _firestore.collection('matches').doc(matchId).set({
              'uids': [fromId, toId],
              'timestamp': FieldValue.serverTimestamp(),
            });

            // Notify opposite user of the match
            await NotificationService().sendNotification(
              recipientId: toId,
              senderId: fromId,
              senderName: senderName ?? 'Someone',
              type: 'match',
            );
          }
        } else {
          // Regular like notification
          // We can skip checking old like existence for now since swipeId .set() prevents DB duplication
          debugPrint(
              'ProfileService: Sending like notification to $toId from $fromId ($senderName)');
          await NotificationService().sendNotification(
            recipientId: toId,
            senderId: fromId,
            senderName: senderName ?? 'Someone',
            type: 'like',
          );
        }
      }
    } catch (e) {
      debugPrint('Error recording swipe: $e');
    }
  }

  /// Removes a swipe record and associated match if it exists
  Future<void> undoLastSwipe(String fromId, String toId) async {
    try {
      final swipeId = '${fromId}_$toId';
      final matchId = fromId.compareTo(toId) < 0 ? '${fromId}_$toId' : '${toId}_$fromId';

      final batch = _firestore.batch();
      
      // Delete swipe doc
      batch.delete(_firestore.collection('swipes').doc(swipeId));
      
      // Attempt to delete match doc (it might not exist, but batch.delete is safe if we have the ref)
      batch.delete(_firestore.collection('matches').doc(matchId));

      await batch.commit();
      debugPrint('ProfileService: Undo swipe and match for $swipeId');
    } catch (e) {
      debugPrint('Error undoing swipe: $e');
      rethrow;
    }
  }

  /// Returns a stream of mutual matches for a user
  Stream<List<UserProfile>> getMatchesStream(String userId) {
    return _firestore
        .collection('matches')
        .where('uids', arrayContains: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserProfile> profiles = [];
      for (var doc in snapshot.docs) {
        final List<dynamic> uids = doc['uids'];
        final otherId = uids.firstWhere((id) => id != userId, orElse: () => null);
        if (otherId != null) {
          final profile = await getUserProfile(otherId);
          if (profile != null) {
            profiles.add(profile);
          }
        }
      }
      return profiles;
    });
  }

  /// Deletes all swipe records made by the user — resets who they can see
  Future<void> resetSwipes(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('swipes')
          .where('fromId', isEqualTo: userId)
          .get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('Swipes reset for user: $userId (${snapshot.docs.length} records deleted)');
    } catch (e) {
      debugPrint('Error resetting swipes: $e');
      rethrow;
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

  /// Returns a stream of the number of likes the current user has received
  Stream<int> getLikesCountStream(String userId) {
    return _firestore
        .collection('swipes')
        .where('toId', isEqualTo: userId)
        .where('type', isEqualTo: 'like')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Returns a stream of the number of matches for the current user
  Stream<int> getMatchesCountStream(String userId) {
    return _firestore
        .collection('matches')
        .where('uids', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Returns a stream of profiles who are looking for a specific category
  Stream<List<UserProfile>> getProfilesByCategory(String category, String currentUserId) {
    return _usersCollection
        .where('lookingFor', arrayContains: category)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .where((doc) => doc.id != currentUserId)
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['uid'] = doc.id;
                return UserProfile.fromMap(data);
              }).toList();
        });
  }

  /// Fetches swipeable profiles filtered by a lookingFor category, excluding already-swiped users
  Future<List<UserProfile>> getSwipeProfilesByCategory(String currentUserId, String category) async {
    try {
      final swipedQuery = await _firestore
          .collection('swipes')
          .where('fromId', isEqualTo: currentUserId)
          .get();
      final swipedIds = swipedQuery.docs.map((doc) => doc['toId'] as String).toSet();

      final snapshot = await _usersCollection
          .where('lookingFor', arrayContains: category)
          .get();

      List<UserProfile> profiles = [];
      for (var doc in snapshot.docs) {
        if (doc.id == currentUserId) continue;
        if (swipedIds.contains(doc.id)) continue;
        try {
          final data = doc.data() as Map<String, dynamic>;
          data['uid'] = doc.id;
          profiles.add(UserProfile.fromMap(data));
        } catch (e) {
          debugPrint('Error parsing profile ${doc.id}: $e');
        }
      }
      return profiles;
    } catch (e) {
      debugPrint('Error fetching category swipe profiles: $e');
      return [];
    }
  }

  /// Returns a stream of the number of users in a specific category
  Stream<int> getCategoryCountStream(String category) {
    return _usersCollection
        .where('lookingFor', arrayContains: category)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Records a profile view in Firestore - Ensures it only happens once per viewer/target pair
  Future<void> recordProfileView(String viewerId, String targetId,
      {String? senderName}) async {
    if (viewerId == targetId) return;

    try {
      final viewId = 'view_${viewerId}_$targetId';
      final docRef = _firestore.collection('profile_views').doc(viewId);

      // Check if this specific view has already been recorded in the new format
      final doc = await docRef.get();
      if (doc.exists) {
        debugPrint('ProfileService: view $viewId already exists, skipping write.');
        return;
      }

      // Record the deterministic view only if it doesn't exist
      await docRef.set({
        'fromId': viewerId,
        'toId': targetId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('ProfileService: recorded new view $viewId');
    } catch (e) {
      debugPrint('Error recording profile view: $e');
    }
  }

  /// Returns a stream of the number of views a user has received
  Stream<int> getViewCountStream(String userId) {
    return _firestore
        .collection('profile_views')
        .where('toId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Returns a stream of profiles and viewing timestamps for the current user
  Stream<List<Map<String, dynamic>>> getViewersStream(String userId) {
    return _firestore
        .collection('profile_views')
        .where('toId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<Map<String, dynamic>> viewerData = [];
      final Set<String> processedIds = {};

      for (var doc in snapshot.docs) {
        final fromId = doc['fromId'] as String;
        final timestamp = doc['timestamp'] as Timestamp?;

        if (!processedIds.contains(fromId)) {
          final profile = await getUserProfile(fromId);
          if (profile != null) {
            viewerData.add({
              'profile': profile,
              'timestamp': timestamp,
            });
            processedIds.add(fromId);
          }
        }
      }
      return viewerData;
    });
  }
}
