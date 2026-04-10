import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/likes_screen.dart';
import '../screens/profile_viewers_screen.dart';
import '../screens/chat_list_screen.dart';
import '../theme/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/language_provider.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = context.watch<LanguageProvider>();

    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Premium Header with Glassmorphism
            Consumer<ProfileProvider>(
              builder: (context, profileProvider, _) {
                final photoUrl = profileProvider.photoURL;
                final displayName = profileProvider.displayName;
                final email =
                    profileProvider.currentUser?.email ?? languageProvider.getString('join_community');

                return Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFFF4D85).withOpacity(0.15),
                        const Color(0xFFFF4D85).withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFFF4D85),
                                    Color(0xFFFF8E8E)
                                  ],
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 42,
                                backgroundColor:
                                    isDark ? Colors.black : Colors.white,
                                child: ClipOval(
                                  child: photoUrl != null
                                      ? Image.network(
                                          photoUrl,
                                          width: 84,
                                          height: 84,
                                          fit: BoxFit.cover,
                                        )
                                      : const Icon(Iconsax.user,
                                          size: 40, color: Color(0xFFFF4D85)),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF4D85),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Stats Row — real numbers, tappable
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              context,
                              languageProvider.getString('likes_label'),
                              profileProvider.likesCount.toString(),
                              Iconsax.heart5,
                              const Color(0xFFFF4D85),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => LikesScreen()));
                              },
                            ),
                            Container(
                                width: 1,
                                height: 24,
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.2)),
                            _buildStatItem(
                              context,
                              languageProvider.getString('visitors_label'),
                              profileProvider.visitorsCount.toString(),
                              Iconsax.eye,
                              Colors.blueAccent,
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            ProfileViewersScreen()));
                              },
                            ),
                            Container(
                                width: 1,
                                height: 24,
                                color: Theme.of(context)
                                    .dividerColor
                                    .withOpacity(0.2)),
                            _buildStatItem(
                              context,
                              languageProvider.getString('matches_label'),
                              profileProvider.matchesCount.toString(),
                              Iconsax.flash5,
                              const Color(0xFFFFD700),
                              onTap: () {
                                Navigator.pop(context);
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const ChatListScreen()));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  const SizedBox(height: 4),

                  // Account Section
                  _buildSectionHeader(context, languageProvider.getString('account_section')),
                  _buildItem(
                    context,
                    Iconsax.user,
                    languageProvider.getString('my_profile'),
                    backgroundColor: const Color(0xFFFF4D85),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProfileScreen()));
                    },
                  ),
                  _buildItem(
                    context,
                    Iconsax.setting_2,
                    languageProvider.getString('settings_label'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()));
                    },
                  ),
                  const SizedBox(height: 4),

                  // Discovery Section
                  _buildSectionHeader(context, languageProvider.getString('discovery_section')),
                  _buildItem(context, Iconsax.discover_1, languageProvider.getString('explore_people')),
                  const SizedBox(height: 4),

                  // Activity Section
                  _buildSectionHeader(context, languageProvider.getString('activity_section')),
                  _buildItem(
                    context,
                    Iconsax.heart_tick,
                    languageProvider.getString('matches_label'),
                    color: const Color(0xFFFF4D85),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ChatListScreen()));
                    },
                  ),
                  _buildItem(
                    context,
                    Iconsax.eye,
                    languageProvider.getString('visitors_label'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ProfileViewersScreen()));
                    },
                  ),
                  _buildItem(context, Iconsax.document_text, languageProvider.getString('blog')),
                  _buildItem(context, Iconsax.video_circle, languageProvider.getString('live_videos')),
                  _buildItem(
                    context,
                    Iconsax.heart5,
                    languageProvider.getString('likes_label'),
                    color: const Color(0xFFFF4D85),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => LikesScreen()));
                    },
                  ),
                  const SizedBox(height: 20),

                  // Finance Section - Subscription & Credits
                  _buildSectionHeader(context, languageProvider.getString('finance_section')),
                  _buildItem(
                    context,
                    Iconsax.ranking,
                    languageProvider.getString('go_premium'),
                    color: const Color(0xFFFFD700),
                    onTap: () {},
                  ),
                  _buildItem(context, Iconsax.wallet_2, languageProvider.getString('my_credits')),
                  _buildItem(context, Iconsax.gift, languageProvider.getString('gifts'),
                      color: Colors.purple.shade300),
                  _buildItem(context, Iconsax.receipt_21, languageProvider.getString('transactions')),
                  const SizedBox(height: 20),

                  // Appearance Section
                  _buildSectionHeader(context, languageProvider.getString('appearance_section')),
                  _buildThemeToggle(context, languageProvider),
                  const SizedBox(height: 20),

                  // Support Section
                  _buildSectionHeader(context, languageProvider.getString('support_section')),
                  _buildItem(context, Iconsax.info_circle, languageProvider.getString('about_us')),
                  _buildItem(context, Iconsax.security_safe, languageProvider.getString('safety_tips')),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context, languageProvider),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.06) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
          color: Theme.of(context).hintColor.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, IconData icon, String title,
      {Color? color, Color? backgroundColor, VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor ??
            (isDark
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: backgroundColor != null
              ? backgroundColor.withOpacity(0.3)
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.05)),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor != null
                ? Colors.white.withOpacity(0.2)
                : (color ?? const Color(0xFFFF4D85)).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon,
              color: backgroundColor != null
                  ? Colors.white
                  : (color ?? Theme.of(context).iconTheme.color),
              size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: backgroundColor != null ? Colors.white : null),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 12,
            color: backgroundColor != null
                ? Colors.white.withOpacity(0.7)
                : Theme.of(context).hintColor.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, LanguageProvider languageProvider) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(isDark ? Iconsax.moon : Iconsax.sun_1, size: 22),
              const SizedBox(width: 12),
              Text(
                isDark ? languageProvider.getString('dark_mode') : languageProvider.getString('light_mode'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Switch.adaptive(
            value: isDark,
            activeColor: const Color(0xFFFF4D85),
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, LanguageProvider languageProvider) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
        onTap: () => _handleLogout(context),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Iconsax.logout, color: Colors.redAccent, size: 20),
        ),
        title: Text(
          languageProvider.getString('logout'),
          style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 15,
              fontWeight: FontWeight.w800),
        ),
        subtitle: Text(languageProvider.getString('logout_sub'),
            style: const TextStyle(fontSize: 12)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.redAccent.withOpacity(0.2)),
        ),
        tileColor: Colors.redAccent.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
