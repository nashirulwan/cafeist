import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/coffee_shop_provider.dart';
import '../models/coffee_shop.dart';
import 'coffee_shop_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMarkers();
    });
  }

  void _updateMarkers() {
    final coffeeShops = context.read<CoffeeShopProvider>().nearbyCoffeeShops;

    setState(() {
      _markers = coffeeShops.map((shop) {
        return Marker(
          markerId: MarkerId(shop.id),
          position: LatLng(shop.latitude, shop.longitude),
          infoWindow: InfoWindow(
            title: shop.name,
            snippet: shop.address,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CoffeeShopDetailScreen(coffeeShop: shop),
                ),
              );
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            shop.isFavorite ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRed,
          ),
        );
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CoffeeShopProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(40.7580, -73.9855), // NYC center
                  zoom: 12,
                ),
                markers: _markers,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              ),
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: _buildSearchBar(),
              ),
              Positioned(
                bottom: 100,
                left: 16,
                child: _buildFilterButton(),
              ),
              Positioned(
                bottom: 100,
                right: 16,
                child: _buildLocationButton(),
              ),
              if (provider.nearbyCoffeeShops.isNotEmpty)
                Positioned(
                  bottom: 180,
                  left: 16,
                  right: 16,
                  child: _buildCoffeeShopCard(provider.nearbyCoffeeShops.first),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
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
            onPressed: _showFilterDialog,
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

  Widget _buildFilterButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.white,
      onPressed: _showFilterDialog,
      child: const Icon(
        Icons.filter_list,
        color: Color(0xFF6F4E37),
      ),
    );
  }

  Widget _buildLocationButton() {
    return FloatingActionButton(
      mini: true,
      backgroundColor: Colors.white,
      onPressed: _centerOnUserLocation,
      child: const Icon(
        Icons.my_location,
        color: Color(0xFF6F4E37),
      ),
    );
  }

  Widget _buildCoffeeShopCard(CoffeeShop coffeeShop) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CoffeeShopDetailScreen(coffeeShop: coffeeShop),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
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
            const SizedBox(width: 12),
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
                      if (coffeeShop.isFavorite)
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 16,
                        ),
                    ],
                  ),
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
                  Text(
                    coffeeShop.address,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
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
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const FilterDialog(),
    );
  }

  void _centerOnUserLocation() {
    // In a real app, this would center on the user's actual location
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        const CameraPosition(
          target: LatLng(40.7580, -73.9855),
          zoom: 14,
        ),
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