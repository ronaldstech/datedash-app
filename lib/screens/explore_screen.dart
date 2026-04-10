import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../widgets/bordered_search_bar.dart';
import '../screens/category_profiles_screen.dart';
import '../services/profile_service.dart';
import '../providers/language_provider.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              languageProvider.getString('explore_header'),
              style: const TextStyle(fontWeight: FontWeight.w800),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Text(
                languageProvider.getString('looking_for_header'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          _buildCategoryGrid(context, languageProvider),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context, LanguageProvider languageProvider) {
    final ProfileService profileService = ProfileService();
    
    final categories = [
      {
        'title': languageProvider.getString('cat_long_term'),
        'subtitle': languageProvider.getString('cat_long_term_sub'),
        'key': 'Long Term', // Original key for DB query
        'icon': Iconsax.heart5,
        'colors': [const Color(0xFFFF4D85), const Color(0xFFFF9A8B)],
      },
      {
        'title': languageProvider.getString('cat_hookups'),
        'subtitle': languageProvider.getString('cat_hookups_sub'),
        'key': 'Hookups',
        'icon': Iconsax.flash,
        'colors': [const Color(0xFF8E2DE2), const Color(0xFF4A00E0)],
      },
      {
        'title': languageProvider.getString('cat_short_term'),
        'subtitle': languageProvider.getString('cat_short_term_sub'),
        'key': 'Short Term Fun',
        'icon': Iconsax.emoji_happy,
        'colors': [const Color(0xFFF2994A), const Color(0xFFF2C94C)],
      },
      {
        'title': languageProvider.getString('cat_new_friends'),
        'subtitle': languageProvider.getString('cat_new_friends_sub'),
        'key': 'New Friends',
        'icon': Iconsax.user_add,
        'colors': [const Color(0xFF56CCF2), const Color(0xFF2F80ED)],
      },
      {
        'title': languageProvider.getString('cat_coffee_date'),
        'subtitle': languageProvider.getString('cat_coffee_date_sub'),
        'key': 'Coffee Date',
        'icon': Iconsax.cup,
        'colors': [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      },
      {
        'title': languageProvider.getString('cat_movie_night'),
        'subtitle': languageProvider.getString('cat_movie_night_sub'),
        'key': 'Movie Night',
        'icon': Iconsax.video_play4,
        'colors': [const Color(0xFFEB5757), const Color(0xFF000000)],
      },
      {
        'title': languageProvider.getString('cat_fitness_duo'),
        'subtitle': languageProvider.getString('cat_fitness_duo_sub'),
        'key': 'Fitness Duo',
        'icon': Iconsax.activity,
        'colors': [const Color(0xFFf857a6), const Color(0xFFff5858)],
      },
      {
        'title': languageProvider.getString('cat_gaming_duo'),
        'subtitle': languageProvider.getString('cat_gaming_duo_sub'),
        'key': 'Gaming Duo',
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

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoryProfilesScreen(category: cat['key'] as String),
                  ),
                );
              },
              child: Container(
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
                              child: StreamBuilder<int>(
                                stream: profileService
                                    .getCategoryCountStream(cat['key'] as String),
                                builder: (context, countSnapshot) {
                                  final count = countSnapshot.data ?? 0;
                                  return Text(
                                    '$count ${languageProvider.getString('people_count_suffix')}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
