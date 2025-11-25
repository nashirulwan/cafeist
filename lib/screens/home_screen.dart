import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/coffee_shop_provider.dart';
import '../providers/theme_provider.dart';
import '../models/coffee_shop.dart';
import '../widgets/glass_container.dart';
import '../widgets/location_header.dart';
import 'coffee_shop_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDistrict = 'Sukun';
  String _selectedCity = 'Malang';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Header - Theme switcher moved to AppBar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Coffee Finder',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.headlineLarge?.color,
                  ),
                ),
              ),

              // Location Header
              LocationHeader(
                district: _selectedDistrict,
                city: _selectedCity,
                region: 'East Java, Indonesia',
                onChangeLocation: () {
                  _showLocationSelector(context);
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
                                  color: themeProvider.secondaryTextColor.withOpacity(0.6),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: themeProvider.primaryTextColor,
                              ),
                              onChanged: (value) {
                                context.read<CoffeeShopProvider>().searchCoffeeShops(value);
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ModernChip(
                        label: 'All Cafes',
                        icon: Icons.coffee,
                        selected: true,
                        onTap: () {
                          // TODO: Filter by all
                        },
                      ),
                      const SizedBox(width: 8),
                      ModernChip(
                        label: 'Near Me',
                        icon: Icons.near_me,
                        onTap: () {
                          // TODO: Filter by distance
                        },
                      ),
                      const SizedBox(width: 8),
                      ModernChip(
                        label: 'Top Rated',
                        icon: Icons.star,
                        onTap: () {
                          // TODO: Filter by rating
                        },
                      ),
                      const SizedBox(width: 8),
                      ModernChip(
                        label: 'Open Now',
                        icon: Icons.access_time,
                        onTap: () {
                          // TODO: Filter by open status
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Main Content
              Expanded(
                child: Consumer<CoffeeShopProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
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
                                  color: themeProvider.accentColor.withOpacity(0.5),
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
                                  provider.error!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: themeProvider.secondaryTextColor.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
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
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Today's Spotlight Section
                          if (provider.nearbyCoffeeShops.isNotEmpty) ...[
                            // Section Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Consumer<ThemeProvider>(
                                builder: (context, themeProvider, child) {
                                  return Row(
                                    children: [
                                      Text(
                                        '🎯 Today\'s Spotlight',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: themeProvider.primaryTextColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.local_fire_department,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Featured Coffee Shop Card
                            CoffeeShopCard(
                              name: provider.nearbyCoffeeShops.first.name,
                              description: provider.nearbyCoffeeShops.first.description,
                              distance: '${provider.nearbyCoffeeShops.first.distance.toStringAsFixed(1)} km',
                              rating: '${provider.nearbyCoffeeShops.first.rating}',
                              imageUrl: provider.nearbyCoffeeShops.first.photos.isNotEmpty
                                  ? provider.nearbyCoffeeShops.first.photos.first
                                  : null,
                              isOpen: provider.nearbyCoffeeShops.first.isOpen,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CoffeeShopDetailScreen(
                                      coffeeShop: provider.nearbyCoffeeShops.first,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Nearby Cafes Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Consumer<ThemeProvider>(
                              builder: (context, themeProvider, child) {
                                return Row(
                                  children: [
                                    Text(
                                      '☕ Nearby Cafes',
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: themeProvider.primaryTextColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: themeProvider.accentColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${provider.nearbyCoffeeShops.length} places',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: themeProvider.accentColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Coffee Shop List
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
                                          color: themeProvider.accentColor.withOpacity(0.5),
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
                                          'Try changing your location or search terms',
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: themeProvider.secondaryTextColor.withOpacity(0.7),
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
                              itemBuilder: (context, index) {
                                final coffeeShop = provider.nearbyCoffeeShops[index];
                                return CoffeeShopCard(
                                  name: coffeeShop.name,
                                  description: coffeeShop.description,
                                  distance: '${coffeeShop.distance.toStringAsFixed(1)} km',
                                  rating: '${coffeeShop.rating}',
                                  imageUrl: coffeeShop.photos.isNotEmpty
                                      ? coffeeShop.photos.first
                                      : null,
                                  isOpen: coffeeShop.isOpen,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CoffeeShopDetailScreen(
                                          coffeeShop: coffeeShop,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLocationSelector(BuildContext context) {
    // TODO: Implement location selector
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select District',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Add district selection
            Text(
              'District selection coming soon...',
              style: GoogleFonts.inter(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}