import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../screens/chat_screen.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import 'action_button.dart';
import 'profile_detail_sheet.dart';
import '../screens/edit_profile_screen.dart';

class SwipeView extends StatefulWidget {
  const SwipeView({super.key});

  @override
  State<SwipeView> createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> with TickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  List<UserProfile> _profiles = [];
  int _currentIndex = 0;
  int _currentPhotoIndex = 0;
  bool _isLoading = true;
  int _lastSwipesVersion = -1;

  bool _isFetching = false;
  int _freeSwipesUsed = 0; // tracks swipes used when user has < 4 photos

  // Swipe Animation State
  Offset _dragOffset = Offset.zero;
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _swipeController, curve: Curves.easeOutBack));

    _loadProfiles();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profileProvider = context.watch<ProfileProvider>();
    final user = profileProvider.currentUser;
    final version = profileProvider.swipesVersion;

    // Trigger load if user just became available or version changed
    if (user != null && _profiles.isEmpty && !_isFetching && _isLoading) {
      _loadProfiles();
    }

    if (version != _lastSwipesVersion && _lastSwipesVersion != -1) {
      _lastSwipesVersion = version;
      setState(() {
        _profiles = [];
        _currentIndex = 0;
        _currentPhotoIndex = 0;
        _isLoading = true;
      });
      _loadProfiles();
    } else {
      _lastSwipesVersion = version;
    }
  }

  Future<void> _loadProfiles() async {
    if (_isFetching) return;

    final profileProvider = context.read<ProfileProvider>();
    final currentUser = profileProvider.currentUser;

    if (currentUser != null) {
      debugPrint('SwipeView: Fetching profiles for UID: ${currentUser.uid}');
      setState(() => _isFetching = true);

      try {
        final profiles = await _profileService
            .getSwipeProfiles(currentUser.uid)
            .timeout(const Duration(seconds: 15)); // Safety timeout

        debugPrint('SwipeView: Fetched ${profiles.length} profiles');
        if (mounted) {
          setState(() {
            _profiles = profiles;
            _isLoading = false;
            _isFetching = false;
          });
        }
      } catch (e) {
        debugPrint('SwipeView: Error loading profiles: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isFetching = false;
          });
        }
      }
    } else {
      debugPrint('SwipeView: No current user yet, retrying in 1.5s...');
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) _loadProfiles();
      });
    }
  }

  void _onSwipeComplete(String direction) {
    if (_profiles.isEmpty) return;

    final targetProfile = _profiles[_currentIndex];
    final profileProvider = context.read<ProfileProvider>();
    final currentUserId = profileProvider.currentUser?.uid;
    final swipeType = direction == 'right' ? 'like' : 'dislike';

    if (currentUserId != null && targetProfile.uid != null) {
      _profileService.swipeUser(currentUserId, targetProfile.uid!, swipeType,
          senderName: profileProvider.displayName);
    }

    setState(() {
      _freeSwipesUsed++;
      if (_currentIndex < _profiles.length - 1) {
        _currentIndex++;
        // Proactive replenishment: fetch more when 2 left
        if (_profiles.length - _currentIndex <= 2) {
          _loadMoreProfiles();
        }
      } else {
        _profiles = [];
        _currentIndex = 0;
      }
      _currentPhotoIndex = 0;
      _dragOffset = Offset.zero;
      _isAnimating = false;
    });
  }

  Future<void> _loadMoreProfiles() async {
    if (_isFetching) return;
    final profileProvider = context.read<ProfileProvider>();
    final currentUser = profileProvider.currentUser;
    if (currentUser == null) return;

    try {
      final newProfiles =
          await _profileService.getSwipeProfiles(currentUser.uid);
      if (mounted && newProfiles.isNotEmpty) {
        setState(() {
          final existingIds = _profiles.map((p) => p.uid).toSet();
          final uniqueNew =
              newProfiles.where((p) => !existingIds.contains(p.uid)).toList();
          _profiles.addAll(uniqueNew);
        });
      }
    } catch (e) {
      debugPrint('SwipeView: Error replenishing: $e');
    }
  }

  void _runSwipeAnimation(String direction) {
    if (_isAnimating) return;
    _isAnimating = true;

    final screenWidth = MediaQuery.of(context).size.width;
    final endOffset = direction == 'right'
        ? Offset(screenWidth * 1.5, _dragOffset.dy)
        : Offset(-screenWidth * 1.5, _dragOffset.dy);

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: endOffset,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));

    _swipeController.forward(from: 0).then((_) {
      _onSwipeComplete(direction);
      context.read<ProfileProvider>().resetSwipeOffset();
      _swipeController.reset();
    });
  }

  void _resetPosition() {
    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _swipeController, curve: Curves.easeOutBack));

    _swipeController.forward(from: 0).then((_) {
      context.read<ProfileProvider>().resetSwipeOffset();
      setState(() {
        _dragOffset = Offset.zero;
        _swipeController.reset();
      });
    });
  }

  void _nextPhoto(int totalPhotos) {
    if (_currentPhotoIndex < totalPhotos - 1) {
      setState(() => _currentPhotoIndex++);
    }
  }

  void _prevPhoto() {
    if (_currentPhotoIndex > 0) {
      setState(() => _currentPhotoIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                color: const Color(0xFFFF4D85),
                strokeWidth: 3,
                backgroundColor: const Color(0xFFFF4D85).withOpacity(0.15),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Finding your matches…',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF4D85))),
          ],
        ),
      );
    }

    if (_profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF4D85).withOpacity(0.15),
                      Colors.transparent
                    ],
                  ),
                ),
                child: Icon(Iconsax.user_search,
                    size: 56, color: const Color(0xFFFF4D85).withOpacity(0.5)),
              ),
              const SizedBox(height: 28),
              const Text('You\'ve seen everyone!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5)),
              const SizedBox(height: 12),
              Text(
                  'Come back later or refresh to revisit profiles you haven\'t connected with yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Theme.of(context).hintColor)),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () => context.read<ProfileProvider>().resetSwipes(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF4D85), Color(0xFFFF7DA0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4D85).withOpacity(0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.refresh, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Text('Refresh Profiles',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final profileProvider = context.watch<ProfileProvider>();
    final myPhotos = profileProvider.userProfile?.photos ?? [];
    final hasMinPhotos = myPhotos.length >= 4;
    final isLockedOut = !hasMinPhotos && _freeSwipesUsed >= 1;

    final hasNext = _currentIndex < _profiles.length - 1;
    final profile = _profiles[_currentIndex];
    final nextProfile = hasNext ? _profiles[_currentIndex + 1] : null;

    final photos = profile.photos.isNotEmpty
        ? profile.photos
        : [
            'https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=800'
          ];
    final photoUrl = _currentPhotoIndex < photos.length
        ? photos[_currentPhotoIndex]
        : photos.first;

    return Padding(
      padding:
          const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 0),
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedBuilder(
                  animation: _swipeController,
                  builder: (context, _) {
                    final offset = _swipeController.isAnimating
                        ? _swipeAnimation.value
                        : _dragOffset;
                    final screenWidth = MediaQuery.of(context).size.width;
                    final angle = (offset.dx / screenWidth) * 0.45;
                    // Back card reacts to drag: scales up as front card moves
                    final dragFraction =
                        (_dragOffset.dx.abs() / screenWidth).clamp(0.0, 1.0);
                    final backScale = 0.95 + (0.05 * dragFraction);
                    final backOpacity = 0.7 + (0.3 * dragFraction);
                    final backOffset = Offset(0, 12 - (12 * dragFraction));

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (hasNext)
                          Positioned.fill(
                            child: Transform.translate(
                              offset: backOffset,
                              child: Transform.scale(
                                scale: backScale,
                                child: Opacity(
                                  opacity: backOpacity.clamp(0.0, 1.0),
                                  child: _buildCard(
                                    context,
                                    nextProfile!,
                                    nextProfile.photos.isNotEmpty
                                        ? nextProfile.photos.first
                                        : 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=800',
                                    nextProfile.photos.length,
                                    isBackCard: true,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: GestureDetector(
                            onPanUpdate: isLockedOut ? null : (details) {
                              if (_isAnimating) return;
                              setState(() => _dragOffset += details.delta);
                              context
                                  .read<ProfileProvider>()
                                  .updateSwipeOffset(_dragOffset.dx);
                            },
                            onPanEnd: isLockedOut ? null : (details) {
                              if (_isAnimating) return;
                              if (_dragOffset.dx > 120) {
                                _runSwipeAnimation('right');
                              } else if (_dragOffset.dx < -120)
                                _runSwipeAnimation('left');
                              else
                                _resetPosition();
                            },
                            child: Transform.translate(
                              offset: offset,
                              child: Transform.rotate(
                                angle: angle,
                                child: Stack(
                                  children: [
                                    _buildCard(
                                      context,
                                      profile,
                                      photoUrl,
                                      photos.length,
                                      onNextPhoto: hasMinPhotos ? () => _nextPhoto(photos.length) : _showPhotoLockSnack,
                                      onPrevPhoto: hasMinPhotos ? _prevPhoto : _showPhotoLockSnack,
                                      hasMinPhotos: hasMinPhotos,
                                    ),
                                    IgnorePointer(
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 56,
                                            left: 24,
                                            child: Transform.rotate(
                                              angle: -0.35,
                                              child: Opacity(
                                                opacity: (offset.dx / 100)
                                                    .clamp(0.0, 1.0),
                                                child: _buildStamp('LIKE',
                                                    const Color(0xFF00D68F)),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 56,
                                            right: 24,
                                            child: Transform.rotate(
                                              angle: 0.35,
                                              child: Opacity(
                                                opacity: (-offset.dx / 100)
                                                    .clamp(0.0, 1.0),
                                                child: _buildStamp('NOPE',
                                                    const Color(0xFFFF5E5E)),
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
                        ),
                        // Locked overlay after 1 free swipe
                        if (isLockedOut)
                          Positioned.fill(
                            child: _buildLockedOverlay(),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, UserProfile profile, String photoUrl, int totalPhotos, {bool isBackCard = false, VoidCallback? onNextPhoto, VoidCallback? onPrevPhoto, bool hasMinPhotos = true}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 32,
              offset: const Offset(0, 16)),
          BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 8,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark background – always visible, prevents back card bleed-through during photo loads
          const ColoredBox(color: Color(0xFF1A1A2E)),

          // Profile photo with crossfade transition between photos
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Image.network(
              photoUrl,
              key: ValueKey(photoUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF1A1A2E)),
              loadingBuilder: (_, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const ColoredBox(color: Color(0xFF1A1A2E));
              },
            ),
          ),

          // Top gradient (dark fade for indicators)
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC000000), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // Bottom gradient (rich and deep)
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xDD000000),
                    Color(0xF5000000)
                  ],
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // Photo tap areas (only front card)
          if (!isBackCard && onNextPhoto != null && onPrevPhoto != null)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                      child: GestureDetector(
                          key: const ValueKey('prev_photo'),
                          onTap: onPrevPhoto,
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox.expand())),
                  Expanded(
                      child: GestureDetector(
                          key: const ValueKey('next_photo'),
                          onTap: onNextPhoto,
                          behavior: HitTestBehavior.opaque,
                          child: const SizedBox.expand())),
                ],
              ),
            ),

          // Photo indicators — Positioned MUST be direct child of Stack
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: IgnorePointer(
              child: Row(
                children: List.generate(
                    totalPhotos,
                    (index) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: index == _currentPhotoIndex ? 4 : 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: index == _currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: index == _currentPhotoIndex
                                  ? [
                                      BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 6)
                                    ]
                                  : [],
                            ),
                          ),
                        )),
              ),
            ),
          ),

          // Common interests chips — Positioned MUST be direct child of Stack
          Positioned(
            top: 30,
            left: 14,
            right: 14,
            child: IgnorePointer(
              child: Consumer<ProfileProvider>(
                builder: (context, profileProvider, _) {
                  final myProfile = profileProvider.userProfile;
                  if (myProfile == null) return const SizedBox.shrink();
                  final common = profile.getCommonInterests(myProfile);
                  if (common.isEmpty) return const SizedBox.shrink();
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: common
                          .take(4)
                          .map((interest) => Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: const Color(0xFFFF4D85)
                                          .withOpacity(0.5),
                                      width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFFFF4D85)
                                            .withOpacity(0.15),
                                        blurRadius: 8)
                                  ],
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Iconsax.heart5,
                                          color: Color(0xFFFF4D85), size: 11),
                                      const SizedBox(width: 5),
                                      Text(interest,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.1)),
                                    ]),
                              ))
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bottom info panel + action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfileInfo(context, profile, hasMinPhotos: hasMinPhotos && !isBackCard),
                if (!isBackCard) _buildActionRow(),
                if (isBackCard) const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 4, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ActionButton(
            svgAsset: 'assets/images/pass.svg',
            color: const Color(0xFFFF5E5E),
            onTap: () => _runSwipeAnimation('left'),
            size: 64,
            label: 'Pass',
          ),
          ActionButton(
            svgAsset: 'assets/images/like.svg',
            color: const Color(0xFF00C853),
            onTap: () => _runSwipeAnimation('right'),
            size: 64,
            label: 'Like',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context, UserProfile profile, {bool hasMinPhotos = true}) {
    final occupation = profile.occupation;
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 22, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  '${profile.firstName ?? 'Someone'},',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      height: 1.1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${profile.age ?? '??'}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5),
                ),
              ),
              if (profile.isVerified) ...[
                const SizedBox(width: 6),
                const Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.verified_rounded,
                        color: Color(0xFF4FC3F7), size: 22))
              ],
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Consumer<ProfileProvider>(
                builder: (_, profileProvider, __) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.location,
                          color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        profile.getDistanceDisplay(profileProvider.userProfile),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              if (occupation != null && occupation.isNotEmpty) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.briefcase,
                            color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            occupation,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (hasMinPhotos)
            GestureDetector(
              onTap: () => _showProfileDetails(profile),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Iconsax.user, color: Colors.white70, size: 13),
                    const SizedBox(width: 6),
                    Text('View Profile',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withOpacity(0.6), size: 10),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedOverlay() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.black.withOpacity(0.55),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D85).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF4D85).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: Color(0xFFFF4D85),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Upload More Photos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Add at least 4 photos to your profile to keep swiping, view profiles, and browse photos.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4D85), Color(0xFFFF7DA0)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4D85).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Add Photos Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStamp(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 3.5),
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16)],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 36,
          fontWeight: FontWeight.w900,
          letterSpacing: 3,
          shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 12)],
        ),
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
          _runSwipeAnimation('right');
        },
        onDislike: () {
          Navigator.pop(context);
          _runSwipeAnimation('left');
        },
        onMessage: () async {
          if (!profile.allowMessages) {
            _showPremiumSnack('This user has disabled direct messaging.');
            return;
          }
          Navigator.pop(context);
          final myUid = FirebaseAuth.instance.currentUser?.uid;
          if (myUid == null || profile.uid == null) return;
          await ChatService().getOrCreateChat(myUid, profile.uid!);
          if (mounted) {
            Navigator.push(
                this.context,
                MaterialPageRoute(
                    builder: (_) => ChatScreen(
                          otherUserId: profile.uid!,
                          otherUserName: profile.firstName ?? 'User',
                          otherUserPhoto: profile.photos.isNotEmpty
                              ? profile.photos.first
                              : null,
                        )));
          }
        },
      ),
    );
  }

  void _showPhotoLockSnack() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Row(
        children: [
          Icon(Icons.lock_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('Upload at least 4 photos to browse more pictures!', style: TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
      backgroundColor: const Color(0xFFFF4D85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.all(20),
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Upload',
        textColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          );
        },
      ),
    ));
  }

  void _showPremiumSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFFFF4D85),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.all(20),
    ));
  }
}
