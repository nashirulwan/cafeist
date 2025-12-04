import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cafe_tracking_provider.dart';
import '../providers/auth_provider.dart';
import '../models/coffee_shop.dart';
import '../services/cafe_tracking_service.dart';
import '../widgets/cafe_card.dart';
import '../widgets/loading_indicator.dart';

class TrackingDashboardScreen extends StatefulWidget {
  const TrackingDashboardScreen({super.key});

  @override
  State<TrackingDashboardScreen> createState() => _TrackingDashboardScreenState();
}

class _TrackingDashboardScreenState extends State<TrackingDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize tracking data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTracking();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    final trackingProvider = Provider.of<CafeTrackingProvider>(context, listen: false);
    await trackingProvider.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Coffee Journey'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.favorite_border), text: 'Wishlist'),
            Tab(icon: Icon(Icons.check_circle), text: 'Visited'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Search My Cafes'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<CafeTrackingProvider>(
        builder: (context, trackingProvider, child) {
          if (trackingProvider.isLoading) {
            return const LoadingIndicator(message: 'Loading your coffee journey...');
          }

          if (trackingProvider.error != null) {
            return _buildErrorWidget(trackingProvider.error!);
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(trackingProvider),
              _buildWishlistTab(trackingProvider),
              _buildVisitedTab(trackingProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardTab(CafeTrackingProvider trackingProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsOverview(trackingProvider),
          const SizedBox(height: 24),
          _buildQuickActions(trackingProvider),
          const SizedBox(height: 24),
          _buildRecentActivity(trackingProvider),
        ],
      ),
    );
  }

  Widget _buildStatsOverview(CafeTrackingProvider trackingProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Coffee Statistics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Tracked',
                    '${trackingProvider.totalTracked}',
                    Icons.coffee,
                    Colors.brown,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Wishlist',
                    '${trackingProvider.wishlistCount}',
                    Icons.favorite_border,
                    Colors.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Visited',
                    '${trackingProvider.visitedCount}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Avg Rating',
                    trackingProvider.averagePersonalRating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(CafeTrackingProvider trackingProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildActionButton(
                  'Add to Wishlist',
                  Icons.add_circle_outline,
                  Colors.pink,
                  () => _showAddToWishlistDialog(),
                ),
                _buildActionButton(
                  'Mark as Visited',
                  Icons.check_circle_outline,
                  Colors.green,
                  () => _showMarkVisitedDialog(),
                ),
                _buildActionButton(
                  'Search Cafes',
                  Icons.search,
                  Colors.blue,
                  () => _showSearchDialog(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(title),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha:0.1),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha:0.3)),
      ),
    );
  }

  Widget _buildRecentActivity(CafeTrackingProvider trackingProvider) {
    final recentCafes = [...trackingProvider.visitedCafes, ...trackingProvider.wishlist]
        .take(5)
        .toList();

    if (recentCafes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.coffee_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Start Your Coffee Journey',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Add cafes to your wishlist or mark them as visited to see them here.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...recentCafes.map((cafe) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildRecentCafeItem(cafe),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCafeItem(CoffeeShop cafe) {
    final isVisited = cafe.trackingStatus == CafeTrackingStatus.visited;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isVisited ? Colors.green : Colors.pink,
        child: Icon(
          isVisited ? Icons.check_circle : Icons.favorite_border,
          color: Colors.white,
        ),
      ),
      title: Text(cafe.name),
      subtitle: Text(cafe.address),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cafe.rating > 0) ...[
            Icon(Icons.star, color: Colors.amber, size: 16),
            Text(cafe.rating.toStringAsFixed(1)),
          ],
        ],
      ),
      onTap: () => _showCafeDetails(cafe),
    );
  }

  Widget _buildWishlistTab(CafeTrackingProvider trackingProvider) {
    if (trackingProvider.wishlist.isEmpty) {
      return _buildEmptyState(
        'Your Wishlist is Empty',
        'Add cafes you want to visit here!',
        Icons.favorite_border,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trackingProvider.wishlist.length,
      itemBuilder: (context, index) {
        final cafe = trackingProvider.wishlist[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CafeCard(
            cafe: cafe,
            onTap: () => _showCafeDetails(cafe),
            onTrack: () => _markAsVisited(cafe),
            onRemove: () => _removeFromTracking(cafe.id),
          ),
        );
      },
    );
  }

  Widget _buildVisitedTab(CafeTrackingProvider trackingProvider) {
    if (trackingProvider.visitedCafes.isEmpty) {
      return _buildEmptyState(
        'No Visited Cafes Yet',
        'Mark cafes as visited after you try them!',
        Icons.check_circle_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trackingProvider.visitedCafes.length,
      itemBuilder: (context, index) {
        final cafe = trackingProvider.visitedCafes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CafeCard(
            cafe: cafe,
            onTap: () => _showCafeDetails(cafe),
            onTrack: null, // Already visited
            onRemove: () => _removeFromTracking(cafe.id),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
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
            ElevatedButton.icon(
              onPressed: () => _showAddToWishlistDialog(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add Your First Cafe'),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog methods
  void _showAddToWishlistDialog() {
    // Implementation would show a dialog to search and add cafes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add to wishlist dialog coming soon!')),
    );
  }

  void _showMarkVisitedDialog() {
    // Implementation would show a dialog to mark cafes as visited
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mark visited dialog coming soon!')),
    );
  }

  void _showSearchDialog() {
    showSearch(
      context: context,
      delegate: CafeSearchDelegate(),
    );
  }

  void _showCafeDetails(CoffeeShop cafe) {
    // Implementation would show cafe details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Details for ${cafe.name} coming soon!')),
    );
  }

  Future<void> _markAsVisited(CoffeeShop cafe) async {
    // Create basic visit data - this could be expanded with a proper dialog
    final visitData = VisitData(
      personalRating: null,
      privateReview: null,
      visitDates: [DateTime.now()],
    );

    final trackingProvider = Provider.of<CafeTrackingProvider>(context, listen: false);
    await trackingProvider.markAsVisited(cafe, visitData);
  }

  Future<void> _removeFromTracking(String cafeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Cafe'),
        content: const Text('Are you sure you want to remove this cafe from your tracking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final trackingProvider = Provider.of<CafeTrackingProvider>(context, listen: false);
      await trackingProvider.removeFromTracking(cafeId);
    }
  }

  Future<void> _refreshData() async {
    final trackingProvider = Provider.of<CafeTrackingProvider>(context, listen: false);
    await trackingProvider.refresh();
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'export':
        await _exportUserData();
        break;
      case 'search':
        _showSearchDialog();
        break;
    }
  }

  Future<void> _exportUserData() async {
    final trackingProvider = Provider.of<CafeTrackingProvider>(context, listen: false);
    final userData = await trackingProvider.exportUserData();

    if (userData != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data exported successfully!')),
      );
    }
  }
}

class CafeSearchDelegate extends SearchDelegate<CoffeeShop> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}