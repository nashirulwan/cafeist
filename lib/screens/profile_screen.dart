import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';

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
                _buildAccountSection(context),
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
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        final user = authProvider.user;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Profile Photo
              GestureDetector(
                onTap: () => _showProfilePhotoOptions(context, authProvider),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: themeProvider.accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: themeProvider.accentColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: user?.photoURL != null
                        ? CachedNetworkImage(
                            imageUrl: user!.photoURL!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.withValues(alpha: 0.3),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: themeProvider.accentColor,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.withValues(alpha: 0.3),
                              child: Icon(
                                Icons.person,
                                size: 40,
                                color: themeProvider.accentColor,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 40,
                            color: themeProvider.accentColor,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user?.displayName ?? 'Guest User',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: themeProvider.primaryTextColor,
                            ),
                          ),
                        ),
                        // Change Name Button
                        if (user != null)
                          GestureDetector(
                            onTap: () =>
                                _showChangeNameDialog(context, authProvider),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: themeProvider.accentColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 16,
                                color: themeProvider.accentColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? 'guest@example.com',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              _getProviderColor(user.authProvider)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getProviderIcon(user.authProvider),
                              size: 14,
                              color: _getProviderColor(user.authProvider),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user.authProvider.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getProviderColor(user.authProvider),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    color: Colors.black.withValues(alpha: 0.1),
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

  Widget _buildAccountSection(BuildContext context) {
    return Consumer2<ThemeProvider, AuthProvider>(
      builder: (context, themeProvider, authProvider, child) {
        // Only show this section if user is logged in
        if (!authProvider.isLoggedIn) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account',
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
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: Colors.red,
                  ),
                ),
                title: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                subtitle: Text(
                  'Sign out from your account',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: themeProvider.secondaryTextColor,
                ),
                onTap: () => _showLogoutConfirmation(context, authProvider),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            title: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: themeProvider.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(
                color: themeProvider.secondaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  
                  // SignOut will set _user = null and call notifyListeners()
                  // MaterialApp in main.dart listens to AuthProvider
                  // and will automatically rebuild with AuthScreen when isLoggedIn becomes false
                  await authProvider.signOut();
                },
                child: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                      '1.2.111',
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
                    color:
                        themeProvider.secondaryTextColor.withValues(alpha: 0.2),
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

  // Helper methods for profile management
  void _showChangeNameDialog(BuildContext context, AuthProvider authProvider) {
    final TextEditingController nameController = TextEditingController(
      text: authProvider.user?.displayName ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            title: Text(
              'Change Display Name',
              style: GoogleFonts.inter(
                color: themeProvider.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: GoogleFonts.inter(
                  color: themeProvider.secondaryTextColor,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: themeProvider.accentColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: themeProvider.accentColor,
                    width: 2,
                  ),
                ),
              ),
              maxLength: 50,
              style: GoogleFonts.inter(
                color: themeProvider.primaryTextColor,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isNotEmpty) {
                    try {
                      await authProvider
                          .updateDisplayName(nameController.text.trim());
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Name updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to update name: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  'Update',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showProfilePhotoOptions(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            title: Text(
              'Profile Photo',
              style: GoogleFonts.inter(
                color: themeProvider.primaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (authProvider.user?.photoURL != null) ...[
                  ListTile(
                    leading: Icon(
                      Icons.remove_circle,
                      color: Colors.red,
                    ),
                    title: Text(
                      'Remove Current Photo',
                      style: GoogleFonts.inter(
                        color: themeProvider.primaryTextColor,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await authProvider.updateProfilePhoto(null);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Profile photo removed'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to remove photo: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                  ),
                ],
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: themeProvider.accentColor,
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: GoogleFonts.inter(
                      color: themeProvider.primaryTextColor,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // TODO: Implement image picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Image gallery coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.camera_alt,
                    color: themeProvider.accentColor,
                  ),
                  title: Text(
                    'Take Photo',
                    style: GoogleFonts.inter(
                      color: themeProvider.primaryTextColor,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    // TODO: Implement camera
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Camera feature coming soon!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    color: themeProvider.secondaryTextColor,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return Colors.red;
      case 'apple':
        return Colors.black;
      case 'facebook':
        return Colors.blue;
      case 'email':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getProviderIcon(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'apple':
        return Icons.apple;
      case 'facebook':
        return Icons.facebook;
      case 'email':
        return Icons.email;
      default:
        return Icons.person;
    }
  }
}
