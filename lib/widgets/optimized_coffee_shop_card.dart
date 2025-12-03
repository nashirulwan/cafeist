import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/coffee_shop.dart';
import '../providers/theme_provider.dart';

class OptimizedCoffeeShopCard extends StatelessWidget {
  final CoffeeShop coffeeShop;
  final VoidCallback? onTap;

  const OptimizedCoffeeShopCard({
    required this.coffeeShop,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: themeProvider.isDarkMode
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeProvider.cardColor.withOpacity(0.8),
                          themeProvider.cardColor.withOpacity(0.6),
                        ],
                      )
                    : null,
                color: themeProvider.isDarkMode ? null : themeProvider.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Optimized Image Widget
                  _buildOptimizedImage(coffeeShop, themeProvider),

                  const SizedBox(width: 16),

                  // Content with optimized layout
                  Expanded(
                    child: _buildContent(coffeeShop, theme, themeProvider),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptimizedImage(CoffeeShop coffeeShop, ThemeProvider themeProvider) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: themeProvider.secondaryTextColor.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: coffeeShop.photos.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: coffeeShop.photos.first,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                // Performance optimizations
                memCacheWidth: 160, // 2x size for retina
                memCacheHeight: 160,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: themeProvider.secondaryTextColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.coffee,
                    color: themeProvider.secondaryTextColor,
                    size: 24,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                // Add fadeIn animation for better UX
                fadeInDuration: const Duration(milliseconds: 300),
              )
            : Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: themeProvider.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.coffee,
                  color: themeProvider.accentColor,
                  size: 24,
                ),
              ),
      ),
    );
  }

  Widget _buildContent(CoffeeShop coffeeShop, ThemeData theme, ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title with optimized text handling
        Text(
          coffeeShop.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: themeProvider.primaryTextColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 4),

        // Description with optimized text handling
        Text(
          coffeeShop.description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: themeProvider.secondaryTextColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Stats Row with optimized layout
        Row(
          children: [
            _buildInfoChip(
              '${coffeeShop.distance.toStringAsFixed(1)} km',
              Icons.location_on,
              Colors.blue,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              coffeeShop.rating.toStringAsFixed(1),
              Icons.star,
              Colors.amber,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              '${coffeeShop.reviewCount}',
              Icons.reviews,
              Colors.green,
            ),
            const SizedBox(width: 8),
            _buildStatusChip(coffeeShop.isOpen),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isOpen ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.access_time : Icons.access_time_filled,
            color: isOpen ? Colors.green : Colors.red,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOpen ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}