import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/coffee_shop_provider.dart';
import '../providers/theme_provider.dart';
import '../models/coffee_shop.dart';
import '../widgets/add_visit_dialog.dart';
import 'coffee_shop_detail_screen.dart';
import 'home_screen.dart';

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My List'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'name',
                child: Text('Sort by Name'),
              ),
              const PopupMenuItem(
                value: 'rating',
                child: Text('Sort by Rating'),
              ),
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  controller: _tabController,
                  labelColor: themeProvider.primaryTextColor,
                  unselectedLabelColor: themeProvider.secondaryTextColor,
                  indicatorColor: themeProvider.accentColor,
                  labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(text: 'Want to Visit'),
                    Tab(text: 'Visited'),
                    Tab(text: 'Discover'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWantToVisitList(),
          _buildVisitedList(),
          _buildDiscoverList(),
        ],
      ),
      floatingActionButton: _tabController.index == 2
        ? FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Cafe'),
            backgroundColor: Colors.blue,
          )
        : null,
    );
  }

  Widget _buildWantToVisitList() {
    return Consumer<CoffeeShopProvider>(
      builder: (context, provider, child) {
        final wantToVisitShops = provider.getWantToVisitCoffeeShops();
        final sortedShops = _sortCoffeeShops(wantToVisitShops);

        if (sortedShops.isEmpty) {
          return _buildEmptyState(
            'No cafes in your "Want to Visit" list',
            'Start exploring and add cafes you want to try!',
            Icons.bookmark_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedShops.length,
          itemBuilder: (context, index) {
            final coffeeShop = sortedShops[index];
            return _buildTrackingCard(coffeeShop, 'want_to_visit');
          },
        );
      },
    );
  }

  Widget _buildVisitedList() {
    return Consumer<CoffeeShopProvider>(
      builder: (context, provider, child) {
        final visitedShops = provider.getVisitedCoffeeShops();
        final sortedShops = _sortCoffeeShops(visitedShops);

        if (sortedShops.isEmpty) {
          return _buildEmptyState(
            'No visited cafes yet',
            'Start visiting cafes and track your experiences!',
            Icons.check_circle_outline,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedShops.length,
          itemBuilder: (context, index) {
            final coffeeShop = sortedShops[index];
            return _buildTrackingCard(coffeeShop, 'visited');
          },
        );
      },
    );
  }

  Widget _buildDiscoverList() {
    return Consumer<CoffeeShopProvider>(
      builder: (context, provider, child) {
        final notTrackedShops = provider.getNotTrackedCoffeeShops();
        final sortedShops = _sortCoffeeShops(notTrackedShops);

        if (sortedShops.isEmpty) {
          return _buildEmptyState(
            'All cafes tracked!',
            'You\'ve added all available cafes to your list',
            Icons.celebration,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedShops.length,
          itemBuilder: (context, index) {
            final coffeeShop = sortedShops[index];
            return _buildTrackingCard(coffeeShop, 'discover');
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (_tabController.index == 2) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.explore),
              label: const Text('Explore Cafes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingCard(CoffeeShop coffeeShop, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CoffeeShopDetailScreen(coffeeShop: coffeeShop),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: coffeeShop.photos.isNotEmpty
                            ? coffeeShop.photos.first
                            : 'https://picsum.photos/seed/coffee/100/100',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.coffee,
                            color: Colors.grey,
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
                                  coffeeShop.name,
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _buildStatusBadge(type),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.orange[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${coffeeShop.rating} (${coffeeShop.reviewCount} reviews)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  coffeeShop.address,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (type == 'visited' && coffeeShop.visitData != null) ...[
                            _buildVisitInfo(coffeeShop.visitData!),
                          ] else if (type == 'want_to_visit') ...[
                            _buildWantToVisitInfo(),
                          ] else if (type == 'discover') ...[
                            _buildDiscoverInfo(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  coffeeShop.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Action buttons for want to visit
                if (type == 'want_to_visit') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _markAsVisited(context, coffeeShop),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text('Mark Visited'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            foregroundColor: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _removeFromWantToVisit(context, coffeeShop),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Remove'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String type) {
    Color color;
    IconData icon;
    String label;

    switch (type) {
      case 'want_to_visit':
        color = Colors.blue;
        icon = Icons.bookmark;
        label = 'Want to Visit';
        break;
      case 'visited':
        color = Colors.green;
        icon = Icons.check_circle;
        label = 'Visited';
        break;
      case 'discover':
        color = Colors.orange;
        icon = Icons.add_circle_outline;
        label = 'Add to List';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        label = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitInfo(VisitData visitData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visitData.personalRating != null) ...[
          Row(
            children: [
              Icon(
                Icons.star,
                size: 14,
                color: Colors.orange[400],
              ),
              const SizedBox(width: 4),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Text(
                    'Your rating: ${visitData.personalRating!.toStringAsFixed(1)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: themeProvider.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
        if (visitData.visitDates.isNotEmpty) ...[
          Row(
            children: [
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: themeProvider.accentColor,
                  );
                },
              ),
              const SizedBox(width: 4),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Text(
                    'Visited ${visitData.visitDates.length} time${visitData.visitDates.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: themeProvider.accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildWantToVisitInfo() {
    return Row(
      children: [
        Icon(
          Icons.bookmark,
          size: 14,
          color: Colors.blue,
        ),
        const SizedBox(width: 4),
        Text(
          'In your wishlist',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.blue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverInfo() {
    return Row(
      children: [
        Icon(
          Icons.add_circle_outline,
          size: 14,
          color: Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          'Tap to add to your list',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.orange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<CoffeeShop> _sortCoffeeShops(List<CoffeeShop> coffeeShops) {
    List<CoffeeShop> sortedShops = List.from(coffeeShops);

    switch (_sortBy) {
      case 'name':
        sortedShops.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'rating':
        sortedShops.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'date':
        if (_tabController.index == 1) { // Visited tab
          sortedShops.sort((a, b) {
            if (a.visitData == null && b.visitData == null) return 0;
            if (a.visitData == null) return 1;
            if (b.visitData == null) return -1;
            return b.visitData!.updatedAt.compareTo(a.visitData!.updatedAt);
          });
        }
        break;
    }

    return sortedShops;
  }

  void _markAsVisited(BuildContext context, CoffeeShop coffeeShop) {
    showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => VisitDetailsDialog(coffeeShop: coffeeShop),
    ).then((result) {
      if (result != null) {
        final provider = context.read<CoffeeShopProvider>();
        provider.markAsVisited(
          coffeeShop.id,
          personalRating: result['personalRating'],
          privateReview: result['privateReview'],
          visitDates: result['visitDates'],
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marked as visited!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _removeFromWantToVisit(BuildContext context, CoffeeShop coffeeShop) {
    showDialog<String>(
      context: context,
      builder: (context) => RemoveFromTrackingDialog(
        coffeeShop: coffeeShop,
        trackingType: 'want_to_visit',
      ),
    ).then((result) {
      if (result == 'remove') {
        final provider = context.read<CoffeeShopProvider>();
        provider.removeFromWantToVisit(coffeeShop.id);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed from your list',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}