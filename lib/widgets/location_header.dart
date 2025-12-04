import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import 'glass_container.dart';

class LocationHeader extends StatelessWidget {
  final String district;
  final String city;
  final String region;
  final VoidCallback? onChangeLocation;

  const LocationHeader({
    super.key,
    required this.district,
    required this.city,
    required this.region,
    this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GlassContainer(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Location Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.accentColor.withValues(alpha:0.2),
                      themeProvider.accentColor.withValues(alpha:0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: themeProvider.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

          // Location Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  const SizedBox(height: 2),
                Text(
                  '$district, $city',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.primaryTextColor,
                  ),
                ),
                ],
            ),
          ),

          // Change Location Button
          if (onChangeLocation != null)
            GestureDetector(
              onTap: onChangeLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      themeProvider.accentColor.withValues(alpha:0.8),
                      themeProvider.accentColor.withValues(alpha:0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      );
    });
  }
}

class CompactLocationHeader extends StatelessWidget {
  final String district;
  final String city;
  final VoidCallback? onTap;

  const CompactLocationHeader({
    super.key,
    required this.district,
    required this.city,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: theme.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$district, $city',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: theme.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class LocationChip extends StatelessWidget {
  final String location;
  final bool selected;
  final VoidCallback? onTap;

  const LocationChip({
    super.key,
    required this.location,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withValues(alpha:0.8),
                    theme.primaryColor.withValues(alpha:0.6),
                  ],
                )
              : null,
          color: selected ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.primaryColor.withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: Text(
          location,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : theme.primaryColor,
          ),
        ),
      ),
    );
  }
}