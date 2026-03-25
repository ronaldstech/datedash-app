import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu_rounded),
                color: Colors.grey.shade700,
                iconSize: 32,
                onPressed: () {
                  Scaffold.of(context).openEndDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const SwipeView(),
      endDrawer: const ProfileDrawer(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.style_outlined),
              activeIcon: Icon(
                Icons.style_outlined,
                shadows: [Shadow(color: Color(0x60FF4D85), blurRadius: 12)],
              ),
              label: 'Swipe',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Iconsax.discover),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                backgroundColor: Theme.of(context).colorScheme.primary,
                label: const Text('3'),
                child: const Icon(Iconsax.heart),
              ),
              label: 'Likes',
            ),
            const BottomNavigationBarItem(icon: Icon(Iconsax.message), label: 'Chat'),
          ],
        ),
      ),
    );
  }
}
