import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/coffee_shop_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/location_discovery_provider.dart';
import '../models/coffee_shop.dart';
import '../widgets/glass_container.dart';
import '../widgets/location_header.dart';
import '../widgets/optimized_coffee_shop_card.dart';
import 'coffee_shop_detail_screen.dart';
import '../widgets/theme_switcher.dart';

// Simple Chip Widget
class SimpleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const SimpleChip({
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
                    theme.primaryColor.withValues(alpha: 0.8),
                    theme.primaryColor.withValues(alpha: 0.6),
                  ],
                )
              : null,
          color: selected ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.primaryColor.withValues(alpha: 0.3),
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

// Simple Coffee Card Widget
class SimpleCoffeeCard extends StatelessWidget {
  final String name;
  final String description;
  final String distance;
  final String rating;
  final String? imageUrl;
  final bool isOpen;
  final VoidCallback? onTap;

  const SimpleCoffeeCard({
    super.key,
    required this.name,
    required this.description,
    required this.distance,
    required this.rating,
    this.imageUrl,
    this.isOpen = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.withValues(alpha: 0.3),
                          child: const Icon(Icons.coffee, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.withValues(alpha: 0.3),
                          child: const Icon(Icons.error, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.primaryColor.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.coffee, color: Colors.white),
                    ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Distance and Rating
                  Row(
                    children: [
                      // Distance
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.blue, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              distance,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),

                      // Status
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isOpen ? Colors.green : Colors.red,
                          ),
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
  }
}

// ModernChip Widget
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
                    theme.primaryColor.withValues(alpha: 0.8),
                    theme.primaryColor.withValues(alpha: 0.6),
                  ],
                )
              : null,
          color: selected ? null : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : theme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
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

// CoffeeShopCard Widget
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
    this.isOpen = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              child: imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.withValues(alpha: 0.3),
                          child: const Icon(Icons.coffee, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.grey.withValues(alpha: 0.3),
                          child: const Icon(Icons.error, color: Colors.grey),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.primaryColor.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.coffee, color: Colors.white),
                    ),
            ),

            const SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Distance
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          distance,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Rating
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(width: 8),

                      // Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOpen
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isOpen ? 'Open' : 'Closed',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isOpen ? Colors.green : Colors.red,
                          ),
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
  }
}

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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Text(
                      'cafeist.',
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
                    district = parts[0].trim().isNotEmpty
                        ? parts[0].trim()
                        : 'Kecamatan';
                    city = parts.length > 1 && parts[1].trim().isNotEmpty
                        ? parts[1].trim()
                        : 'Kota';
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                                  color: themeProvider.secondaryTextColor
                                      .withValues(alpha: 0.6),
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: themeProvider.primaryTextColor,
                              ),
                              onChanged: (value) {
                                // Debounced search to avoid too many API calls
                                Future.delayed(
                                    const Duration(milliseconds: 500), () {
                                  if (_searchController.text == value) {
                                    // Check if still the same query
                                    context
                                        .read<CoffeeShopProvider>()
                                        .searchCoffeeShops(value);
                                  }
                                });
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                context
                                    .read<CoffeeShopProvider>()
                                    .searchCoffeeShops('');
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
                                  color: themeProvider.accentColor
                                      .withValues(alpha: 0.5),
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
                                    color: themeProvider.secondaryTextColor
                                        .withValues(alpha: 0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (provider.error != null &&
                                    provider.error!.contains('offline')) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Using local coffee shop database',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: themeProvider.secondaryTextColor
                                          .withValues(alpha: 0.5),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                GlassContainer(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
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
                                          color: themeProvider.accentColor
                                              .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No cafes found nearby',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            color:
                                                themeProvider.primaryTextColor,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Try refreshing or search terms',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeProvider
                                                .secondaryTextColor
                                                .withValues(alpha: 0.7),
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
                                final coffeeShop =
                                    provider.nearbyCoffeeShops[index];
                                return OptimizedCoffeeShopCard(
                                  coffeeShop: coffeeShop,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            CoffeeShopDetailScreen(
                                          coffeeShop: coffeeShop,
                                        ),
                                        transitionDuration:
                                            const Duration(milliseconds: 300),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
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

  void _showLocationSelector(BuildContext context) {
    final List<Map<String, dynamic>> jakartaDistricts = [
      {'name': 'Jakarta Pusat', 'lat': -6.1944, 'lng': 106.8229},
      {'name': 'Jakarta Utara', 'lat': -6.1384, 'lng': 106.8759},
      {'name': 'Jakarta Barat', 'lat': -6.1755, 'lng': 106.7952},
      {'name': 'Jakarta Selatan', 'lat': -6.2615, 'lng': 106.8106},
      {'name': 'Jakarta Timur', 'lat': -6.2485, 'lng': 106.8755},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
            const SizedBox(height: 8),
            Text(
              'Choose a district to find coffee shops nearby',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: jakartaDistricts.length,
                itemBuilder: (context, index) {
                  final district = jakartaDistricts[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          Navigator.pop(context);

                          // Update location provider with selected district
                          final locationProvider =
                              Provider.of<LocationDiscoveryProvider>(
                            context,
                            listen: false,
                          );

                          await locationProvider.updateLocation(
                            district['lat'],
                            district['lng'],
                          );

                          // Refresh coffee shops with new location
                          final coffeeProvider =
                              Provider.of<CoffeeShopProvider>(
                            context,
                            listen: false,
                          );

                          await coffeeProvider.refreshCoffeeShops();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Location updated to ${district['name']}'),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      district['name'],
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Tap to search coffee shops here',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      // Use current GPS location
                      final locationProvider =
                          Provider.of<LocationDiscoveryProvider>(
                        context,
                        listen: false,
                      );

                      try {
                        await locationProvider.refreshLocation();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Using your current location'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to get location: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.gps_fixed,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text('Use GPS Location'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
