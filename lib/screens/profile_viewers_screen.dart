import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/profile_service.dart';
import '../services/chat_service.dart';
import '../widgets/profile_detail_sheet.dart';
import '../screens/chat_screen.dart';

class ProfileViewersScreen extends StatelessWidget {
  final ProfileService _profileService = ProfileService();

  ProfileViewersScreen({super.key});

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final DateTime dateTime = timestamp.toDate();
    final DateTime now = DateTime.now();
    final int differenceInMinutes = now.difference(dateTime).inMinutes;
    final int differenceInHours = now.difference(dateTime).inHours;
    final int differenceInDays = now.difference(dateTime).inDays;

    if (differenceInMinutes < 1) {
      return 'Just now';
    } else if (differenceInMinutes < 60) {
      return '$differenceInMinutes min ago';
    } else if (differenceInHours < 24) {
      return '$differenceInHours hr ago';
    } else if (differenceInDays < 7) {
      return '$differenceInDays days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to see viewers')),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _profileService.getViewersStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4D85)),
            );
          }

          final viewers = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text(
                  'Recent Viewers',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                centerTitle: false,
                floating: true,
                snap: true,
                leading: IconButton(
                  icon: const Icon(Iconsax.arrow_left_2),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              if (viewers.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'People who visited your profile',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                _buildViewersGrid(context, viewers),
              ] else
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.eye_slash,
                          size: 64,
                          color: Theme.of(context)
                              .iconTheme
                              .color
                              ?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No views yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Keep active to get noticed!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildViewersGrid(
      BuildContext context, List<Map<String, dynamic>> viewers) {
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
            final viewer = viewers[index];
            final profile = viewer['profile'] as UserProfile;
            final timestamp = viewer['timestamp'] as Timestamp?;
            final photo = profile.photos.isNotEmpty
                ? profile.photos.first
                : 'https://images.unsplash.com/photo-1511367461989-f85a21fda167?q=80&w=800';

            return GestureDetector(
              onTap: () => _showProfileDetails(context, profile),
              child: Container(
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Iconsax.clock,
                              color: Color(0xFFFF4D85), size: 10),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(timestamp),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                                profile.getDistanceDisplay(
                                    profileProvider.userProfile),
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
              ),
            );
          },
          childCount: viewers.length,
        ),
      ),
    );
  }

  void _showProfileDetails(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileDetailSheet(
        profile: profile,
        onLike: () async {
          final profileProvider = context.read<ProfileProvider>();
          final myUid = profileProvider.currentUser?.uid;
          if (myUid != null && profile.uid != null) {
            await _profileService.swipeUser(myUid, profile.uid!, 'like',
                senderName: profileProvider.displayName);
          }
          if (context.mounted) Navigator.pop(context);
        },
        onDislike: () async {
          final profileProvider = context.read<ProfileProvider>();
          final myUid = profileProvider.currentUser?.uid;
          if (myUid != null && profile.uid != null) {
            await _profileService.swipeUser(myUid, profile.uid!, 'dislike',
                senderName: profileProvider.displayName);
          }
          if (context.mounted) Navigator.pop(context);
        },
        onMessage: () async {
          final myUid = FirebaseAuth.instance.currentUser?.uid;
          if (myUid == null || profile.uid == null) return;

          Navigator.pop(context);

          await ChatService().getOrCreateChat(myUid, profile.uid!);

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  otherUserId: profile.uid!,
                  otherUserName: profile.firstName ?? 'User',
                  otherUserPhoto: profile.photos.isNotEmpty
                      ? profile.photos.first
                      : null,
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
