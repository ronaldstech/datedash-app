import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../models/user_profile_model.dart';

class ProfileDetailSheet extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onMessage;

  const ProfileDetailSheet({
    super.key,
    required this.profile,
    required this.onLike,
    required this.onDislike,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF4D85);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 120), // Bottom padding for buttons
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.firstName ?? 'Someone'}, ${profile.age ?? '??'}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Iconsax.location, color: primaryColor, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.location ?? 'Somewhere',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (profile.isVerified)
                          const Icon(Icons.verified, color: Colors.blueAccent, size: 32),
                      ],
                    ),
                    const SizedBox(height: 28),
                    
                    // About Me
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const SectionHeader(title: 'About Me'),
                      Text(
                        profile.bio!,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Basic Info Highlights
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (profile.height != null) InfoTag(icon: Iconsax.ruler, label: profile.height!),
                        if (profile.educationLevel != null) InfoTag(icon: Iconsax.teacher, label: profile.educationLevel!),
                        if (profile.occupation != null) InfoTag(icon: Iconsax.briefcase, label: profile.occupation!),
                        if (profile.religion != null) InfoTag(icon: Iconsax.cloud, label: profile.religion!),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Lifestyle Section
                    const SectionHeader(title: 'Lifestyle'),
                    LifestyleGrid(profile: profile),
                    const SizedBox(height: 32),

                    // Interests Section
                    if (profile.hobbies.isNotEmpty) ...[
                      const SectionHeader(title: 'Interests & Hobbies'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.hobbies.map((h) => DetailChip(label: h)).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Relationship Goals
                    if (profile.lookingFor.isNotEmpty) ...[
                      const SectionHeader(title: 'Relationship Goals'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.lookingFor.map((g) => DetailChip(label: g, color: primaryColor)).toList(),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Action Buttons Fixed at Bottom
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DetailActionButton(
                  icon: Iconsax.close_circle,
                  color: const Color(0xFFFF5E5E),
                  onTap: onDislike,
                ),
                _DetailActionButton(
                  icon: Iconsax.message_text5,
                  color: Colors.blueAccent,
                  onTap: onMessage,
                  isSmall: true,
                ),
                _DetailActionButton(
                  icon: Iconsax.heart5,
                  color: const Color(0xFFFF4D85),
                  onTap: onLike,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSmall;

  const _DetailActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSmall ? 56.0 : 68.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: color.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}

class InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoTag({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFFF4D85)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class DetailChip extends StatelessWidget {
  final String label;
  final Color? color;
  const DetailChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? Theme.of(context).primaryColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: (color ?? Theme.of(context).primaryColor).withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color ?? Theme.of(context).primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class LifestyleGrid extends StatelessWidget {
  final UserProfile profile;
  const LifestyleGrid({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (profile.smoking != null) LifestyleRow(icon: Iconsax.status, title: 'Smoking', value: profile.smoking!),
        if (profile.drinking != null) LifestyleRow(icon: Iconsax.cup, title: 'Drinking', value: profile.drinking!),
        if (profile.fitness != null) LifestyleRow(icon: Iconsax.ranking, title: 'Exercise', value: profile.fitness!),
        if (profile.diet != null) LifestyleRow(icon: Iconsax.coffee, title: 'Diet', value: profile.diet!),
      ],
    );
  }
}

class LifestyleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const LifestyleRow({super.key, required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
