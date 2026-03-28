import 'package:flutter/material.dart';
import '../widgets/bordered_search_bar.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
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
              const BorderedSearchBar(),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(child: _buildMatchQueue(context)),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Recent Messages',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _buildChatList(context),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  Widget _buildMatchQueue(BuildContext context) {
    final matches = [
      {'name': 'Lily', 'img': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2'},
      {'name': 'Megan', 'img': 'https://images.unsplash.com/photo-1517841905240-472988babdf9'},
      {'name': 'Zoe', 'img': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1'},
      {'name': 'Grace', 'img': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04'},
      {'name': 'Harper', 'img': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Match Queue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFFF4D85)),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(matches[index]['img']!),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      matches[index]['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

  Widget _buildChatList(BuildContext context) {
    final chats = [
      {
        'name': 'Sarah',
        'img': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
        'lastMsg': 'Hey! How is your day going?',
        'time': '2m ago',
        'unread': true
      },
      {
        'name': 'Jessica',
        'img': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
        'lastMsg': 'That sounds like a lot of fun!',
        'time': '1h ago',
        'unread': false
      },
      {
        'name': 'Emily',
        'img': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        'lastMsg': 'Haha, definitely 😂',
        'time': '3h ago',
        'unread': false
      },
      {
        'name': 'Chloe',
        'img': 'https://images.unsplash.com/photo-1517841905240-472988babdf9',
        'lastMsg': 'Where do you want to meet?',
        'time': 'Yesterday',
        'unread': false
      },
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chat = chats[index];
          final bool isUnread = chat['unread'] as bool;

          return ListTile(
            onTap: () {},
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(chat['img'] as String),
                ),
                if (index == 0) // Example online status
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                  ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  chat['name'] as String,
                  style: TextStyle(
                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  chat['time'] as String,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    chat['lastMsg'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUnread ? Theme.of(context).textTheme.bodyLarge?.color : Theme.of(context).hintColor,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isUnread)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4D85),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
        childCount: chats.length,
      ),
    );
  }
}
