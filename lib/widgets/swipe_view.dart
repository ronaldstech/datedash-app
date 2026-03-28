import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';
import 'action_button.dart';
import 'profile_detail_sheet.dart';

class SwipeView extends StatefulWidget {
  const SwipeView({super.key});

  @override
  State<SwipeView> createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> {
  final ProfileService _profileService = ProfileService();
  List<UserProfile> _profiles = [];
  int _currentIndex = 0;
  int _currentPhotoIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    debugPrint('SwipeView: _loadProfiles started');
    final profileProvider = context.read<ProfileProvider>();
    final currentUser = profileProvider.currentUser;
    
    if (currentUser != null) {
      debugPrint('SwipeView: Fetching profiles for UID: ${currentUser.uid}');
      try {
        final profiles = await _profileService.getSwipeProfiles(currentUser.uid);
        debugPrint('SwipeView: Fetched ${profiles.length} profiles');
        if (mounted) {
          setState(() {
            _profiles = profiles;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('SwipeView: Error loading profiles: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      debugPrint('SwipeView: No current user found in ProfileProvider');
      // If no user yet, wait a bit and try again (simple retry)
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) _loadProfiles();
      });
    }
  }

  void _nextProfile() {
    setState(() {
      if (_profiles.isNotEmpty) {
        if (_currentIndex < _profiles.length - 1) {
          _currentIndex++;
        } else {
          // No more profiles for now, could fetch more
          _currentIndex = 0; // Loop for demo or show empty
        }
        _currentPhotoIndex = 0; // Reset photo index for new profile
      }
    });
  }

  void _nextPhoto(int totalPhotos) {
    if (_currentPhotoIndex < totalPhotos - 1) {
      setState(() {
        _currentPhotoIndex++;
      });
    } else {
      // Logic for if they tap right on last photo - maybe move to next profile?
      // Some apps move to next, others just stay on last. Let's stay for now.
    }
  }

  void _prevPhoto() {
    if (_currentPhotoIndex > 0) {
      setState(() {
        _currentPhotoIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF4D85),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.user_search,
              size: 64,
              color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No more profiles nearby',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    final profile = _profiles[_currentIndex];
    final photos = profile.photos.isNotEmpty ? profile.photos : ['https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=800&auto=format&fit=crop'];
    final photoUrl = _currentPhotoIndex < photos.length ? photos[_currentPhotoIndex] : photos.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width - 32; // Screen width minus padding
                if (details.localPosition.dx < width * 0.3) {
                  _prevPhoto();
                } else {
                  _nextPhoto(photos.length);
                }
              },
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Main Background Image
                    Positioned.fill(
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF4D85),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('SwipeView: Image load error: $error');
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(
                                Iconsax.image,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.4), // Top gradient for indicators
                              Colors.transparent,
                              Colors.black.withOpacity(0.85), // Bottom gradient for info
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Photo Indicators (Top)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        children: List.generate(
                          photos.length,
                          (index) => Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: index == _currentPhotoIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Profile Info (Bottom)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${profile.firstName ?? 'Someone'}, ${profile.age ?? '??'}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (profile.isVerified) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.blueAccent,
                                        size: 24,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Consumer<ProfileProvider>(
                                  builder: (context, profileProvider, _) {
                                    return Row(
                                      children: [
                                        const Icon(
                                          Iconsax.location,
                                          color: Colors.white70,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          profile.getDistanceDisplay(profileProvider.userProfile),
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Arrow Up Button for full details
                          GestureDetector(
                            onTap: () => _showProfileDetails(profile),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.keyboard_arrow_up,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 28,
                                  ),
                                  Text(
                                    'Pull for details',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButton(
                icon: Iconsax.close_circle,
                color: const Color(0xFFFF5E5E),
                onTap: _nextProfile,
                size: 64,
              ),
              ActionButton(
                icon: Iconsax.heart5,
                color: Theme.of(context).colorScheme.primary,
                onTap: _nextProfile,
                size: 64,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showProfileDetails(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(
        profile: profile,
        onLike: () {
          Navigator.pop(context);
          _nextProfile();
        },
        onDislike: () {
          Navigator.pop(context);
          _nextProfile();
        },
        onMessage: () {
          final profileProvider = context.read<ProfileProvider>();
          if (profile.allowMessages) {
            Navigator.pop(context);
            profileProvider.setTabIndex(3);
          } else {
            _showPremiumSnack('This user has disabled direct messaging.');
          }
        },
      ),
    );
  }

  void _showPremiumSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFFF4D85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}
