import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';
import '../services/chat_service.dart';
import '../providers/language_provider.dart';
import '../widgets/profile_detail_sheet.dart';
import '../widgets/action_button.dart';
import 'chat_screen.dart';

class CategoryProfilesScreen extends StatefulWidget {
  final String category;
  const CategoryProfilesScreen({super.key, required this.category});

  @override
  State<CategoryProfilesScreen> createState() => _CategoryProfilesScreenState();
}

class _CategoryProfilesScreenState extends State<CategoryProfilesScreen>
    with TickerProviderStateMixin {
  final ProfileService _profileService = ProfileService();
  List<UserProfile> _profiles = [];
  int _currentIndex = 0;
  int _currentPhotoIndex = 0;
  bool _isLoading = true;

  Offset _dragOffset = Offset.zero;
  late AnimationController _swipeController;
  late Animation<Offset> _swipeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _swipeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _swipeAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _swipeController, curve: Curves.easeOutBack));
    _loadProfiles();
  }

  @override
  void dispose() {
    _swipeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isLoading = true);
    try {
      final profiles = await _profileService.getSwipeProfilesByCategory(
          uid, widget.category);
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getLocalizedCategoryName(String key, LanguageProvider lp) {
    switch (key) {
      case 'Long Term':
        return lp.getString('cat_long_term');
      case 'Hookups':
        return lp.getString('cat_hookups');
      case 'Short Term Fun':
        return lp.getString('cat_short_term');
      case 'New Friends':
        return lp.getString('cat_new_friends');
      case 'Coffee Date':
        return lp.getString('cat_coffee_date');
      case 'Movie Night':
        return lp.getString('cat_movie_night');
      case 'Fitness Duo':
        return lp.getString('cat_fitness_duo');
      case 'Gaming Duo':
        return lp.getString('cat_gaming_duo');
      default:
        return key;
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
      if (_currentIndex < _profiles.length - 1) {
        _currentIndex++;
      } else {
        _profiles = [];
        _currentIndex = 0;
      }
      _currentPhotoIndex = 0;
      _dragOffset = Offset.zero;
      _isAnimating = false;
    });
  }

  void _runSwipeAnimation(String direction) {
    if (_isAnimating) return;
    _isAnimating = true;
    final screenWidth = MediaQuery.of(context).size.width;
    final endOffset = direction == 'right'
        ? Offset(screenWidth * 1.5, _dragOffset.dy)
        : Offset(-screenWidth * 1.5, _dragOffset.dy);
    _swipeAnimation = Tween<Offset>(begin: _dragOffset, end: endOffset).animate(
        CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));
    _swipeController.forward(from: 0).then((_) {
      _onSwipeComplete(direction);
      _swipeController.reset();
    });
  }

  void _resetPosition() {
    _swipeAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _swipeController, curve: Curves.easeOutBack));
    _swipeController.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _swipeController.reset();
      });
    });
  }

  void _nextPhoto(int total) {
    if (_currentPhotoIndex < total - 1) setState(() => _currentPhotoIndex++);
  }

  void _prevPhoto() {
    if (_currentPhotoIndex > 0) setState(() => _currentPhotoIndex--);
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_getLocalizedCategoryName(widget.category, languageProvider),
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D85)))
          : _profiles.isEmpty
              ? _buildEmpty(languageProvider)
              : _buildSwipeLayout(languageProvider),
    );
  }

  Widget _buildEmpty(LanguageProvider lp) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.user_search,
                size: 64, color: Colors.white.withOpacity(0.4)),
            const SizedBox(height: 20),
            Text(
                'No one in ${_getLocalizedCategoryName(widget.category, lp)} yet',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(lp.getString('try_different_search'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.6), fontSize: 14)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadProfiles,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D85),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20))),
              icon: const Icon(Iconsax.refresh, color: Colors.white),
              label: Text(lp.getString('retry_button'),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipeLayout(LanguageProvider lp) {
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
      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 0),
      child: Column(
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _swipeController,
              builder: (context, _) {
                final offset = _swipeController.isAnimating
                    ? _swipeAnimation.value
                    : _dragOffset;
                final screenWidth = MediaQuery.of(context).size.width;
                final angle = (offset.dx / screenWidth) * 0.45;
                final dragFraction =
                    (_dragOffset.dx.abs() / screenWidth).clamp(0.0, 1.0);
                final backScale = 0.95 + 0.05 * dragFraction;
                final backOpacity = 0.7 + 0.3 * dragFraction;
                final backOffset = Offset(0, 12 - 12 * dragFraction);

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
                                nextProfile!,
                                nextProfile.photos.isNotEmpty
                                    ? nextProfile.photos.first
                                    : photos.first,
                                nextProfile.photos.length,
                                lp,
                                isBackCard: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          if (_isAnimating) return;
                          setState(() => _dragOffset += details.delta);
                        },
                        onPanEnd: (details) {
                          if (_isAnimating) return;
                          if (_dragOffset.dx > 120) {
                            _runSwipeAnimation('right');
                          } else if (_dragOffset.dx < -120) {
                            _runSwipeAnimation('left');
                          } else {
                            _resetPosition();
                          }
                        },
                        child: Transform.translate(
                          offset: offset,
                          child: Transform.rotate(
                            angle: angle,
                            child: Stack(
                              children: [
                                _buildCard(profile, photoUrl, photos.length, lp,
                                    onNextPhoto: () =>
                                        _nextPhoto(photos.length),
                                    onPrevPhoto: _prevPhoto),
                                IgnorePointer(
                                  child: Stack(children: [
                                    Positioned(
                                      top: 80,
                                      left: 24,
                                      child: Transform.rotate(
                                        angle: -0.35,
                                        child: Opacity(
                                          opacity:
                                              (offset.dx / 100).clamp(0.0, 1.0),
                                          child: _buildStamp(
                                              lp.getString('like_stamp'),
                                              const Color(0xFF00D68F)),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 80,
                                      right: 24,
                                      child: Transform.rotate(
                                        angle: 0.35,
                                        child: Opacity(
                                          opacity: (-offset.dx / 100)
                                              .clamp(0.0, 1.0),
                                          child: _buildStamp(
                                              lp.getString('nope_stamp'),
                                              const Color(0xFFFF5E5E)),
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildActionRow(lp),
          SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildCard(UserProfile profile, String photoUrl, int totalPhotos,
      LanguageProvider lp,
      {bool isBackCard = false,
      VoidCallback? onNextPhoto,
      VoidCallback? onPrevPhoto}) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 32,
              offset: const Offset(0, 16)),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF1A1A2E)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Image.network(photoUrl,
                key: ValueKey(photoUrl),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) =>
                    const ColoredBox(color: Color(0xFF1A1A2E)),
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const ColoredBox(color: Color(0xFF1A1A2E))),
          ),
          IgnorePointer(
              child: Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xCC000000), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.center)))),
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
                          stops: [0, 0.65, 1])))),
          if (!isBackCard && onNextPhoto != null && onPrevPhoto != null)
            Positioned.fill(
              child: Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: onPrevPhoto,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand())),
                Expanded(
                    child: GestureDetector(
                        onTap: onNextPhoto,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox.expand())),
              ]),
            ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: IgnorePointer(
                child: Row(
              children: List.generate(
                  totalPhotos,
                  (i) => Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: i == _currentPhotoIndex ? 4 : 3,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i == _currentPhotoIndex
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )),
            )),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Flexible(
                        child: Text(
                      '${profile.firstName ?? lp.getString('someone_fallback')},',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.1),
                      overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('${profile.age ?? '??'}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 26,
                              fontWeight: FontWeight.w500)),
                    ),
                    if (profile.isVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          color: Color(0xFF4FC3F7), size: 22),
                    ],
                  ]),
                  if (profile.location != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Iconsax.location,
                            color: Colors.white70, size: 12),
                        const SizedBox(width: 4),
                        Text(profile.location!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                  if (!isBackCard) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showProfileDetails(profile, lp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Iconsax.user,
                              color: Colors.white70, size: 13),
                          const SizedBox(width: 6),
                          Text(lp.getString('view_profile'),
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.white.withOpacity(0.6), size: 10),
                        ]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(LanguageProvider lp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActionButton(
          svgAsset: 'assets/images/pass.svg',
          color: const Color(0xFFFF5E5E),
          onTap: () => _runSwipeAnimation('left'),
          size: 64,
          label: lp.getString('pass'),
        ),
        ActionButton(
          svgAsset: 'assets/images/like.svg',
          color: const Color(0xFF00C853),
          onTap: () => _runSwipeAnimation('right'),
          size: 64,
          label: lp.getString('like'),
        ),
      ],
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
      child: Text(text,
          style: TextStyle(
              color: color,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              shadows: [
                Shadow(color: color.withOpacity(0.5), blurRadius: 12)
              ])),
    );
  }

  void _showProfileDetails(UserProfile profile, LanguageProvider lp) {
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
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lp.getString('messages_disabled_snack'))));
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
                    otherUserName: profile.firstName ?? lp.getString('user_fallback'),
                    otherUserPhoto:
                        profile.photos.isNotEmpty ? profile.photos.first : null,
                  ),
                ));
          }
        },
      ),
    );
  }
}
