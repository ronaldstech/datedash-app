import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';
import '../services/chat_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  final ChatService _chatService = ChatService();
  UserProfile? _userProfile;
  User? _currentUser;
  StreamSubscription<User?>? _userSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  int _currentTabIndex = 0;
  int _likesCount = 0;
  int _unreadMessageCount = 0;
  int _swipesVersion = 0; // increments on each reset to signal SwipeView
  StreamSubscription<int>? _likesCountSubscription;
  StreamSubscription<int>? _unreadMessageCountSubscription;

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
        _unreadMessageCount = 0;
        _likesCountSubscription?.cancel();
        _unreadMessageCountSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  UserProfile? get userProfile => _userProfile;
  User? get currentUser => _currentUser;
  int get currentTabIndex => _currentTabIndex;
  int get likesCount => _likesCount;
  int get unreadMessageCount => _unreadMessageCount;
  int get swipesVersion => _swipesVersion;

  void setTabIndex(int index) {
    _currentTabIndex = index;
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
    _unreadMessageCountSubscription?.cancel();
    super.dispose();
  }
}
