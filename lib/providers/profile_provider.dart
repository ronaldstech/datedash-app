import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../services/chat_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserProfile? _userProfile;
  User? _currentUser;
  StreamSubscription<User?>? _userSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  int _currentTabIndex = 0;
  int _likesCount = 0;
  int _visitorsCount = 0;
  int _matchesCount = 0;
  int _unreadMessageCount = 0;
  int _swipesVersion = 0;
  int _initialPremiumTab = 0;
  StreamSubscription<int>? _likesCountSubscription;
  StreamSubscription<int>? _visitorsCountSubscription;
  StreamSubscription<int>? _matchesCountSubscription;
  StreamSubscription<int>? _unreadMessageCountSubscription;
  double _swipeOffset = 0.0;
  String? _lastSwipedUserId;

  ProfileProvider() {
    _userSubscription = FirebaseAuth.instance.userChanges().listen((user) {
      _currentUser = user;
      _profileSubscription?.cancel();

      if (user != null) {
        _profileSubscription = _profileService
            .getUserProfileStream(user.uid)
            .listen((profile) {
          _userProfile = profile;
          notifyListeners();
        });

        _likesCountSubscription?.cancel();
        _likesCountSubscription = _profileService
            .getLikesCountStream(user.uid)
            .listen((count) {
          _likesCount = count;
          notifyListeners();
        });

        _visitorsCountSubscription?.cancel();
        _visitorsCountSubscription = _profileService
            .getViewCountStream(user.uid)
            .listen((count) {
          _visitorsCount = count;
          notifyListeners();
        });

        _matchesCountSubscription?.cancel();
        _matchesCountSubscription = _profileService
            .getMatchesCountStream(user.uid)
            .listen((count) {
          _matchesCount = count;
          notifyListeners();
        });

        _unreadMessageCountSubscription?.cancel();
        _unreadMessageCountSubscription = _chatService
            .getUnreadMessageCountStream(user.uid)
            .listen((count) {
          _unreadMessageCount = count;
          notifyListeners();
        });
      } else {
        _userProfile = null;
        _likesCount = 0;
        _visitorsCount = 0;
        _matchesCount = 0;
        _unreadMessageCount = 0;
        _likesCountSubscription?.cancel();
        _visitorsCountSubscription?.cancel();
        _matchesCountSubscription?.cancel();
        _unreadMessageCountSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  UserProfile? get userProfile => _userProfile;
  User? get currentUser => _currentUser;
  int get currentTabIndex => _currentTabIndex;
  int get likesCount => _likesCount;
  
  /// Returns the count for the Likes badge: 
  /// - Full count if Premium
  /// - Unlocked profiles count if not Premium
  int get unlockedLikesCount {
    if (_userProfile?.isPremium == true) return _likesCount;
    return _userProfile?.unlockedLikes.length ?? 0;
  }

  int get visitorsCount => _visitorsCount;
  int get matchesCount => _matchesCount;
  int get unreadMessageCount => _unreadMessageCount;
  int get swipesVersion => _swipesVersion;
  double get swipeOffset => _swipeOffset;
  int get initialPremiumTab => _initialPremiumTab;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void navigateToPremium(int subTabIndex) {
    _currentTabIndex = 4; // Premium Tab
    _initialPremiumTab = subTabIndex;
    notifyListeners();
  }

  /// Resets swipe history in Firestore and signals SwipeView to reload.
  Future<void> resetSwipes() async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    await _profileService.resetSwipes(uid);
    _swipesVersion++;
    notifyListeners();
  }

  void updateSwipeOffset(double offset) {
    _swipeOffset = offset;
    notifyListeners();
  }

  void resetSwipeOffset() {
    _swipeOffset = 0.0;
    notifyListeners();
  }

  /// Saves or updates a UserProfile in Firestore
  Future<void> saveUserProfile(String uid, UserProfile profile) async {
    try {
      await _profileService.saveUserProfile(uid, profile);
      // Local profile is updated via the stream listener in constructor
    } catch (e) {
      debugPrint('ProfileProvider: Error saving profile: $e');
      rethrow;
    }
  }

  /// Updates and saves the user's swipe filter preferences
  Future<void> updateFilters(int minAge, int maxAge, double maxDistance, String gender, bool ageStrict, bool distanceStrict) async {
    if (_userProfile == null || _currentUser == null) return;
    
    _userProfile!.filterMinAge = minAge;
    _userProfile!.filterMaxAge = maxAge;
    _userProfile!.filterMaxDistance = maxDistance;
    _userProfile!.filterGender = gender;
    _userProfile!.filterAgeStrict = ageStrict;
    _userProfile!.filterDistanceStrict = distanceStrict;
    
    notifyListeners();
    
    try {
      await saveUserProfile(_currentUser!.uid, _userProfile!);
      // Increment swipes version to force a reload of the swiping stack with new filters
      _swipesVersion++;
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileProvider: Error saving filters: $e');
      rethrow;
    }
  }

  /// Deducts credits from the current user
  Future<void> useCredits(int amount) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    try {
      await _profileService.deductCredits(uid, amount);
      // Local state will update via stream
    } catch (e) {
      debugPrint('ProfileProvider: Error using credits: $e');
      rethrow;
    }
  }

  /// Unlocks a specific profile for 20 credits
  Future<void> unlockProfile(String targetId) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    try {
      // 1. Deduct 20 credits
      await useCredits(20);
      
      // 2. Add to unlockedLikes in Firestore
      await _profileService.unlockProfile(uid, targetId);
      
      // 3. Update local state
      _userProfile?.unlockedLikes.add(targetId);
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileProvider: Error unlocking profile: $e');
      rethrow;
    }
  }

  /// Sets the last swiped user ID for potential rewind
  void setLastSwipedUserId(String? uid) {
    _lastSwipedUserId = uid;
    notifyListeners();
  }

  /// Performs the rewind action on the backend
  Future<void> rewindSwipe() async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null || _lastSwipedUserId == null) return;

    try {
      await _profileService.undoLastSwipe(myUid, _lastSwipedUserId!);
      _lastSwipedUserId = null;
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileProvider: Error rewinding swipe: $e');
      rethrow;
    }
  }

  String? get lastSwipedUserId => _lastSwipedUserId;

  /// Returns the display name with fallback logic:
  /// Firestore firstName -> Google displayName -> 'Guest User'
  String get displayName {
    if (_userProfile?.firstName != null && _userProfile!.firstName!.isNotEmpty) {
      return _userProfile!.firstName!;
    }
    return _currentUser?.displayName ?? 'Guest User';
  }

  /// Returns the photo URL with fallback logic:
  /// Firestore first photo -> Google photoURL -> null
  String? get photoURL {
    if (_userProfile?.photos != null && _userProfile!.photos.isNotEmpty) {
      return _userProfile!.photos.first;
    }
    if (_currentUser?.photoURL != null && _currentUser!.photoURL!.isNotEmpty) {
      return _currentUser!.photoURL;
    }
    return null;
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    _profileSubscription?.cancel();
    _likesCountSubscription?.cancel();
    _visitorsCountSubscription?.cancel();
    _matchesCountSubscription?.cancel();
    _unreadMessageCountSubscription?.cancel();
    super.dispose();
  }
}
