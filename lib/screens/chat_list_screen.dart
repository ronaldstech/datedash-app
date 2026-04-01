import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import '../models/user_profile_model.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import 'chat_screen.dart';
import '../widgets/bordered_search_bar.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final ChatService _chatService;
  late final ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _profileService = ProfileService();
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    if (myUid == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view messages')),
      );
    }

    return Scaffold(
      body: StreamBuilder<List<Chat>>(
        stream: _chatService.getChatsStream(myUid),
        builder: (context, snapshot) {
          final chats = snapshot.data ?? [];
          final hasError = snapshot.hasError;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text(
                  'Messages',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                elevation: 0,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                centerTitle: false,
                floating: true,
                snap: true,
                actions: [
                  IconButton(
                    onPressed: () {
                      // Refresh the stream by rebuilding
                      setState(() {});
                    },
                    icon: Icon(
                      Iconsax.refresh,
                      color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      size: 24,
                    ),
                  ),
                  const BorderedSearchBar(),
                  const SizedBox(width: 8),
                ],
              ),

              // Error state
              if (hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.warning_2,
                          size: 48,
                          color: Colors.red.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load messages',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Empty state
              if (chats.isEmpty &&
                  snapshot.connectionState != ConnectionState.waiting &&
                  !hasError)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4D85).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.message,
                            size: 48,
                            color: Color(0xFFFF4D85),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No conversations yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Like someone to start a conversation',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading
              if (snapshot.connectionState == ConnectionState.waiting &&
                  chats.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF4D85)),
                  ),
                ),

              // Section header: New Matches
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'New Matches',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),

              // New Matches Horizontal List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: StreamBuilder<List<UserProfile>>(
                    stream: _profileService.getMatchesStream(myUid),
                    builder: (context, snapshot) {
                      final matches = snapshot.data ?? [];
                      if (matches.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            child: Text(
                              'No matches yet. Keep swiping!',
                              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          final photo = match.photos.isNotEmpty ? match.photos.first : null;
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserId: match.uid!,
                                    otherUserName: match.firstName ?? 'User',
                                    otherUserPhoto: photo,
                                  ),
                                ),
                              );
                              setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 34,
                                    backgroundColor: const Color(0xFFFF4D85).withOpacity(0.15),
                                    backgroundImage: photo != null ? NetworkImage(photo) : null,
                                    child: photo == null
                                        ? const Icon(Iconsax.user, color: Color(0xFFFF4D85), size: 28)
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    match.firstName ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Section header: Messages
              if (chats.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Recent Messages',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),

              // Chat list
              if (chats.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final chat = chats[index];
                      final otherUid = chat.otherUserId(myUid);
                      final unread = chat.unreadCount[myUid] ?? 0;

                      return FutureBuilder<UserProfile?>(
                        future: _profileService.getUserProfile(otherUid),
                        builder: (context, profileSnap) {
                          final profile = profileSnap.data;
                          final name = profile?.firstName ?? 'User';
                          final photo = profile?.photos.isNotEmpty == true
                              ? profile!.photos.first
                              : null;

                          return ListTile(
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    otherUserId: otherUid,
                                    otherUserName: name,
                                    otherUserPhoto: photo,
                                  ),
                                ),
                              );
                              // Refresh chats when returning from ChatScreen
                              if (result == true && mounted) {
                                setState(() {});
                              }
                            },
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 6),
                            leading: CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  const Color(0xFFFF4D85).withOpacity(0.15),
                              backgroundImage:
                                  photo != null ? NetworkImage(photo) : null,
                              child: photo == null
                                  ? const Icon(Iconsax.user,
                                      color: Color(0xFFFF4D85), size: 24)
                                  : null,
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontWeight: unread > 0
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _formatTime(chat.lastMessageTime),
                                  style: TextStyle(
                                    color: unread > 0
                                        ? const Color(0xFFFF4D85)
                                        : Theme.of(context).hintColor,
                                    fontSize: 12,
                                    fontWeight: unread > 0
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.lastMessage.isEmpty
                                        ? 'Say hello!'
                                        : (chat.lastMessageSenderId == myUid
                                            ? 'You: ${chat.lastMessage}'
                                            : chat.lastMessage),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: unread > 0
                                          ? Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color
                                          : Theme.of(context).hintColor,
                                      fontWeight: unread > 0
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                if (unread > 0)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4D85),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      unread > 99 ? '99+' : '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    childCount: chats.length,
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          );
        },
      ),
    );
  }
}
