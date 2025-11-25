import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../widgets/theme_switcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const SizedBox(height: 24),
            _buildPreferencesSection(context),
            const SizedBox(height: 24),
            _buildAboutSection(context),
            const SizedBox(height: 24),
            _buildSupportSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF6F4E37),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Theme.of(context).cardTheme.color,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coffee Lover',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'coffee.lover@example.com',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F4E37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Premium Member',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6F4E37),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preferences',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Theme Switcher Tile
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return ListTile(
                    leading: Icon(
                      Icons.palette_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(
                      'Theme',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      themeProvider.themeDisplayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Choose Theme'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildThemeOption(context, CoffeeTheme.morning, themeProvider),
                              _buildThemeOption(context, CoffeeTheme.evening, themeProvider),
                              _buildThemeOption(context, CoffeeTheme.sunset, themeProvider),
                              _buildThemeOption(context, CoffeeTheme.midnight, themeProvider),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(BuildContext context, CoffeeTheme theme, ThemeProvider provider) {
    final isSelected = provider.currentTheme == theme;

    return ListTile(
      leading: _buildThemeIcon(theme),
      title: Text(_getThemeDisplayName(theme)),
      subtitle: Text(_getThemeDescription(theme)),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
          : null,
      onTap: () {
        provider.setTheme(theme);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildThemeIcon(CoffeeTheme theme) {
    switch (theme) {
      case CoffeeTheme.morning:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8DC), Color(0xFFFFF4E6)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.wb_sunny, color: Color(0xFFD2691E), size: 20),
        );
      case CoffeeTheme.evening:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.nightlight_round, color: Color(0xFF6B46C1), size: 20),
        );
      case CoffeeTheme.sunset:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFCE7F3), Color(0xFFFECACA)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.wb_twilight, color: Color(0xFFEC4899), size: 20),
        );
      case CoffeeTheme.midnight:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.dark_mode, color: Color(0xFF10B981), size: 20),
        );
    }
  }

  String _getThemeDisplayName(CoffeeTheme theme) {
    switch (theme) {
      case CoffeeTheme.morning:
        return 'Morning Coffee';
      case CoffeeTheme.evening:
        return 'Evening Vibes';
      case CoffeeTheme.sunset:
        return 'Sunset Mode';
      case CoffeeTheme.midnight:
        return 'Midnight Brew';
    }
  }

  String _getThemeDescription(CoffeeTheme theme) {
    switch (theme) {
      case CoffeeTheme.morning:
        return 'Light & cozy';
      case CoffeeTheme.evening:
        return 'Dark & elegant';
      case CoffeeTheme.sunset:
        return 'Vibrant & romantic';
      case CoffeeTheme.midnight:
        return 'Minimalist & professional';
    }
  }

  Widget _buildSettingsTile(String title,
                'Within 5 km',
                Icons.location_searching_outlined,
                () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                'Preferred Coffee Types',
                'Espresso, Cappuccino, Latte',
                Icons.coffee_outlined,
                () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                'Notifications',
                'Enabled for nearby shops',
                Icons.notifications_outlined,
                () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                'Map Style',
                'Standard',
                Icons.map_outlined,
                () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'About',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                'Rate App',
                'Share your feedback',
                Icons.star_rate_outlined,
                () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                'Share App',
                'Tell your friends',
                Icons.share_outlined,
                () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                'Privacy Policy',
                'How we protect your data',
                Icons.privacy_tip_outlined,
                () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                'Terms of Service',
                'Rules and guidelines',
                Icons.description_outlined,
                () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Support',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsTile(
                'Help Center',
                'Get help and support',
                Icons.help_outline,
                () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                'Contact Us',
                'Send us a message',
                Icons.mail_outline,
                () {},
              ),
              _buildDivider(),
              _buildSettingsTile(
                'Report a Problem',
                'Help us improve the app',
                Icons.bug_report_outlined,
                () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF6F4E37),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }
}