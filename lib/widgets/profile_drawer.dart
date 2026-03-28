import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../theme/theme_provider.dart';
import '../providers/profile_provider.dart';

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
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, _) {
                final photoUrl = profileProvider.photoURL;
                final displayName = profileProvider.displayName;
                final email = profileProvider.currentUser?.email ?? 'View and edit profile';

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFFF4D85),
                        child: ClipOval(
                          child: photoUrl != null
                              ? Image.network(
                                  photoUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Iconsax.user,
                                        color: Colors.white, size: 30);
                                  },
                                )
                              : const Icon(Iconsax.user,
                                  color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              email,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Theme.of(context).hintColor,
                                  fontSize: 13),
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
                  _buildItem(
                    context,
                    Iconsax.profile_circle,
                    'My Profile',
                    color: const Color(0xFFFF4D85),
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ProfileScreen()),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildGroup(
                    context,
                    Iconsax.activity,
                    'My Activity',
                    [
                      _buildItem(context, Iconsax.heart_tick, 'Matches',
                          color: const Color(0xFFFF4D85)),
                      _buildItem(context, Iconsax.eye, 'Visitors'),
                      _buildItem(context, Iconsax.heart5, 'Likes',
                          color: const Color(0xFFFF4D85)),
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
                      _buildItem(context, Iconsax.ranking, 'Premium',
                          color: const Color(0xFFFFD700)),
                      _buildItem(context, Iconsax.gift, 'Gifts',
                          color: Colors.purple.shade400),
                      _buildItem(context, Iconsax.receipt_21, 'Transactions'),
                      _buildItem(context, Iconsax.money_2, 'Credits'),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _buildItem(
                    context,
                    Iconsax.setting_2,
                    'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                  ),
                  _buildItem(
                    context,
                    context.read<ThemeProvider>().isDarkMode
                        ? Iconsax.sun_1
                        : Iconsax.moon,
                    context.read<ThemeProvider>().isDarkMode
                        ? 'Light Mode'
                        : 'Night Mode',
                    onTap: () {
                      context.read<ThemeProvider>().toggleTheme();
                    },
                  ),
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

  Widget _buildGroup(BuildContext context, IconData icon, String title,
      List<Widget> children) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon,
            color: Theme.of(context).iconTheme.color?.withOpacity(0.8),
            size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
            letterSpacing: 0.2,
          ),
        ),
        iconColor: const Color(0xFFFF4D85),
        collapsedIconColor: Theme.of(context).hintColor.withOpacity(0.5),
        childrenPadding: const EdgeInsets.only(left: 12, bottom: 8),
        children: children,
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title,
      {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon,
          color: color ?? Theme.of(context).iconTheme.color?.withOpacity(0.7),
          size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyMedium?.color,
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
