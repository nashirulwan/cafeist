import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/coffee_shop_provider.dart';
import '../models/coffee_shop.dart';
import 'coffee_shop_detail_screen.dart';

class MapScreenSafe extends StatefulWidget {
  const MapScreenSafe({super.key});

  @override
  State<MapScreenSafe> createState() => _MapScreenSafeState();
}

class _MapScreenSafeState extends State<MapScreenSafe> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<CoffeeShopProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.updateNearbyCoffeeShops(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildSearchBar(context),
              _buildMapViewPlaceholder(),
              Expanded(child: _buildCoffeeShopList(provider.nearbyCoffeeShops)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (value) {
          context.read<CoffeeShopProvider>().searchCoffeeShops(value);
        },
        decoration: InputDecoration(
          hintText: 'Search coffee shops...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMapViewPlaceholder() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Map View',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Google Maps requires API key',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Demo Mode',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoffeeShopList(List<CoffeeShop> coffeeShops) {
    if (coffeeShops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.coffee_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No coffee shops found',
              style: GoogleFonts.inter(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: coffeeShops.length,
      itemBuilder: (context, index) {
        final coffeeShop = coffeeShops[index];
        return _buildCoffeeShopCard(coffeeShop);
      },
    );
  }

  Widget _buildCoffeeShopCard(CoffeeShop coffeeShop) {
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
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: coffeeShop.photos.isNotEmpty
                        ? coffeeShop.photos.first
                        : 'https://picsum.photos/seed/coffee/80/80',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 80,
                      height: 80,
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              coffeeShop.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: coffeeShop.isFavorite
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              context.read<CoffeeShopProvider>().toggleFavorite(coffeeShop.id);
                            },
                          ),
                        ],
                      ),
                      // Status badge (hanya untuk yang sudah di-list)
                      if (coffeeShop.trackingStatus != CafeTrackingStatus.notTracked) ...[
                        const SizedBox(height: 4),
                        _buildStatusBadge(coffeeShop.trackingStatus),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.orange[400],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${coffeeShop.rating} (${coffeeShop.reviewCount})',
                            style: GoogleFonts.inter(
                              fontSize: 12,
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
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              coffeeShop.address,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (coffeeShop.distance > 0)
                            Text(
                              '${(coffeeShop.distance / 1000).toStringAsFixed(1)} km',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF6F4E37),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (coffeeShop.distance > 0 && coffeeShop.isOpen)
                            const SizedBox(width: 8),
                          if (coffeeShop.isOpen)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Open',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const FilterDialog(),
    );
  }

  Widget _buildStatusBadge(CafeTrackingStatus status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case CafeTrackingStatus.wantToVisit:
        color = Colors.blue;
        label = 'Want to Visit';
        icon = Icons.bookmark;
        break;
      case CafeTrackingStatus.visited:
        color = Colors.green;
        label = 'Visited';
        icon = Icons.check_circle;
        break;
      case CafeTrackingStatus.notTracked:
      default:
        return const SizedBox.shrink(); // Jangan tampilkan apa-apa untuk notTracked
    }

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
}

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  List<String> selectedFeatures = [];

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CoffeeShopProvider>();
    final allFeatures = provider.getAllFeatures();

    return AlertDialog(
      title: Text(
        'Filter Coffee Shops',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allFeatures.map((feature) {
                final isSelected = selectedFeatures.contains(feature);
                return FilterChip(
                  label: Text(
                    feature,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedFeatures.add(feature);
                      } else {
                        selectedFeatures.remove(feature);
                      }
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFF6F4E37).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF6F4E37),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              selectedFeatures.clear();
            });
          },
          child: Text(
            'Clear',
            style: GoogleFonts.inter(),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            provider.filterByFeatures(selectedFeatures);
            Navigator.pop(context);
          },
          child: Text(
            'Apply',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}