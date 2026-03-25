import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/auth/sign_in_screen.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({super.key});

  void _handleLogout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                final user = snapshot.data;
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFFF4D85),
                        backgroundImage: user?.photoURL != null 
                            ? NetworkImage(user!.photoURL!) 
                            : null,
                        child: user?.photoURL == null 
                            ? const Icon(Iconsax.user, color: Colors.white, size: 30)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              user?.displayName ?? 'Guest User',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? 'View and edit profile',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 10),
                  _buildItem(context, Iconsax.profile_circle, 'My Profile', color: const Color(0xFFFF4D85)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildGroup(
                    context,
                    Iconsax.activity,
                    'My Activity',
                    [
                      _buildItem(context, Iconsax.heart_tick, 'Matches', color: const Color(0xFFFF4D85)),
                      _buildItem(context, Iconsax.eye, 'Visitors'),
                      _buildItem(context, Iconsax.heart5, 'Likes', color: const Color(0xFFFF4D85)),
                      _buildItem(context, Iconsax.document_text, 'Blog'),
                      _buildItem(context, Iconsax.video_circle, 'Live Videos'),
                    ],
                  ),
                  _buildGroup(
                    context,
                    Iconsax.user_octagon,
                    'Social',
                    [
                      _buildItem(context, Iconsax.discover_1, 'Explore People'),
                      _buildItem(context, Iconsax.user_add, 'Friend Requests'),
                      _buildItem(context, Iconsax.people, 'My People'),
                    ],
                  ),
                  _buildGroup(
                    context,
                    Iconsax.wallet_2,
                    'Finance',
                    [
                      _buildItem(context, Iconsax.ranking, 'Premium', color: const Color(0xFFFFD700)),
                      _buildItem(context, Iconsax.gift, 'Gifts', color: Colors.purple.shade400),
                      _buildItem(context, Iconsax.receipt_21, 'Transactions'),
                      _buildItem(context, Iconsax.money_2, 'Credits'),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildItem(context, Iconsax.setting_2, 'Settings'),
                  _buildItem(context, Iconsax.moon, 'Night Mode'),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildItem(
                    context,
                    Iconsax.logout,
                    'Logout',
                    color: Colors.red.shade400,
                    onTap: () => _handleLogout(context),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(BuildContext context, IconData icon, String title, List<Widget> children) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.grey.shade800, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        iconColor: const Color(0xFFFF4D85),
        collapsedIconColor: Colors.grey.shade400,
        childrenPadding: const EdgeInsets.only(left: 12, bottom: 8),
        children: children,
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade600, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap ?? () {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
