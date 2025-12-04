import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Color? color;
  final double blur;
  final double opacity;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.boxShadow,
    this.color,
    this.blur = 10.0,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: border ?? Border.all(
          color: (color ?? theme.primaryColor).withValues(alpha:0.2),
          width: 1,
        ),
        boxShadow: boxShadow ?? [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha:0.3)
                : Colors.black.withValues(alpha:0.1),
            blurRadius: blur,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            color: (color ?? (isDark ? Colors.white : Colors.black))
                .withValues(alpha:opacity * 0.3), // Reduce opacity significantly
            border: Border.all(
              color: theme.primaryColor.withValues(alpha:0.1),
              width: 1,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: margin,
      elevation: elevation,
      shadowColor: theme.primaryColor.withValues(alpha:0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: theme.cardColor,
            border: Border.all(
              color: theme.primaryColor.withValues(alpha:0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;

  const GradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin,
    this.end,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin ?? Alignment.topLeft,
          end: end ?? Alignment.bottomRight,
          colors: colors ?? (isDark
              ? [
                  theme.scaffoldBackgroundColor,
                  theme.scaffoldBackgroundColor.withValues(alpha:0.8),
                ]
              : [
                  theme.scaffoldBackgroundColor,
                  Colors.white.withValues(alpha:0.9),
                ]),
        ),
      ),
      child: child,
    );
  }
}

class ModernChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;
  final Color? selectedColor;
  final Color? backgroundColor;

  const ModernChip({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    this.selectedColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: onTap,
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? (selectedColor ?? themeProvider.accentColor)
                : (backgroundColor ?? Colors.transparent),
            opacity: selected ? 0.9 : 0.7,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? Colors.white
                        : themeProvider.primaryTextColor,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? Colors.white
                        : themeProvider.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CoffeeShopCard extends StatelessWidget {
  final String name;
  final String description;
  final String distance;
  final String rating;
  final String? imageUrl;
  final bool isOpen;
  final VoidCallback? onTap;

  const CoffeeShopCard({
    super.key,
    required this.name,
    required this.description,
    required this.distance,
    required this.rating,
    this.imageUrl,
    this.isOpen = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GlassCard(
          onTap: onTap,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Coffee Shop Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: themeProvider.accentColor.withValues(alpha:0.1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.coffee,
                                size: 32,
                                color: themeProvider.accentColor,
                              );
                            },
                          )
                        : Icon(
                            Icons.coffee,
                            size: 32,
                            color: themeProvider.accentColor,
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Coffee Shop Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: themeProvider.primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? Colors.green.withValues(alpha:0.2)
                                  : Colors.red.withValues(alpha:0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOpen ? 'Open' : 'Closed',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOpen
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: themeProvider.secondaryTextColor.withValues(alpha:0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: themeProvider.primaryTextColor,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: themeProvider.accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: themeProvider.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}