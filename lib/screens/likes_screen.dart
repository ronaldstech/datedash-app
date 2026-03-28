import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../widgets/bordered_search_bar.dart';
import '../models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';

class LikesScreen extends StatelessWidget {
  final ProfileService _profileService = ProfileService();

  LikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to see likes')),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<UserProfile>>(
        stream: _profileService.getReceivedLikesStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D85)),
            );
          }

          final likes = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text(
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
              if (likes.isNotEmpty) ...[
                SliverToBoxAdapter(child: _buildNewLikesSection(context, likes)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'All Likes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                _buildLikesGrid(context, likes),
              ] else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.heart_slash,
                          size: 64,
                          color: Theme.of(context).iconTheme.color?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No likes yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Keep swiping to find matches!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNewLikesSection(BuildContext context, List<UserProfile> likes) {
    // Show only the most recent in the horizontal "New" section
    final newLikes = likes.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'New Likes (${likes.length})',
            style: const TextStyle(
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
              final photo = newLikes[index].photos.isNotEmpty 
                  ? newLikes[index].photos.first 
                  : 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=800';
              
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
                          backgroundImage: NetworkImage(photo),
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

  Widget _buildLikesGrid(BuildContext context, List<UserProfile> likes) {
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
            final profile = likes[index];
            final photo = profile.photos.isNotEmpty 
                ? profile.photos.first 
                : 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=800';

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: NetworkImage(photo),
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
                      '${profile.firstName ?? 'Someone'}, ${profile.age ?? '??'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Consumer<ProfileProvider>(
                      builder: (context, profileProvider, _) {
                        return Row(
                          children: [
                            const Icon(Iconsax.location,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              profile.getDistanceDisplay(profileProvider.userProfile),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: likes.length,
        ),
      ),
    );
  }
}
