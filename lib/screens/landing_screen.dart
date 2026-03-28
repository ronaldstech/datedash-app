import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui';
import '../widgets/swipe_view.dart';
import '../widgets/profile_drawer.dart';
import 'explore_screen.dart';
import 'likes_screen.dart';
import 'chat_list_screen.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/bordered_search_bar.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        final currentIndex = profileProvider.currentTabIndex;
        
        return Scaffold(
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
              const BorderedSearchBar(),
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
                                color: Theme.of(context).dividerColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.user,
                                color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
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
          const LikesScreen(),
          ChatListScreen(),
        ],
      ),
          endDrawer: const ProfileDrawer(),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color.fromARGB(255, 248, 201, 232).withOpacity(0.8)
                    : const Color(0xFF1F1F3D).withOpacity(0.9),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.1 : 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Iconsax.flash, Iconsax.flash5, 'Swipe', currentIndex, profileProvider),
                      _buildNavItem(
                        1,
                        Iconsax.discover,
                        Iconsax.discover5,
                        'Explore',
                        currentIndex,
                        profileProvider,
                      ),
                      _buildNavItem(
                        2,
                        Iconsax.heart,
                        Iconsax.heart5,
                        'Likes',
                        currentIndex,
                        profileProvider,
                        hasBadge: true,
                      ),
                      _buildNavItem(3, Iconsax.message, Iconsax.message5, 'Chat', currentIndex, profileProvider),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
        : Theme.of(context).iconTheme.color?.withOpacity(0.5);

    return GestureDetector(
      onTap: () => profileProvider.setTabIndex(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.transparent, // Increase tap area
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBadge)
              Badge(
                backgroundColor: const Color(0xFFFF4D85),
                label: const Text('3'),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: isSelected ? 28 : 24,
                  shadows: isSelected
                      ? [Shadow(color: (color ?? Colors.transparent).withOpacity(0.3), blurRadius: 12)]
                      : null,
                ),
              )
            else
              Icon(
                isSelected ? activeIcon : icon,
                color: color,
                size: isSelected ? 28 : 24,
                shadows: isSelected
                    ? [Shadow(color: (color ?? Colors.transparent).withOpacity(0.3), blurRadius: 12)]
                    : null,
              ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4D85),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
