import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.getString('settings_title'),
          style: const TextStyle(fontWeight: FontWeight.w800),
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
          _buildSectionHeader(languageProvider.getString('account')),
          _buildSettingTile(
            context,
            Iconsax.user_edit,
            languageProvider.getString('edit_profile'),
            languageProvider.getString('edit_profile_sub'),
            onTap: () => Navigator.pop(context), 
          ),
          _buildSettingTile(
            context,
            Iconsax.sms,
            languageProvider.getString('email_settings'),
            languageProvider.getString('email_settings_sub'),
          ),
          _buildSettingTile(
            context,
            Iconsax.lock,
            languageProvider.getString('security'),
            languageProvider.getString('security_sub'),
          ),
          const SizedBox(height: 20),
          _buildPrivacySection(context, languageProvider),
          const SizedBox(height: 20),
          _buildSectionHeader(languageProvider.getString('preferences')),
          _buildThemeTile(context, themeProvider, languageProvider),
          _buildSettingTile(
            context,
            Iconsax.notification,
            languageProvider.getString('notifications'),
            languageProvider.getString('notifications_sub'),
          ),
          _buildLanguageTile(context),
          const SizedBox(height: 20),
          _buildSectionHeader(languageProvider.getString('discovery')),
          _buildResetSwipesTile(context),
          const SizedBox(height: 20),
          _buildSectionHeader(languageProvider.getString('support')),
          _buildSettingTile(
            context,
            Iconsax.info_circle,
            languageProvider.getString('help_center'),
            languageProvider.getString('help_center_sub'),
          ),
          _buildSettingTile(
            context,
            Iconsax.document_text,
            languageProvider.getString('terms_of_service'),
            languageProvider.getString('terms_of_service_sub'),
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
        title: Text(
          context.read<LanguageProvider>().getString('reset_swipes'),
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          context.read<LanguageProvider>().getString('reset_swipes_sub'),
          style: const TextStyle(color: Colors.orange, fontSize: 12),
        ),
        trailing: const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.orange),
        onTap: () => _showResetSwipesDialog(context, context.read<LanguageProvider>()),
      ),
    );
  }

  void _showResetSwipesDialog(BuildContext context, LanguageProvider languageProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Iconsax.refresh, color: Colors.orange),
            const SizedBox(width: 10),
            Text(languageProvider.getString('reset_swipes_title'), style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Text(
          languageProvider.getString('reset_swipes_content'),
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(languageProvider.getString('cancel'), style: const TextStyle(fontWeight: FontWeight.w600)),
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
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              languageProvider.getString('swipes_reset_success'),
                              style: const TextStyle(fontWeight: FontWeight.w600),
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
                      content: Text(languageProvider.getString('swipes_reset_failed')),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                }
              }
            },
            child: Text(languageProvider.getString('reset'), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeTile(BuildContext context, ThemeProvider themeProvider, LanguageProvider languageProvider) {
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
        title: Text(
          languageProvider.getString('night_mode'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Text(
          themeProvider.isDarkMode 
              ? languageProvider.getString('night_mode_on') 
              : languageProvider.getString('night_mode_off'),
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
        title: Text(
          context.read<LanguageProvider>().getString('delete_account'),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          context.read<LanguageProvider>().getString('delete_account_sub'),
          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
        ),
        onTap: () {
          // Show confirmation dialog
        },
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, LanguageProvider languageProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(languageProvider.getString('privacy_visibility')),
        Consumer<ProfileProvider>(
          builder: (context, profileProvider, _) {
            final profile = profileProvider.userProfile;
            if (profile == null) return const SizedBox.shrink();

            return Column(
              children: [
                _buildPrivacyTile(
                  context,
                  Iconsax.user_tag,
                  languageProvider.getString('show_age'),
                  languageProvider.getString('show_age_sub'),
                  profile.showAge,
                  (val) {
                    profile.showAge = val;
                    final user = profileProvider.currentUser;
                    if (user != null) {
                      profileProvider.saveUserProfile(user.uid, profile);
                    }
                  },
                ),
                _buildPrivacyTile(
                  context,
                  Iconsax.location_add,
                  languageProvider.getString('show_distance'),
                  languageProvider.getString('show_distance_sub'),
                  profile.showDistance,
                  (val) {
                    profile.showDistance = val;
                    final user = profileProvider.currentUser;
                    if (user != null) {
                      profileProvider.saveUserProfile(user.uid, profile);
                    }
                  },
                ),
                _buildPrivacyTile(
                  context,
                  Iconsax.message_notif,
                  languageProvider.getString('allow_messages_label'),
                  languageProvider.getString('allow_messages_sub'),
                  profile.allowMessages,
                  (val) {
                    profile.allowMessages = val;
                    final user = profileProvider.currentUser;
                    if (user != null) {
                      profileProvider.saveUserProfile(user.uid, profile);
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrivacyTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
                Theme.of(context).brightness == Brightness.light ? 0.03 : 0.2),
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
        value: value,
        activeColor: const Color(0xFFFF4D85),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    return _buildSettingTile(
      context,
      Iconsax.global,
      languageProvider.getString('language'),
      languageProvider.currentLanguageName,
      onTap: () => _showLanguageSelector(context),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.getString('select_language'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: languageProvider.supportedLanguages.map((lang) {
                    final isSelected = languageProvider.currentLanguageCode == lang['code'];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF4D85).withOpacity(0.1) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Iconsax.global,
                          size: 18,
                          color: isSelected ? const Color(0xFFFF4D85) : Theme.of(context).hintColor,
                        ),
                      ),
                      title: Text(
                        lang['name']!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? const Color(0xFFFF4D85) : null,
                        ),
                      ),
                      trailing: isSelected 
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFFFF4D85))
                        : null,
                      onTap: () {
                        languageProvider.setLanguage(lang['code']!);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
