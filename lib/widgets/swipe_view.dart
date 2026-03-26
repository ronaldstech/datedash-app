import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/profile_model.dart';
import 'action_button.dart';

class SwipeView extends StatefulWidget {
  const SwipeView({super.key});

  @override
  State<SwipeView> createState() => _SwipeViewState();
}

class _SwipeViewState extends State<SwipeView> {
  // Fake data for the first trial
  final List<Profile> profiles = [
    Profile(
      name: 'Emma',
      age: 24,
      bio: 'Love hiking and good coffee ☕',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=800&auto=format&fit=crop',
    ),
    Profile(
      name: 'Sophia',
      age: 26,
      bio: 'Art enthusiast and dog mom 🐶',
      imageUrl:
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=800&auto=format&fit=crop',
    ),
    Profile(
      name: 'Isabella',
      age: 23,
      bio: 'Travel, food, and photography ✈️',
      imageUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=800&auto=format&fit=crop',
    ),
  ];

  int currentIndex = 0;

  void _nextProfile() {
    setState(() {
      if (currentIndex < profiles.length - 1) {
        currentIndex++;
      } else {
        // Reset or show empty state, resetting for demo
        currentIndex = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty) {
      return const Center(child: Text('No more profiles'));
    }

    final profile = profiles[currentIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                image: DecorationImage(
                  image: NetworkImage(profile.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.55, 1.0],
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${profile.name}, ${profile.age}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.verified,
                          color: Colors.blueAccent,
                          size: 26,
                        ),
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
                          '1 mile away',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile.bio,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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
                icon: Iconsax.heart5, // Filled heart for like
                color: Theme.of(context).colorScheme.primary,
                onTap: _nextProfile,
                size: 68,
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
