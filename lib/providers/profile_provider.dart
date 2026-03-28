import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';

class ProfileProvider with ChangeNotifier {
  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  User? _currentUser;
  StreamSubscription<User?>? _userSubscription;
  StreamSubscription<UserProfile?>? _profileSubscription;
  int _currentTabIndex = 0;

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
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  UserProfile? get userProfile => _userProfile;
  User? get currentUser => _currentUser;
  int get currentTabIndex => _currentTabIndex;

  void setTabIndex(int index) {
    _currentTabIndex = index;
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
    super.dispose();
  }
}
