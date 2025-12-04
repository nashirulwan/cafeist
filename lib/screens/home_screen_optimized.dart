import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/coffee_shop_provider.dart';
import '../providers/theme_provider.dart';
import '../models/coffee_shop.dart';
import '../widgets/glass_container.dart';
import '../widgets/location_header.dart';
import '../widgets/optimized_coffee_shop_card.dart';
import 'coffee_shop_detail_screen.dart';
import '../widgets/theme_switcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Only initialize coffee shops if it's the first time loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CoffeeShopProvider>();
      // Only update if we don't have any data yet or location has changed significantly
    if (provider.nearbyCoffeeShops.isEmpty) {
        provider.updateNearbyCoffeeShops();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      'Coffee Finder',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.headlineLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),

              // Location Header (no change button)
              Consumer<CoffeeShopProvider>(
                builder: (context, provider, child) {
                  // Parse location properly to show district and city
                  String district = 'Kecamatan';
                  String city = 'Kota';

                  if (provider.userLocation.contains(',')) {
                    final parts = provider.userLocation.split(',');
                    district = parts[0].trim().isNotEmpty ? parts[0].trim() : 'Kecamatan';
                    city = parts.length > 1 && parts[1].trim().isNotEmpty ? parts[1].trim() : 'Kota';
                  } else if (provider.userLocation.isNotEmpty &&
                             provider.userLocation != 'Getting location...' &&
                             provider.userLocation != 'Unknown Location') {
                    district = provider.userLocation;
                    city = 'Indonesia';
                  }

                  return LocationHeader(
                    district: district,
                    city: city,
                    region: provider.userRegion,
                    onChangeLocation: null, // Remove change location button
                  );
                },
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_outlined,
                            color: themeProvider.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search cafes, coffee, or vibes...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: themeProvider.secondaryTextColor.withValues(alpha:0.6),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: themeProvider.primaryTextColor,
                              ),
                              onChanged: (value) {
                                // Debounced search to avoid too many API calls
                                Future.delayed(const Duration(milliseconds: 500), () {
                                  if (_searchController.text == value) {  // Check if still the same query
                                    context.read<CoffeeShopProvider>().searchCoffeeShops(value);
                                  }
                                });
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                context.read<CoffeeShopProvider>().searchCoffeeShops('');
                              },
                              child: Icon(
                                Icons.close,
                                color: themeProvider.accentColor,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Consumer<CoffeeShopProvider>(
                  builder: (context, provider, child) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ModernChip(
                            label: 'All',
                            icon: Icons.coffee,
                            selected: provider.activeFilter == 'all',
                            onTap: () {
                              provider.setActiveFilter('all');
                            },
                          ),
                          const SizedBox(width: 8),
                          ModernChip(
                            label: 'Nearby',
                            icon: Icons.near_me,
                            selected: provider.activeFilter == 'nearby',
                            onTap: () {
                              provider.setActiveFilter('nearby');
                            },
                          ),
                          const SizedBox(width: 8),
                          ModernChip(
                            label: 'Top Rated',
                            icon: Icons.star,
                            selected: provider.activeFilter == 'topRated',
                            onTap: () {
                              provider.setActiveFilter('topRated');
                            },
                          ),
                          const SizedBox(width: 8),
                          ModernChip(
                            label: 'Top Review',
                            icon: Icons.reviews,
                            selected: provider.activeFilter == 'topReview',
                            onTap: () {
                              provider.setActiveFilter('topReview');
                            },
                          ),
                          const SizedBox(width: 8),
                          ModernChip(
                            label: 'For You',
                            icon: Icons.thumb_up,
                            selected: provider.activeFilter == 'recommended',
                            onTap: () async {
                              await provider.applyRecommendationFilter();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Main Content
              Expanded(
                child: Consumer<CoffeeShopProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading nearby coffee shops...'),
                          ],
                        ),
                      );
                    }

                    // Error State
                    if (provider.error != null) {
                      return Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: themeProvider.accentColor.withValues(alpha:0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Oops! Something went wrong',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: themeProvider.primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  provider.error ?? 'No coffee shops available',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: themeProvider.secondaryTextColor.withValues(alpha:0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (provider.error != null && provider.error!.contains('offline')) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Using local coffee shop database',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: themeProvider.secondaryTextColor.withValues(alpha:0.5),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                GlassContainer(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  borderRadius: BorderRadius.circular(16),
                                  color: themeProvider.accentColor,
                                  opacity: 0.9,
                                  child: GestureDetector(
                                    onTap: () {
                                      provider.updateNearbyCoffeeShops();
                                    },
                                    child: Text(
                                      'Try Again',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }

                    // Main Content
                    return RefreshIndicator(
                      onRefresh: () async {
                        await provider.updateNearbyCoffeeShops();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),

                            // Coffee Shop List with optimized performance
                            if (provider.nearbyCoffeeShops.isEmpty)
                              Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(32.0),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.coffee_outlined,
                                            size: 64,
                                            color: themeProvider.accentColor.withValues(alpha:0.5),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No cafes found nearby',
                                            style: theme.textTheme.titleLarge?.copyWith(
                                              color: themeProvider.primaryTextColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Try refreshing or search terms',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: themeProvider.secondaryTextColor.withValues(alpha:0.7),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(bottom: 100),
                                itemCount: provider.nearbyCoffeeShops.length,
                                // Performance optimization: set item extent for smooth scrolling
                                itemExtent: 120.0,
                                // Performance optimization: cache extent for better performance
                                cacheExtent: 500.0,
                                itemBuilder: (context, index) {
                                  final coffeeShop = provider.nearbyCoffeeShops[index];
                                  return OptimizedCoffeeShopCard(
                                    coffeeShop: coffeeShop,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              CoffeeShopDetailScreen(
                                                coffeeShop: coffeeShop,
                                              ),
                                          transitionDuration: const Duration(milliseconds: 300),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            return SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(1.0, 0.0),
                                                end: Offset.zero,
                                              ).animate(CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              )),
                                              child: child,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Consumer<CoffeeShopProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            onPressed: () {
              // Refresh cafe data
              provider.updateNearbyCoffeeShops();
            },
            child: provider.isLoading
                ? Container(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
          );
        },
      ),
    );
  }
}

// ModernChip Widget - Simplified for better performance
class ModernChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const ModernChip({
    super.key,
    required this.label,
    required this.icon,
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : theme.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : theme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}