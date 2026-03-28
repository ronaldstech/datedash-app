import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../providers/profile_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingTile(
            context,
            Iconsax.user_edit,
            'Edit Profile',
            'Change your profile details',
            onTap: () => Navigator.pop(context), // Should go back or to edit profile
          ),
          _buildSettingTile(
            context,
            Iconsax.sms,
            'Email Settings',
            'Update your email address',
          ),
          _buildSettingTile(
            context,
            Iconsax.lock,
            'Privacy & Security',
            'Password, blocked users',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Preferences'),
          _buildThemeTile(context, themeProvider),
          _buildSettingTile(
            context,
            Iconsax.notification,
            'Notifications',
            'Push and email alerts',
          ),
          _buildSettingTile(
            context,
            Iconsax.global,
            'Language',
            'English (US)',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Discovery'),
          _buildResetSwipesTile(context),
          const SizedBox(height: 20),
          _buildSectionHeader('Support'),
          _buildSettingTile(
            context,
            Iconsax.info_circle,
            'Help Center',
            'FAQs and support chat',
          ),
          _buildSettingTile(
            context,
            Iconsax.document_text,
            'Terms of Service',
            'Legal information',
          ),
          const SizedBox(height: 30),
          _buildDangerZoneTile(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFFFF4D85),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.03 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D85).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFFF4D85), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Iconsax.arrow_right_3,
          size: 18,
          color: Theme.of(context).hintColor,
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildResetSwipesTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.refresh, color: Colors.orange, size: 22),
        ),
        title: const Text(
          'Reset Swipes',
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: const Text(
          'See previously swiped profiles again',
          style: TextStyle(color: Colors.orange, fontSize: 12),
        ),
        trailing: const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.orange),
        onTap: () => _showResetSwipesDialog(context),
      ),
    );
  }

  void _showResetSwipesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Iconsax.refresh, color: Colors.orange),
            SizedBox(width: 10),
            Text('Reset Swipes', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text(
          'This will clear your entire swipe history. You will see all users again, including those you disliked.\n\nThis action cannot be undone.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<ProfileProvider>().resetSwipes();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Swipes reset! Fresh profiles are loading.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.orange,
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
                      content: const Text('Failed to reset swipes. Please try again.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.03 : 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            themeProvider.isDarkMode ? Iconsax.moon5 : Iconsax.sun5,
            color: Colors.deepPurple,
            size: 22,
          ),
        ),
        title: const Text(
          'Night Mode',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          themeProvider.isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 12,
          ),
        ),
        value: themeProvider.isDarkMode,
        activeColor: const Color(0xFFFF4D85),
        onChanged: (_) => themeProvider.toggleTheme(),
      ),
    );
  }

  Widget _buildDangerZoneTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.trash, color: Colors.white, size: 20),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        subtitle: const Text(
          'Permanently remove your profile and data',
          style: TextStyle(color: Colors.redAccent, fontSize: 11),
        ),
        onTap: () {
          // Show confirmation dialog
        },
      ),
    );
  }
}
