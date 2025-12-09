import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_discovery_provider.dart';
import '../providers/auth_provider.dart';
import '../models/coffee_shop.dart';
import '../widgets/cafe_card.dart';
import '../widgets/loading_indicator.dart';

class CafeDiscoveryScreen extends StatefulWidget {
  const CafeDiscoveryScreen({super.key});

  @override
  State<CafeDiscoveryScreen> createState() => _CafeDiscoveryScreenState();
}

class _CafeDiscoveryScreenState extends State<CafeDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedSortOption = 'smart';
  double? _minRating;
  bool? _openNow;
  final List<String> _selectedFeatures = [];

  final List<Map<String, dynamic>> _sortOptions = [
    {'value': 'smart', 'label': 'Smart Sort', 'icon': Icons.auto_awesome},
    {'value': 'rating', 'label': 'Top Rated', 'icon': Icons.star},
    {'value': 'distance', 'label': 'Nearest', 'icon': Icons.near_me},
    {'value': 'reviews', 'label': 'Most Reviews', 'icon': Icons.chat},
  ];

  final List<Map<String, dynamic>> _cafeFeatures = [
    {'value': 'wifi', 'label': 'WiFi', 'icon': Icons.wifi},
    {'value': 'power', 'label': 'Power Outlets', 'icon': Icons.power},
    {'value': 'quiet', 'label': 'Quiet Environment', 'icon': Icons.volume_off},
    {'value': 'workspace', 'label': 'Workspace', 'icon': Icons.laptop},
    {'value': 'outdoor', 'label': 'Outdoor Seating', 'icon': Icons.deck},
    {'value': 'parking', 'label': 'Parking', 'icon': Icons.local_parking},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize discovery provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDiscovery();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Cafes'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.near_me), text: 'Nearby'),
            Tab(icon: Icon(Icons.trending_up), text: 'Trending'),
            Tab(icon: Icon(Icons.explore), text: 'Explore'),
            Tab(icon: Icon(Icons.person), text: 'For You'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDiscovery,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Consumer<LocationDiscoveryProvider>(
        builder: (context, discoveryProvider, child) {
          if (discoveryProvider.isLoading &&
              discoveryProvider.allDiscoveredCafes.isEmpty) {
            return const CoffeeLoadingIndicator(
              message: 'Discovering amazing coffee shops near you...',
            );
          }

          if (discoveryProvider.error != null) {
            return _buildErrorWidget(discoveryProvider.error!);
          }

          return Column(
            children: [
              // Search bar
              Container(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search coffee shops...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (query) => _searchCafes(query),
                ),
              ),

              // Sort and filter pills
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Sort option
                    _buildSortPill(discoveryProvider),
                    const SizedBox(width: 8),
                    // Rating filter
                    if (_minRating != null) _buildFilterPill(
                      '★ $_minRating+',
                      () => _clearRatingFilter(),
                    ),
                    // Open now filter
                    if (_openNow == true) _buildFilterPill(
                      'Open Now',
                      () => _clearOpenNowFilter(),
                    ),
                    // Feature filters
                    ..._selectedFeatures.map((feature) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterPill(
                        feature,
                        () => _removeFeatureFilter(feature),
                      ),
                    )),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNearbyTab(discoveryProvider),
                    _buildTrendingTab(discoveryProvider),
                    _buildExploreTab(discoveryProvider),
                    _buildPersonalizedTab(discoveryProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAdvancedSearch,
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildSortPill(LocationDiscoveryProvider discoveryProvider) {
    return PopupMenuButton<String>(
      initialValue: _selectedSortOption,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _sortOptions.firstWhere((opt) => opt['value'] == _selectedSortOption)['icon'],
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              _sortOptions.firstWhere((opt) => opt['value'] == _selectedSortOption)['label'],
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
      onSelected: (value) {
        setState(() {
          _selectedSortOption = value;
          _applyFilters();
        });
      },
      itemBuilder: (context) {
        return _sortOptions.map((option) {
          return PopupMenuItem<String>(
            value: option['value'],
            child: Row(
              children: [
                Icon(option['icon'], size: 20),
                const SizedBox(width: 12),
                Text(option['label']),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildFilterPill(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.orange[700],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyTab(LocationDiscoveryProvider discoveryProvider) {
    if (!discoveryProvider.isLocationEnabled) {
      return _buildLocationPermissionWidget();
    }

    if (discoveryProvider.nearbyCafes.isEmpty) {
      return _buildEmptyState(
        'No cafes found nearby',
        'Try expanding your search radius or check your location settings.',
        Icons.location_off,
        () => discoveryProvider.retry(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: discoveryProvider.nearbyCafes.length,
      itemBuilder: (context, index) {
        final cafe = discoveryProvider.nearbyCafes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CafeCard(
            cafe: cafe,
            onTap: () => _showCafeDetails(cafe),
          ),
        );
      },
    );
  }

  Widget _buildTrendingTab(LocationDiscoveryProvider discoveryProvider) {
    if (discoveryProvider.trendingCafes.isEmpty) {
      return _buildEmptyState(
        'No trending cafes found',
        'Check back later for popular coffee shops in your area.',
        Icons.trending_down,
        () => discoveryProvider.getTrendingCafes(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: discoveryProvider.trendingCafes.length,
      itemBuilder: (context, index) {
        final cafe = discoveryProvider.trendingCafes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CafeCard(
            cafe: cafe,
            onTap: () => _showCafeDetails(cafe),
          ),
        );
      },
    );
  }

  Widget _buildExploreTab(LocationDiscoveryProvider discoveryProvider) {
    if (discoveryProvider.nearbyCities.isEmpty) {
      return _buildEmptyState(
        'No regions available',
        'Enable location services to see cafes in your area.',
        Icons.explore_off,
        () => discoveryProvider.retry(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Popular regions
        Text(
          'Popular Regions',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: discoveryProvider.nearbyCities.take(6).map((city) {
            return ActionChip(
              label: Text(city),
              onPressed: () => _discoverInRegion(city),
              avatar: const Icon(Icons.location_city, size: 18),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Regional cafes
        if (discoveryProvider.regionalCafes.isNotEmpty) ...[
          Text(
            'Cafes in Your Area',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...discoveryProvider.regionalCafes.map((cafe) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CafeCard(
              cafe: cafe,
              onTap: () => _showCafeDetails(cafe),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildPersonalizedTab(LocationDiscoveryProvider discoveryProvider) {
    final authProvider = context.read<AuthProvider>();

    if (!authProvider.isLoggedIn) {
      return _buildLoginPrompt();
    }

    if (discoveryProvider.personalizedRecommendations.isEmpty) {
      return _buildEmptyState(
        'No recommendations yet',
        'Start by adding cafes to your wishlist and marking them as visited.',
        Icons.lightbulb_outline,
        () => discoveryProvider.loadPersonalizedRecommendations(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: discoveryProvider.personalizedRecommendations.length,
      itemBuilder: (context, index) {
        final cafe = discoveryProvider.personalizedRecommendations[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CafeCard(
            cafe: cafe,
            onTap: () => _showCafeDetails(cafe),
          ),
        );
      },
    );
  }

  Widget _buildLocationPermissionWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Location Access Required',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Enable location services to discover coffee shops near you.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestLocationPermission,
              icon: const Icon(Icons.location_on),
              label: const Text('Enable Location'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sign In for Personalized Recommendations',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Get personalized cafe recommendations based on your preferences.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/auth');
              },
              icon: const Icon(Icons.login),
              label: const Text('Sign In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryDiscovery,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _initializeDiscovery() {
    final discoveryProvider = context.read<LocationDiscoveryProvider>();
    discoveryProvider.initialize();
  }

  void _refreshDiscovery() {
    final discoveryProvider = context.read<LocationDiscoveryProvider>();
    discoveryProvider.refreshLocation();
  }

  void _retryDiscovery() {
    final discoveryProvider = context.read<LocationDiscoveryProvider>();
    discoveryProvider.retry();
  }

  void _searchCafes(String query) {
    final discoveryProvider = context.read<LocationDiscoveryProvider>();

    // Determine sort by based on selected option
    String sortBy;
    switch (_selectedSortOption) {
      case 'rating':
        sortBy = 'rating';
        break;
      case 'distance':
        sortBy = 'distance';
        break;
      case 'reviews':
        sortBy = 'reviews';
        break;
      default:
        sortBy = 'smart';
    }

    discoveryProvider.searchCafesWithFilters(
      query: query,
      minRating: _minRating,
      openNow: _openNow,
      sortBy: sortBy,
    );
  }

  void _applyFilters() {
    _searchCafes(_searchController.text);
  }

  void _clearRatingFilter() {
    setState(() {
      _minRating = null;
    });
    _applyFilters();
  }

  void _clearOpenNowFilter() {
    setState(() {
      _openNow = null;
    });
    _applyFilters();
  }

  void _removeFeatureFilter(String feature) {
    setState(() {
      _selectedFeatures.remove(feature);
    });
    _applyFilters();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Cafes'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating filter
                Text(
                  'Minimum Rating',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _minRating ?? 0.0,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  label: (_minRating ?? 0.0).toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _minRating = value == 0.0 ? null : value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Open now filter
                SwitchListTile(
                  title: const Text('Open Now'),
                  value: _openNow ?? false,
                  onChanged: (value) {
                    setState(() {
                      _openNow = value ? value : null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Features filter
                Text(
                  'Features',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _cafeFeatures.map((feature) {
                    final isSelected = _selectedFeatures.contains(feature['value']);
                    return FilterChip(
                      label: Text(feature['label']),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFeatures.add(feature['value']);
                          } else {
                            _selectedFeatures.remove(feature['value']);
                          }
                        });
                      },
                      avatar: Icon(feature['icon'], size: 18),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _minRating = null;
                _openNow = null;
                _selectedFeatures.clear();
              });
            },
            child: const Text('Clear All'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _applyFilters();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAdvancedSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Advanced Search'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search term',
                hintText: 'Coffee, WiFi, quiet space...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Location (optional)',
                hintText: 'Jakarta, Surabaya, Bandung...',
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Implement advanced search logic
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _discoverInRegion(String region) {
    final discoveryProvider = context.read<LocationDiscoveryProvider>();
    discoveryProvider.discoverByRegion(region);

    // Switch to explore tab
    _tabController.animateTo(2);
  }

  void _requestLocationPermission() {
    final discoveryProvider = context.read<LocationDiscoveryProvider>();
    discoveryProvider.retry();
  }

  void _showCafeDetails(CoffeeShop cafe) {
    // Navigate to cafe details screen
    Navigator.pushNamed(
      context,
      '/cafe-details',
      arguments: cafe,
    );
  }
}