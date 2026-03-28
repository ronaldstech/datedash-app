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
    const primaryColor = Color(0xFFFF4D85);

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
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 130),
                  children: [
                    // ── Header ──────────────────────────────────────
                    Row(
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
                              if (profile.occupation != null ||
                                  profile.industry != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Iconsax.briefcase,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        [
                                          if (profile.occupation != null)
                                            profile.occupation,
                                          if (profile.industry != null)
                                            profile.industry,
                                        ].join(' · '),
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Iconsax.location,
                                      color: primaryColor, size: 14),
                                  const SizedBox(width: 6),
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
                          const Icon(Icons.verified,
                              color: Colors.blueAccent, size: 32),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── About Me ────────────────────────────────────
                    if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                      const _SectionHeader(
                          title: 'About Me', icon: Iconsax.user),
                      Text(
                        profile.bio!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.7,
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.color
                              ?.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Quick Facts ─────────────────────────────────
                    _buildQuickFacts(context),
                    const SizedBox(height: 28),

                    // ── Personal Details ────────────────────────────
                    _buildPersonalDetails(context),

                    // ── Lifestyle ───────────────────────────────────
                    _buildLifestyle(context),

                    // ── Relationship Goals ──────────────────────────
                    if (profile.lookingFor.isNotEmpty) ...[
                      const _SectionHeader(
                          title: 'Relationship Goals', icon: Iconsax.heart),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.lookingFor
                            .map((g) => _Chip(label: g, color: primaryColor))
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Interests & Hobbies ─────────────────────────
                    if (profile.hobbies.isNotEmpty) ...[
                      const _SectionHeader(
                          title: 'Interests & Hobbies', icon: Iconsax.activity),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.hobbies
                            .map((h) => _Chip(label: h))
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Music ───────────────────────────────────────
                    if (profile.musicGenres.isNotEmpty) ...[
                      const _SectionHeader(
                          title: 'Music Taste', icon: Iconsax.music),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile.musicGenres
                            .map((g) => _Chip(label: g))
                            .toList(),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ── Personality ─────────────────────────────────
                    _buildPersonality(context),

                    // ── Prompts ─────────────────────────────────────
                    _buildPrompts(context),
                  ],
                ),
              ),
            ],
          ),

          // ── Action Buttons fixed at bottom ────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Iconsax.close_circle,
                    color: const Color(0xFFFF5E5E),
                    label: 'Pass',
                    onTap: onDislike,
                  ),
                  _ActionButton(
                    icon: Iconsax.message_text5,
                    color: Colors.blueAccent,
                    label: 'Message',
                    onTap: onMessage,
                    isSmall: true,
                  ),
                  _ActionButton(
                    icon: Iconsax.heart5,
                    color: primaryColor,
                    label: 'Like',
                    onTap: onLike,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFacts(BuildContext context) {
    final facts = <Map<String, dynamic>>[];
    if (profile.height != null) {
      facts.add(
          {'icon': Iconsax.ruler, 'label': 'Height', 'value': profile.height!});
    }
    if (profile.educationLevel != null) {
      facts.add({
        'icon': Iconsax.teacher,
        'label': 'Education',
        'value': profile.educationLevel!
      });
    }
    if (profile.religion != null) {
      facts.add({
        'icon': Iconsax.cloud,
        'label': 'Religion',
        'value': profile.religion!
      });
    }
    if (profile.wantKids != null) {
      facts.add({
        'icon': Iconsax.heart_circle,
        'label': 'Wants Kids',
        'value': profile.wantKids!
      });
    }
    if (profile.openToLongDistance != null) {
      facts.add({
        'icon': Iconsax.global,
        'label': 'Long Distance',
        'value': profile.openToLongDistance! ? 'Open to it' : 'No'
      });
    }

    if (facts.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const _SectionHeader(title: 'Quick Facts', icon: Iconsax.info_circle),
        ...facts.map(
          (f) => _LabeledRow(
            icon: f['icon'] as IconData,
            label: f['label'] as String,
            value: f['value'] as String,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildPersonalDetails(BuildContext context) {
    final items = <Map<String, dynamic>>[];
    if (profile.bodyType != null) {
      items.add({
        'icon': Iconsax.user,
        'label': 'Body Type',
        'value': profile.bodyType!
      });
    }
    if (profile.ethnicity != null) {
      items.add({
        'icon': Iconsax.people,
        'label': 'Ethnicity',
        'value': profile.ethnicity!
      });
    }
    if (profile.school != null) {
      items.add(
          {'icon': Iconsax.book, 'label': 'School', 'value': profile.school!});
    }
    if (profile.languages.isNotEmpty) {
      items.add({
        'icon': Iconsax.translate,
        'label': 'Languages',
        'value': profile.languages.join(', ')
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const _SectionHeader(title: 'Background', icon: Iconsax.profile_2user),
        ...items.map(
          (f) => _LabeledRow(
            icon: f['icon'] as IconData,
            label: f['label'] as String,
            value: f['value'] as String,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildLifestyle(BuildContext context) {
    final items = <Map<String, dynamic>>[];
    if (profile.smoking != null) {
      items.add({
        'icon': Iconsax.status,
        'label': 'Smoking',
        'value': profile.smoking!
      });
    }
    if (profile.drinking != null) {
      items.add({
        'icon': Iconsax.cup,
        'label': 'Drinking',
        'value': profile.drinking!
      });
    }
    if (profile.fitness != null) {
      items.add({
        'icon': Iconsax.activity,
        'label': 'Exercise',
        'value': profile.fitness!
      });
    }
    if (profile.diet != null) {
      items.add(
          {'icon': Iconsax.coffee, 'label': 'Diet', 'value': profile.diet!});
    }
    if (profile.sleepingHabits != null) {
      items.add({
        'icon': Iconsax.moon,
        'label': 'Sleep',
        'value': profile.sleepingHabits!
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const _SectionHeader(title: 'Lifestyle', icon: Iconsax.chart_2),
        ...items.map(
          (f) => _LabeledRow(
            icon: f['icon'] as IconData,
            label: f['label'] as String,
            value: f['value'] as String,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildPersonality(BuildContext context) {
    final items = <Map<String, dynamic>>[];
    if (profile.mbti != null) {
      items.add({
        'icon': Iconsax.profile_circle,
        'label': 'Personality Type',
        'value': profile.mbti!
      });
    }
    if (profile.introvertExtrovert != null) {
      items.add({
        'icon': Iconsax.sun_1,
        'label': 'Social Style',
        'value': profile.introvertExtrovert!
      });
    }
    if (profile.loveLanguage != null) {
      items.add({
        'icon': Iconsax.heart,
        'label': 'Love Language',
        'value': profile.loveLanguage!
      });
    }
    if (profile.coreValues != null) {
      items.add({
        'icon': Iconsax.star,
        'label': 'Core Values',
        'value': profile.coreValues!
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const _SectionHeader(title: 'Personality', icon: Iconsax.emoji_happy),
        ...items.map(
          (f) => _LabeledRow(
            icon: f['icon'] as IconData,
            label: f['label'] as String,
            value: f['value'] as String,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildPrompts(BuildContext context) {
    final prompts = <Map<String, String?>>[
      {'q': 'The perfect date', 'a': profile.promptPerfectDate},
      {'q': 'You\'ll fall for me if', 'a': profile.promptFallForYou},
      {'q': 'My green flag', 'a': profile.promptGreenFlag},
      {'q': 'Two truths & a lie', 'a': profile.promptTwoTruths},
    ].where((p) => p['a'] != null && p['a']!.isNotEmpty).toList();

    if (prompts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Prompts', icon: Iconsax.message_question),
        ...prompts.map(
          (p) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['q']!,
                  style: const TextStyle(
                    color: Color(0xFFFF4D85),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p['a']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ── Reusable sub-widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF4D85)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }
}

class _LabeledRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _LabeledRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4D85).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFFFF4D85)),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  const _Chip({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFFF4D85);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool isSmall;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSmall ? 54.0 : 64.0;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: color.withOpacity(0.15), width: 1.5),
            ),
            child: Icon(icon, color: color, size: size * 0.42),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}

// Keep legacy exports for backward compatibility
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});
  @override
  Widget build(BuildContext context) =>
      _SectionHeader(title: title, icon: Iconsax.info_circle);
}

class InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoTag({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) =>
      _LabeledRow(icon: icon, label: label, value: '');
}

class DetailChip extends StatelessWidget {
  final String label;
  final Color? color;
  const DetailChip({super.key, required this.label, this.color});
  @override
  Widget build(BuildContext context) => _Chip(label: label, color: color);
}

class LifestyleGrid extends StatelessWidget {
  final UserProfile profile;
  const LifestyleGrid({super.key, required this.profile});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class LifestyleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const LifestyleRow(
      {super.key,
      required this.icon,
      required this.title,
      required this.value});
  @override
  Widget build(BuildContext context) =>
      _LabeledRow(icon: icon, label: title, value: value);
}
