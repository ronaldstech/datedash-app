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
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
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
        return UserProfile.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  /// Fetches a list of other users for swiping
  Future<List<UserProfile>> getSwipeProfiles(String currentUserId) async {
    try {
      debugPrint('Fetching swipe profiles for user: $currentUserId');
      
      // Basic implementation: fetch all users
      QuerySnapshot snapshot = await _usersCollection.get();
      
      debugPrint('Total users found in Firestore: ${snapshot.docs.length}');
      
      final filteredDocs = snapshot.docs.where((doc) => doc.id != currentUserId).toList();
      debugPrint('Users after filtering current user: ${filteredDocs.length}');

      List<UserProfile> profiles = [];
      for (var doc in filteredDocs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          profiles.add(UserProfile.fromMap(data));
        } catch (e) {
          debugPrint('Error parsing user ${doc.id}: $e');
        }
      }
      
      debugPrint('Successfully parsed profiles: ${profiles.length}');
      return profiles;
    } catch (e) {
      debugPrint('Error fetching swipe profiles globally: $e');
      return [];
    }
  }
}
