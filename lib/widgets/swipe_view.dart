import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';
import 'action_button.dart';

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
                      ),
                    ),
                    // Gradient Overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.35), // Top gradient for indicators
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
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${profile.firstName ?? 'Someone'}, ${profile.age ?? '??'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
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
                                  size: 26,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Iconsax.location,
                                color: Colors.white70,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                profile.location ?? 'Somewhere',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              profile.bio!,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionButton(
                icon: Iconsax.close_circle,
                color: const Color(0xFFFF5E5E),
                onTap: _nextProfile,
                size: 68,
              ),
              ActionButton(
                icon: Iconsax.heart5,
                color: Theme.of(context).colorScheme.primary,
                onTap: _nextProfile,
                size: 68,
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
