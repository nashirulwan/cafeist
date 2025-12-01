import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Profile',
              style: GoogleFonts.inter(
                color: themeProvider.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
                  color: themeProvider.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: themeProvider.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coffee Lover',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'coffee.lover@example.com',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.primaryTextColor,
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
              child: ListTile(
                leading: Icon(
                  Icons.palette_outlined,
                  color: themeProvider.accentColor,
                ),
                title: Text(
                  'Theme',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: themeProvider.primaryTextColor,
                  ),
                ),
                subtitle: Text(
                  themeProvider.themeDisplayName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: themeProvider.secondaryTextColor,
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Choose Theme',
                        style: GoogleFonts.inter(
                          color: themeProvider.primaryTextColor,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildThemeOption(
                              context, CoffeeTheme.morning, themeProvider),
                          _buildThemeOption(
                              context, CoffeeTheme.evening, themeProvider),
                          _buildThemeOption(
                              context, CoffeeTheme.sunset, themeProvider),
                          _buildThemeOption(
                              context, CoffeeTheme.midnight, themeProvider),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: GoogleFonts.inter(
                              color: themeProvider.accentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
      BuildContext context, CoffeeTheme theme, ThemeProvider provider) {
    final isSelected = provider.currentTheme == theme;

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListTile(
          leading: _buildThemeIcon(theme),
          title: Text(
            _getThemeDisplayName(theme),
            style: GoogleFonts.inter(
              color: themeProvider.primaryTextColor,
            ),
          ),
          subtitle: Text(
            _getThemeDescription(theme),
            style: GoogleFonts.inter(
              color: themeProvider.secondaryTextColor,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_circle, color: themeProvider.accentColor)
              : null,
          onTap: () {
            provider.setTheme(theme);
            Navigator.pop(context);
          },
        );
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
          child: const Icon(Icons.nightlight_round,
              color: Color(0xFF6B46C1), size: 20),
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
          child:
              const Icon(Icons.wb_twilight, color: Color(0xFFEC4899), size: 20),
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
          child:
              const Icon(Icons.dark_mode, color: Color(0xFF10B981), size: 20),
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

  Widget _buildAboutSection(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: themeProvider.primaryTextColor,
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
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: themeProvider.accentColor,
                    ),
                    title: Text(
                      'Version',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: themeProvider.primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      '0.59.111',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: themeProvider.secondaryTextColor.withOpacity(0.2),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.code_outlined,
                      color: themeProvider.accentColor,
                    ),
                    title: Text(
                      'Developer',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        color: themeProvider.primaryTextColor,
                      ),
                    ),
                    subtitle: Text(
                      'nashirulwan',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
