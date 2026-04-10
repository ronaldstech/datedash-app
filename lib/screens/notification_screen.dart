import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../models/user_profile_model.dart';
import '../providers/profile_provider.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../widgets/profile_detail_sheet.dart';
import '../services/chat_service.dart';
import '../utils/date_formatter.dart';
import 'chat_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final ProfileService _profileService = ProfileService();

  String _formatDateTime(DateTime dateTime) {
    return DateFormatter.format(dateTime);
  }

  Map<String, List<DatedashNotification>> _groupNotifications(
      List<DatedashNotification> notifications) {
    final Map<String, List<DatedashNotification>> groups = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));

    for (var n in notifications) {
      final DateTime nDate =
          DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day);
      if (nDate == today) {
        groups['Today']!.add(n);
      } else if (nDate == yesterday) {
        groups['Yesterday']!.add(n);
      } else {
        groups['Earlier']!.add(n);
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to see notifications')),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<DatedashNotification>>(
        stream: _notificationService.getNotificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4D85)));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) return _buildEmptyState(context);

          final grouped = _groupNotifications(notifications);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                flexibleSpace: const FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                  title: Text(
                    'Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () =>
                        _notificationService.markAllAsRead(user.uid),
                    child: const Text('Mark all as read',
                        style: TextStyle(
                            color: Color(0xFFFF4D85),
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              if (grouped['Today']!.isNotEmpty)
                _buildSectionHeader('New for you'),
              if (grouped['Today']!.isNotEmpty)
                _buildNotificationSliver(grouped['Today']!),
              if (grouped['Yesterday']!.isNotEmpty)
                _buildSectionHeader('Yesterday'),
              if (grouped['Yesterday']!.isNotEmpty)
                _buildNotificationSliver(grouped['Yesterday']!),
              if (grouped['Earlier']!.isNotEmpty) _buildSectionHeader('Earlier'),
              if (grouped['Earlier']!.isNotEmpty)
                _buildNotificationSliver(grouped['Earlier']!),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Text(
          title,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildNotificationSliver(List<DatedashNotification> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _NotificationCard(
            notification: items[index],
            service: _notificationService,
            profileService: _profileService,
            onPop: () => setState(() {}),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4D85).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.notification_bing,
                size: 80, color: Color(0xFFFF4D85)),
          ),
          const SizedBox(height: 24),
          const Text(
            'Keep it quiet?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'New likes and views will appear here',
            style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 16,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final DatedashNotification notification;
  final NotificationService service;
  final ProfileService profileService;
  final VoidCallback onPop;

  const _NotificationCard({
    required this.notification,
    required this.service,
    required this.profileService,
    required this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLike = notification.type == 'like';
    final bool isMissedCall = notification.type == 'missed_call';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _handleTap(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.transparent
                : const Color(0xFFFF4D85).withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: notification.isRead
                  ? Colors.grey.withOpacity(0.08)
                  : const Color(0xFFFF4D85).withOpacity(0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              _buildAvatar(context),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 15),
                        children: [
                          TextSpan(
                              text: notification.senderName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          TextSpan(
                              text: isLike
                                  ? ' liked your profile'
                                  : isMissedCall
                                      ? ' missed your call'
                                      : ' viewed your profile'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDateTime(notification.timestamp),
                      style: TextStyle(
                        color: Theme.of(context).hintColor.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4D85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: Color(0xFFFF4D85),
                          blurRadius: 6,
                          spreadRadius: 1)
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final bool isLike = notification.type == 'like';
    final bool isMissedCall = notification.type == 'missed_call';
    final IconData icon = isLike
        ? Iconsax.heart5
        : isMissedCall
            ? Iconsax.call_slash
            : Iconsax.eye;
    final Color badgeColor = isLike
        ? const Color(0xFFFF4D85)
        : isMissedCall
            ? Colors.red
            : Colors.blue;

    return FutureBuilder<UserProfile?>(
      future: profileService.getUserProfile(notification.senderId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final photo =
            profile?.photos.isNotEmpty == true ? profile!.photos.first : null;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
                image: photo != null
                    ? DecorationImage(
                        image: NetworkImage(photo), fit: BoxFit.cover)
                    : null,
              ),
              child: photo == null
                  ? const Icon(Iconsax.user, size: 24, color: Colors.grey)
                  : null,
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2),
                ),
                child: Icon(icon, color: Colors.white, size: 10),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormatter.format(dateTime);
  }

  void _handleTap(BuildContext context) async {
    service.markAsRead(notification.id);
    onPop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF4D85))),
    );

    try {
      final senderProfile = await profileService.getUserProfile(notification.senderId);
      if (context.mounted) Navigator.pop(context);

      if (senderProfile != null && context.mounted) {
        _showProfileDetails(context, senderProfile);
      }
    } catch (_) {
      if (context.mounted) Navigator.pop(context);
    }
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
            await profileService.swipeUser(myUid, profile.uid!, 'like',
                senderName: profileProvider.displayName);
          }
          if (context.mounted) Navigator.pop(context);
        },
        onDislike: () async {
          final profileProvider = context.read<ProfileProvider>();
          final myUid = profileProvider.currentUser?.uid;
          if (myUid != null && profile.uid != null) {
            await profileService.swipeUser(myUid, profile.uid!, 'dislike',
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
            Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
              otherUserId: profile.uid!,
              otherUserName: profile.firstName ?? 'User',
              otherUserPhoto: profile.photos.isNotEmpty ? profile.photos.first : null,
            )));
          }
        },
      ),
    );
  }
}
