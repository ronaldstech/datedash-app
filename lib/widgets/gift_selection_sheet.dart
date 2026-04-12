import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../providers/language_provider.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';

class GiftItem {
  final String id;
  final String icon;
  final String name;
  final int cost;
  final Color color;

  GiftItem({
    required this.id,
    required this.icon,
    required this.name,
    required this.cost,
    required this.color,
  });
}

class GiftSelectionSheet extends StatelessWidget {
  final String targetUserId;
  final String targetUserName;

  const GiftSelectionSheet({
    super.key,
    required this.targetUserId,
    required this.targetUserName,
  });

  static final List<GiftItem> gifts = [
    GiftItem(id: 'rose', icon: '🌹', name: 'Rose', cost: 50, color: Colors.red),
    GiftItem(id: 'chocolate', icon: '🍫', name: 'Chocolate', cost: 150, color: Colors.brown),
    GiftItem(id: 'teddy', icon: '🧸', name: 'Teddy Bear', cost: 300, color: Colors.orange),
    GiftItem(id: 'champagne', icon: '🥂', name: 'Champagne', cost: 500, color: Colors.amber),
    GiftItem(id: 'diamond', icon: '💎', name: 'Diamond', cost: 1000, color: Colors.blueAccent),
    GiftItem(id: 'ring', icon: '💍', name: 'Ring', cost: 5000, color: Colors.teal),
  ];

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final userCredits = profileProvider.userProfile?.credits ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageProvider.getString('send_gift'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.coin, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$userCredits',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.amber,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Surprise $targetUserName with a special gift!',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];
              final canAfford = userCredits >= gift.cost;

              return GestureDetector(
                onTap: canAfford ? () => _handleSendGift(context, gift) : null,
                child: Opacity(
                  opacity: canAfford ? 1.0 : 0.5,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: canAfford 
                          ? gift.color.withOpacity(0.2) 
                          : Colors.grey.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          gift.icon,
                          style: const TextStyle(fontSize: 32),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          gift.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Iconsax.coin, size: 12, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${gift.cost}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _handleSendGift(BuildContext context, GiftItem gift) async {
    final profileProvider = context.read<ProfileProvider>();
    final languageProvider = context.read<LanguageProvider>();

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Send ${gift.name}?'),
        content: Text('This will cost ${gift.cost} credits.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(languageProvider.getString('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D85),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(languageProvider.getString('confirm_button')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final myUid = profileProvider.currentUser?.uid;
        if (myUid == null) return;

        // 1. Deduct cost from sender
        await profileProvider.useCredits(gift.cost);

        // 2. Add full reward to recipient
        await ProfileService().addCredits(targetUserId, gift.cost);

        // 3. Send notification to recipient
        await NotificationService().sendNotification(
          recipientId: targetUserId,
          senderId: myUid,
          senderName: profileProvider.displayName,
          type: 'gift',
          message: '${gift.icon} ${gift.name}',
        );

        if (context.mounted) {
          Navigator.pop(context); // Close selection sheet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(gift.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      languageProvider.getString('gift_sent_success'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send gift: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
