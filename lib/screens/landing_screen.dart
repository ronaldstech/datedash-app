import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';
import '../widgets/swipe_view.dart';
import '../widgets/profile_drawer.dart';
import 'explore_screen.dart';
import 'likes_screen.dart';
import 'chat_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/profile_provider.dart';
import '../services/notification_service.dart';
import '../screens/notification_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/swipe_filters_screen.dart';
import '../screens/premium_screen.dart';
import '../services/auth_service.dart';
import '../providers/language_provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        if (profileProvider.userProfile == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D85)),
            ),
          );
        }

        final completion = profileProvider.userProfile!.completionPercentage;
        final isProfileIncomplete = completion < 40;

        final currentIndex = profileProvider.currentTabIndex;

        return Stack(
          children: [
            Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              extendBody: true,
              appBar: AppBar(
                title: const Text(
                  'DateDash',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 26,
                    color: Color(0xFFFF4D85),
                    letterSpacing: -0.5,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: [
                  if (currentIndex == 0) // Show Filter icon only on Swipe View
                    IconButton(
                      icon: Icon(Iconsax.setting_4, color: Theme.of(context).iconTheme.color?.withOpacity(0.7), size: 22),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => const SwipeFiltersScreen(),
                        );
                      },
                    ),
                  StreamBuilder<int>(
                    stream: NotificationService().getUnreadCountStream(
                        FirebaseAuth.instance.currentUser?.uid ?? ''),
                    builder: (context, snapshot) {
                      final unreadCount = snapshot.data ?? 0;
                      return Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationScreen()),
                              );
                            },
                            icon: Icon(
                              Iconsax.notification,
                              color: Theme.of(context)
                                  .iconTheme
                                  .color
                                  ?.withOpacity(0.7),
                              size: 20,
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4D85),
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  unreadCount > 9
                                      ? '9+'
                                      : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  Consumer<ProfileProvider>(
                    builder: (context, profileProvider, _) {
                      final photoUrl = profileProvider.photoURL;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                          icon: photoUrl != null
                              ? CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: NetworkImage(photoUrl),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .dividerColor
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Iconsax.user,
                                    color: Theme.of(context)
                                        .iconTheme
                                        .color
                                        ?.withOpacity(0.7),
                                    size: 20,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              body: IndexedStack(
                index: currentIndex,
                children: [
                  const SwipeView(),
                  const ExploreScreen(),
                  LikesScreen(),
                  const ChatListScreen(),
                  PremiumScreen(initialTab: profileProvider.initialPremiumTab),
                ],
              ),
              endDrawer: const ProfileDrawer(),
              bottomNavigationBar: Container(
                margin: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                height: 64,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(0, Iconsax.flash, Iconsax.flash5, languageProvider.getString('nav_swipe'),
                            currentIndex, profileProvider),
                        _buildNavItem(1, Iconsax.discover, Iconsax.discover5,
                            languageProvider.getString('nav_explore'), currentIndex, profileProvider),
                        _buildNavItem(2, Iconsax.heart, Iconsax.heart5, languageProvider.getString('nav_likes'),
                            currentIndex, profileProvider,
                            hasBadge: true),
                        _buildNavItem(3, Iconsax.message, Iconsax.message5,
                            languageProvider.getString('nav_chat'), currentIndex, profileProvider,
                            hasBadge: true),
                        _buildNavItem(4, Iconsax.crown, Iconsax.crown5,
                            'Premium', currentIndex, profileProvider),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Stunning Full-Screen Swipe Border Overlay
            if (profileProvider.swipeOffset != 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Builder(builder: (context) {
                    final offset = profileProvider.swipeOffset;
                    final isLike = offset > 0;
                    final progress = (offset.abs() / 150).clamp(0.0, 1.0);

                    // Like: green → teal → cyan palette
                    // Dislike: red → coral → orange palette
                    final borderColor = isLike
                        ? Color.lerp(const Color(0xFF00E676),
                            const Color(0xFF00BCD4), progress * 0.6)!
                        : Color.lerp(const Color(0xFFFF1744),
                            const Color(0xFFFF6D00), progress * 0.6)!;

                    final glowInner = isLike
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF1744);
                    final glowMid = isLike
                        ? const Color(0xFF69F0AE)
                        : const Color(0xFFFF6E40);
                    final glowOuter = isLike
                        ? const Color(0xFF00BCD4)
                        : const Color(0xFFFF9100);

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              borderColor.withOpacity(progress.clamp(0.3, 1.0)),
                          width: 5 + (progress * 3), // Grows from 5→8px
                          strokeAlign: BorderSide.strokeAlignInside,
                        ),
                        boxShadow: [
                          // Tight inner glow
                          BoxShadow(
                            color: glowInner
                                .withOpacity((progress * 0.9).clamp(0, 0.9)),
                            blurRadius: 16,
                            spreadRadius: 2,
                            blurStyle: BlurStyle.outer,
                          ),
                          // Mid halo
                          BoxShadow(
                            color: glowMid
                                .withOpacity((progress * 0.6).clamp(0, 0.6)),
                            blurRadius: 40,
                            spreadRadius: 8,
                            blurStyle: BlurStyle.outer,
                          ),
                          // Wide diffuse outer glow
                          BoxShadow(
                            color: glowOuter
                                .withOpacity((progress * 0.35).clamp(0, 0.35)),
                            blurRadius: 80,
                            spreadRadius: 20,
                            blurStyle: BlurStyle.outer,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            // Incomplete Profile Block Overlay
            if (isProfileIncomplete)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    color:
                        Theme.of(context).colorScheme.surface.withOpacity(0.3),
                    child: _buildIncompleteProfileScreen(context, completion, languageProvider),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
    int currentIndex,
    ProfileProvider profileProvider, {
    bool hasBadge = false,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected
        ? const Color(0xFFFF4D85)
        : Theme.of(context).hintColor.withOpacity(0.6);

    int badgeCount = 0;
    if (hasBadge) {
      badgeCount = index == 2
          ? profileProvider.unlockedLikesCount
          : profileProvider.unreadMessageCount;
    }

    return GestureDetector(
      onTap: () => profileProvider.setTabIndex(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: hasBadge && badgeCount > 0,
              backgroundColor: const Color(0xFFFF4D85),
              label: Text(badgeCount.toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white)),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncompleteProfileScreen(BuildContext context, int completion, LanguageProvider languageProvider) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D85).withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/logo2.png',
                  width: 170,
                  height: 170,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                languageProvider.getString('profile_needs_attention'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                languageProvider.getString('profile_completion_sub').replaceAll('{completion}', completion.toString()),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: completion / 100,
                  backgroundColor: const Color(0xFFFF4D85).withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFFF4D85)),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$completion% / 40% required',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF4D85),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const EditProfileScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFFF4D85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    languageProvider.getString('complete_profile_button'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => AuthService().signOut(),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.6),
                ),
                child: Text(languageProvider.getString('signout_label')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
