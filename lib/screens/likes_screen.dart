import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/bordered_search_bar.dart';

class LikesScreen extends StatelessWidget {
  const LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Likes',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            centerTitle: false,
            floating: true,
            snap: true,
            actions: [
              const BorderedSearchBar(),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(child: _buildNewLikesSection(context)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                'All Likes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _buildLikesGrid(context),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  Widget _buildNewLikesSection(BuildContext context) {
    final newLikes = [
      {
        'name': 'Sarah',
        'age': '22',
        'img': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330'
      },
      {
        'name': 'Jessica',
        'age': '25',
        'img': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80'
      },
      {
        'name': 'Emily',
        'age': '24',
        'img': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2'
      },
      {
        'name': 'Chloe',
        'age': '23',
        'img': 'https://images.unsplash.com/photo-1517841905240-472988babdf9'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'New Likes (4)',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFF4D85)),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: newLikes.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF4D85), Color(0xFFFF9A8B)],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage:
                              NetworkImage(newLikes[index]['img']!),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLikesGrid(BuildContext context) {
    final allLikes = [
      {
        'name': 'Olivia',
        'age': '26',
        'img': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1'
      },
      {
        'name': 'Sophia',
        'age': '24',
        'img': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04'
      },
      {
        'name': 'Ava',
        'age': '23',
        'img': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb'
      },
      {
        'name': 'Mia',
        'age': '25',
        'img': 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e'
      },
      {
        'name': 'Isabella',
        'age': '22',
        'img': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d'
      },
      {
        'name': 'Charlotte',
        'age': '27',
        'img': 'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df'
      },
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(allLikes[index]['img']!),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${allLikes[index]['name']}, ${allLikes[index]['age']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Iconsax.location,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '2.5 km away',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: allLikes.length,
        ),
      ),
    );
  }
}
