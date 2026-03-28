import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/bordered_search_bar.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text(
              'Explore',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            floating: true,
            snap: true,
            actions: const [
              BorderedSearchBar(),
              SizedBox(width: 8),
            ],
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Text(
                'What are you looking for?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          _buildCategoryGrid(context),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      {
        'title': 'Long Term',
        'subtitle': 'Serious partner',
        'count': '1.2k',
        'icon': Iconsax.heart5,
        'colors': [const Color(0xFFFF4D85), const Color(0xFFFF9A8B)],
      },
      {
        'title': 'Hookups',
        'subtitle': 'Casual & fun',
        'count': '2.5k',
        'icon': Iconsax.flash,
        'colors': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      },
      {
        'title': 'Short Term Fun',
        'subtitle': 'No strings attached',
        'count': '1.8k',
        'icon': Iconsax.emoji_happy,
        'colors': [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
      },
      {
        'title': 'New Friends',
        'subtitle': 'Platonic only',
        'count': '3.1k',
        'icon': Iconsax.user_add,
        'colors': [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
      },
      {
        'title': 'Coffee Date',
        'subtitle': 'Relaxed vibes',
        'count': '950',
        'icon': Iconsax.cup,
        'colors': [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      },
      {
        'title': 'Movie Night',
        'subtitle': 'Film lovers',
        'count': '1.1k',
        'icon': Iconsax.video_play4,
        'colors': [const Color(0xFFEB5757), const Color(0xFF000000)],
      },
      {
        'title': 'Fitness Duo',
        'subtitle': 'Gym buddies',
        'count': '780',
        'icon': Iconsax.activity,
        'colors': [const Color(0xFFf857a6), const Color(0xFFff5858)],
      },
      {
        'title': 'Gaming Duo',
        'subtitle': 'Player 2?',
        'count': '2.2k',
        'icon': Iconsax.game,
        'colors': [const Color(0xFF7F00FF), const Color(0xFFE100FF)],
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final cat = categories[index];
            final colors = cat['colors'] as List<Color>;

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors[0].withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Decorative icon in background
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Opacity(
                        opacity: 0.2,
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            cat['title'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            cat['subtitle'] as String,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${cat['count']} people',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: categories.length,
        ),
      ),
    );
  }
}
