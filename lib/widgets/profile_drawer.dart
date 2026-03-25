import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFFF4D85),
                    child: Icon(Iconsax.user, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Name',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'View and edit profile',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildItem(Iconsax.user, 'Profile'),
                  _buildItem(Icons.monetization_on_rounded, 'Credits'),
                  _buildItem(
                    Icons.star_rounded,
                    'Premium',
                    color: const Color(0xFFFF4D85),
                  ),
                  _buildItem(Iconsax.discover, 'Explore People'),
                  _buildItem(
                    Icons.favorite_rounded,
                    'Matches',
                    color: const Color(0xFFFF4D85),
                  ),
                  _buildItem(Icons.calendar_month_rounded, 'Bookings'),
                  _buildItem(Icons.remove_red_eye_rounded, 'Visitors'),
                  _buildItem(Icons.people_rounded, 'Friends'),
                  _buildItem(Icons.person_add_rounded, 'Friend Requests'),
                  _buildItem(
                    Icons.card_giftcard_rounded,
                    'Gifts',
                    color: Colors.purple,
                  ),
                  _buildItem(Iconsax.heart, 'Likes'),
                  _buildItem(Icons.groups_rounded, 'My People'),
                  _buildItem(
                    Icons.local_fire_department_rounded,
                    'Hot',
                    color: Colors.orange,
                  ),
                  _buildItem(Icons.article_rounded, 'Blog'),
                  _buildItem(Icons.videocam_rounded, 'Live Videos'),
                  const Divider(),
                  _buildItem(Iconsax.setting_2, 'Settings'),
                  _buildItem(Icons.dark_mode_rounded, 'Night Mode'),
                  _buildItem(Icons.receipt_long_rounded, 'Transactions'),
                  const Divider(),
                  _buildItem(
                    Icons.logout_rounded,
                    'Logout',
                    color: Colors.red,
                    onTap: () => _handleLogout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String title, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: color ?? Colors.black87,
        ),
      ),
      onTap: onTap ?? () {},
    );
  }
}
