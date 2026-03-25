import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../widgets/swipe_view.dart';
import '../widgets/profile_drawer.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
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
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  icon: user != null && user.photoURL != null
                      ? CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: NetworkImage(user.photoURL!),
                        )
                      : Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.user,
                            color: Colors.grey.shade700,
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
      body: const SwipeView(),
      endDrawer: const ProfileDrawer(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                  _buildNavItem(0, Iconsax.flash, Iconsax.flash5, 'Swipe'),
                  _buildNavItem(1, Iconsax.discover, Iconsax.discover5, 'Explore'),
                  _buildNavItem(2, Iconsax.heart, Iconsax.heart5, 'Likes', hasBadge: true),
                  _buildNavItem(3, Iconsax.message, Iconsax.message5, 'Chat'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, {bool hasBadge = false}) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFFFF4D85) : Colors.grey.shade400;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
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
                child: Icon(isSelected ? activeIcon : icon, color: color, size: 24),
              )
            else
              Icon(isSelected ? activeIcon : icon, color: color, size: 24),
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
