import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return PopupMenuButton<CoffeeTheme>(
          icon: Icon(
            Icons.palette_outlined,
            color: Theme.of(context).iconTheme.color,
          ),
          tooltip: 'Switch Theme',
          onSelected: (theme) {
            themeProvider.setTheme(theme);
          },
          itemBuilder: (context) => CoffeeTheme.values.map((theme) {
            return PopupMenuItem<CoffeeTheme>(
              value: theme,
              child: Row(
                children: [
                  _buildThemeIcon(theme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getThemeDisplayName(theme),
                          style: TextStyle(
                            fontWeight: themeProvider.currentTheme == theme
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        Text(
                          _getThemeDescription(theme),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (themeProvider.currentTheme == theme)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildThemeIcon(CoffeeTheme theme) {
    switch (theme) {
      case CoffeeTheme.morning:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF8DC), Color(0xFFFFF4E6)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.wb_sunny,
            color: Color(0xFFD2691E),
            size: 18,
          ),
        );
      case CoffeeTheme.evening:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.nightlight_round,
            color: Color(0xFF6B46C1),
            size: 18,
          ),
        );
      case CoffeeTheme.sunset:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFCE7F3), Color(0xFFFECACA)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.wb_twilight,
            color: Color(0xFFEC4899),
            size: 18,
          ),
        );
      case CoffeeTheme.midnight:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.dark_mode,
            color: Color(0xFF10B981),
            size: 18,
          ),
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
        return 'Minimalist & pro';
    }
  }
}

class QuickThemeButton extends StatelessWidget {
  const QuickThemeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () => themeProvider.nextTheme(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            child: Icon(
              _getThemeIcon(themeProvider.currentTheme),
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  IconData _getThemeIcon(CoffeeTheme theme) {
    switch (theme) {
      case CoffeeTheme.morning:
        return Icons.wb_sunny;
      case CoffeeTheme.evening:
        return Icons.nightlight_round;
      case CoffeeTheme.sunset:
        return Icons.wb_twilight;
      case CoffeeTheme.midnight:
        return Icons.dark_mode;
    }
  }
}