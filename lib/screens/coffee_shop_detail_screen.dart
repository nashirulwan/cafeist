import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../models/coffee_shop.dart';
import '../providers/coffee_shop_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/add_visit_dialog.dart';
import '../utils/google_maps_helper.dart';
import '../services/places_service.dart';

class CoffeeShopDetailScreen extends StatefulWidget {
  final CoffeeShop coffeeShop;

  const CoffeeShopDetailScreen({super.key, required this.coffeeShop});

  @override
  State<CoffeeShopDetailScreen> createState() => _CoffeeShopDetailScreenState();
}

class _CoffeeShopDetailScreenState extends State<CoffeeShopDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CoffeeShop? _detailedCoffeeShop;
  bool _isLoadingDetails = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    if (!mounted) return;
    
    setState(() => _isLoadingDetails = true);
    
    try {
      final placesService = PlacesService();
      if (placesService.isReady) {
        final details = await placesService.getPlaceDetails(widget.coffeeShop.id);
        if (mounted && details != null) {
          setState(() {
            _detailedCoffeeShop = details.copyWith(
              isFavorite: widget.coffeeShop.isFavorite,
              trackingStatus: widget.coffeeShop.trackingStatus,
              visitData: widget.coffeeShop.visitData,
              distance: widget.coffeeShop.distance,
            );
          });
        }
      }
    } catch (e) {
      // Fallback to basic info if API fails
      debugPrint('Failed to load place details: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer2<CoffeeShopProvider, ThemeProvider>(
        builder: (context, provider, themeProvider, child) {
          // Get the latest state from provider
          final baseCoffeeShop = provider.getCoffeeShopById(widget.coffeeShop.id) ?? widget.coffeeShop;
          
          // Use detailed data if available, but always sync isFavorite and trackingStatus from provider
          CoffeeShop coffeeShop;
          final isFavorite = provider.isFavorite(widget.coffeeShop.id);
          
          if (_detailedCoffeeShop != null) {
            coffeeShop = _detailedCoffeeShop!.copyWith(
              isFavorite: isFavorite,
              trackingStatus: baseCoffeeShop.trackingStatus,
              visitData: baseCoffeeShop.visitData,
            );
          } else {
            coffeeShop = baseCoffeeShop.copyWith(
              isFavorite: isFavorite,
            );
          }

          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildSliverAppBar(coffeeShop),
                  SliverToBoxAdapter(child: _buildHeaderSection(coffeeShop)),
                  SliverToBoxAdapter(child: _buildTrackingStatus(coffeeShop)),
                  SliverToBoxAdapter(child: _buildActionButtons(coffeeShop)),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(_buildTabBar(themeProvider)),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(coffeeShop),
                  _buildReviewsTab(coffeeShop),
                  _buildPhotosTab(coffeeShop),
                ],
              ),
            ),
            floatingActionButton: Consumer2<CoffeeShopProvider, ThemeProvider>(
              builder: (context, provider, themeProvider, child) {
                // Determine if we should show floating action button
                final trackingStatus = coffeeShop.trackingStatus;
                
                if (trackingStatus == CafeTrackingStatus.notTracked) {
                  return FloatingActionButton.extended(
                    onPressed: () => _showAddToTrackingDialog(context, coffeeShop),
                    icon: const Icon(Icons.add),
                    label: const Text('Add to List'),
                    backgroundColor: themeProvider.accentColor,
                  );
                } else if (trackingStatus == CafeTrackingStatus.wantToVisit) {
                  return FloatingActionButton.extended(
                    onPressed: () => _markAsVisited(context, coffeeShop),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark Visited'),
                    backgroundColor: Colors.green,
                  );
                } else if (trackingStatus == CafeTrackingStatus.visited) {
                  return FloatingActionButton.extended(
                    onPressed: () => _addRevisit(context, coffeeShop),
                    icon: const Icon(Icons.replay),
                    label: const Text('Revisit'),
                    backgroundColor: Colors.blue,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(CoffeeShop coffeeShop) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      actions: [
        IconButton(
          icon: Icon(
            coffeeShop.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: coffeeShop.isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () {
            context.read<CoffeeShopProvider>().toggleFavorite(coffeeShop.id);
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: coffeeShop.photos.isNotEmpty
                  ? coffeeShop.photos.first
                  : 'https://picsum.photos/seed/coffee/400/250',
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Icon(
                  Icons.coffee,
                  size: 80,
                  color: Colors.grey,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor.withValues(alpha:0.7),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(CoffeeShop coffeeShop) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  coffeeShop.name,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: coffeeShop.isOpen ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  coffeeShop.isOpen ? 'Open Now' : 'Closed',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).cardTheme.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.orange[400],
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${coffeeShop.rating}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' (${coffeeShop.reviewCount} reviews)',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Colors.transparent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  coffeeShop.address,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          if (coffeeShop.distance > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  color: Colors.transparent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(coffeeShop.distance / 1000).toStringAsFixed(1)} km away',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.transparent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingStatus(CoffeeShop coffeeShop) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (coffeeShop.trackingStatus) {
      case CafeTrackingStatus.wantToVisit:
        statusColor = Colors.blue;
        statusText = 'Want to Visit';
        statusIcon = Icons.bookmark;
        break;
      case CafeTrackingStatus.visited:
        statusColor = Colors.green;
        statusText = 'Visited';
        statusIcon = Icons.check_circle;
        break;
      case CafeTrackingStatus.notTracked:
        statusColor = Colors.grey;
        statusText = 'Not Tracked';
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha:0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Status',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (coffeeShop.trackingStatus == CafeTrackingStatus.visited && coffeeShop.visitData != null) ...[
                  const SizedBox(height: 4),
                  _buildVisitSummary(coffeeShop.visitData!),
                ],
              ],
            ),
          ),
          if (coffeeShop.trackingStatus == CafeTrackingStatus.visited) ...[
            TextButton(
              onPressed: () => _editVisitDetails(context, coffeeShop),
              child: Text(
                'Edit Details',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisitSummary(VisitData visitData) {
    List<String> summary = [];

    if (visitData.personalRating != null) {
      summary.add('Rated: ${visitData.personalRating!.toStringAsFixed(1)}⭐');
    }

    if (visitData.visitDates.isNotEmpty) {
      summary.add('Visited: ${visitData.visitDates.length} time${visitData.visitDates.length > 1 ? 's' : ''}');
    }

    if (visitData.privateReview != null && visitData.privateReview!.isNotEmpty) {
      summary.add('Has notes');
    }

    if (summary.isEmpty) {
      summary.add('No details yet');
    }

    return Text(
      summary.join(' • '),
      style: GoogleFonts.inter(
        fontSize: 12,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildActionButtons(CoffeeShop coffeeShop) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _openDirections(coffeeShop);
                  },
                  icon: const Icon(Icons.directions),
                  label: Text(
                    'Directions',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _shareLocation(coffeeShop);
                  },
                  icon: const Icon(Icons.share),
                  label: Text(
                    'Share',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          // Contact buttons
          if (coffeeShop.phoneNumber.isNotEmpty || coffeeShop.website.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (coffeeShop.phoneNumber.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _callPhone(coffeeShop.phoneNumber);
                      },
                      icon: const Icon(Icons.phone),
                      label: Text(
                        'Call',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (coffeeShop.website.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _openWebsite(coffeeShop.website);
                      },
                      icon: const Icon(Icons.language),
                      label: Text(
                        'Website',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.purple),
                        foregroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  TabBar _buildTabBar(ThemeProvider themeProvider) {
    return TabBar(
      controller: _tabController,
      labelColor: themeProvider.accentColor,
      unselectedLabelColor: themeProvider.secondaryTextColor,
      indicatorColor: themeProvider.accentColor,
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Reviews'),
        Tab(text: 'Photos'),
      ],
    );
  }

  Widget _buildOverviewTab(CoffeeShop coffeeShop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('About'),
          const SizedBox(height: 8),
          Text(
            coffeeShop.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          _buildSectionTitle('Hours'),
          const SizedBox(height: 8),
          _buildHoursList(coffeeShop.openingHours),
          const SizedBox(height: 24),

          // Social Media
          if (coffeeShop.socialMedia != null && coffeeShop.socialMedia!.isNotEmpty) ...[
            _buildSectionTitle('Social Media'),
            const SizedBox(height: 8),
            _buildSocialMediaLinks(coffeeShop.socialMedia!),
            const SizedBox(height: 24),
          ],

          _buildSectionTitle('Contact'),
          const SizedBox(height: 8),
          _buildContactInfo(coffeeShop),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(CoffeeShop coffeeShop) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: coffeeShop.reviews.length,
      itemBuilder: (context, index) {
        final review = coffeeShop.reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    child: Text(
                      review.userName[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        color: Theme.of(context).cardTheme.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.userName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return Icon(
                                index < review.rating.floor()
                                    ? Icons.star
                                    : index < review.rating
                                        ? Icons.star_half
                                        : Icons.star_border,
                                size: 14,
                                color: Colors.orange[400],
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(review.date),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (review.comment.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  review.comment,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotosTab(CoffeeShop coffeeShop) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: coffeeShop.photos.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            _showPhotoViewer(coffeeShop.photos, index);
          },
          child: Hero(
            tag: 'photo_$index',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: coffeeShop.photos[index],
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildHoursList(dynamic openingHours) {
    final days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final hours = [
      openingHours.monday,
      openingHours.tuesday,
      openingHours.wednesday,
      openingHours.thursday,
      openingHours.friday,
      openingHours.saturday,
      openingHours.sunday,
    ];

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            children: List.generate(7, (index) {
              final isToday = days[index] == _getTodayName();
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: isToday ? 12 : 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      days[index],
                      style: GoogleFonts.inter(
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? themeProvider.accentColor
                            : themeProvider.primaryTextColor,
                      ),
                    ),
                    Text(
                      hours[index],
                      style: GoogleFonts.inter(
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday
                            ? themeProvider.accentColor
                            : themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildContactInfo(CoffeeShop coffeeShop) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Address
          ListTile(
            leading: Consumer<ThemeProvider>(builder: (context, themeProvider, child) => Icon(Icons.location_on, color: themeProvider.accentColor)),
            title: Text('Address'),
            subtitle: Text(
              coffeeShop.address,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            onTap: () => _openDirections(coffeeShop),
          ),
          const Divider(height: 1),

          // Phone
          if (coffeeShop.phoneNumber.isNotEmpty) ...[
            ListTile(
              leading: Consumer<ThemeProvider>(builder: (context, themeProvider, child) => Icon(Icons.phone, color: themeProvider.accentColor)),
              title: Text('Phone'),
              subtitle: Text(
                coffeeShop.phoneNumber,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              onTap: () => _callPhone(coffeeShop.phoneNumber),
            ),
            const Divider(height: 1),
          ],

          // Website
          if (coffeeShop.website.isNotEmpty) ...[
            ListTile(
              leading: Consumer<ThemeProvider>(builder: (context, themeProvider, child) => Icon(Icons.language, color: themeProvider.accentColor)),
              title: Text('Website'),
              subtitle: Text(
                coffeeShop.website,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _openWebsite(coffeeShop.website),
            ),
            const Divider(height: 1),
          ],

          // Status
          ListTile(
            leading: Consumer<ThemeProvider>(builder: (context, themeProvider, child) => Icon(
              coffeeShop.isOpen ? Icons.access_time : Icons.access_time_filled,
              color: coffeeShop.isOpen ? Colors.green : Colors.red,
            )),
            title: Text('Status'),
            subtitle: Text(
              coffeeShop.isOpen ? 'Open now' : 'Closed now',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: coffeeShop.isOpen ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Text(
              coffeeShop.openingHours.getTodayHours(),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaLinks(Map<String, String> socialMedia) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: socialMedia.entries.map((entry) {
          final platform = entry.key;
          final url = entry.value;
          IconData icon;
          String label;

          switch (platform.toLowerCase()) {
            case 'instagram':
              icon = Icons.camera_alt;
              label = 'Instagram';
              break;
            case 'facebook':
              icon = Icons.facebook;
              label = 'Facebook';
              break;
            case 'twitter':
              icon = Icons.alternate_email;
              label = 'Twitter';
              break;
            case 'tiktok':
              icon = Icons.music_note;
              label = 'TikTok';
              break;
            case 'youtube':
              icon = Icons.play_circle_filled;
              label = 'YouTube';
              break;
            case 'linkedin':
              icon = Icons.work;
              label = 'LinkedIn';
              break;
            default:
              icon = Icons.link;
              label = platform;
          }

          return Column(
            children: [
              ListTile(
                leading: Consumer<ThemeProvider>(builder: (context, themeProvider, child) => Icon(icon, color: themeProvider.accentColor)),
                title: Text(label),
                subtitle: Text(
                  platform.toLowerCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: const Icon(Icons.open_in_new, color: Colors.grey),
                onTap: () => _launchSocialMedia(url),
              ),
              if (socialMedia.keys.last != platform) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getTodayName() {
    final today = DateTime.now().weekday;
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[today - 1];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }



  void _launchSocialMedia(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _showPhotoViewer(List<String> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // Tracking functionality
  void _showAddToTrackingDialog(BuildContext context, CoffeeShop coffeeShop) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => AddVisitDialog(coffeeShop: coffeeShop),
    );

    if (result != null) {
      final provider = context.read<CoffeeShopProvider>();

      if (result == 'want_to_visit') {
        provider.addToWantToVisit(coffeeShop.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Added to your "Want to Visit" list!',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.blue,
          ),
        );
      } else if (result is Map<String, dynamic>) {
        // Handle visited case with the map data directly
        final personalRating = result['personalRating'];
        provider.markAsVisited(
          coffeeShop.id,
          rating: personalRating is double ? personalRating.round() : (personalRating as int?),
          note: result['privateReview'],
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
    }
  }

  void _markAsVisited(BuildContext context, CoffeeShop coffeeShop) {
    _showVisitDetailsDialog(context, coffeeShop);
  }

  void _showVisitDetailsDialog(BuildContext context, CoffeeShop coffeeShop) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => VisitDetailsDialog(coffeeShop: coffeeShop),
    );

    if (result != null) {
      final provider = context.read<CoffeeShopProvider>();
      provider.markAsVisited(
        coffeeShop.id,
        rating: result['personalRating'],
        note: result['privateReview'],
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
  }

  void _editVisitDetails(BuildContext context, CoffeeShop coffeeShop) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) => VisitDetailsDialog(
        coffeeShop: coffeeShop,
        isEditing: true,
      ),
    );

    if (result != null) {
      final provider = context.read<CoffeeShopProvider>();
      final visitData = VisitData(
        personalRating: result['personalRating']?.toDouble(),
        privateReview: result['privateReview'],
        visitDates: result['visitDates'] ?? [DateTime.now()],
      );
      provider.updateVisitData(
        coffeeShop.id,
        visitData,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Visit details updated!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _addRevisit(BuildContext context, CoffeeShop coffeeShop) async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => AddRevisitDialog(coffeeShop: coffeeShop),
    );

    if (result != null) {
      final provider = context.read<CoffeeShopProvider>();
      final visitData = VisitData(
        visitDates: [result],
      );
      provider.addVisitDate(coffeeShop.id, visitData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Revisit date added!',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  // Google Maps Integration Methods
  void _openDirections(CoffeeShop coffeeShop) async {
    final provider = context.read<CoffeeShopProvider>();

    await GoogleMapsHelper.openDirections(
      destinationLat: coffeeShop.latitude,
      destinationLng: coffeeShop.longitude,
      destinationName: coffeeShop.name,
      originLat: provider.userLatitude != 0.0 ? provider.userLatitude : null,
      originLng: provider.userLongitude != 0.0 ? provider.userLongitude : null,
    );
  }

  void _shareLocation(CoffeeShop coffeeShop) async {
    // Copy to clipboard - use place_id for proper Google Maps cafe link
    // Only use if it looks like a valid Google Place ID (length > 10)
    final placeId = (coffeeShop.id.length > 10) ? coffeeShop.id : null;
    
    final mapUrl = GoogleMapsHelper.getShareableMapUrl(
      lat: coffeeShop.latitude,
      lng: coffeeShop.longitude,
      name: coffeeShop.name,
      placeId: placeId,
    );

    await Clipboard.setData(ClipboardData(text: mapUrl));

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Google Maps link copied!',
            style: GoogleFonts.inter(),
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _callPhone(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not make phone call')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error making phone call')),
        );
      }
    }
  }

  void _shareCoffeeShop(CoffeeShop coffeeShop) async {
    try {
      // Only copy Google Maps link
      final mapUrl = GoogleMapsHelper.getShareableMapUrl(
        lat: coffeeShop.latitude,
        lng: coffeeShop.longitude,
        name: coffeeShop.name,
      );

      await Clipboard.setData(ClipboardData(text: mapUrl));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Google Maps link copied!',
              style: GoogleFonts.inter(),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error sharing coffee shop',
              style: GoogleFonts.inter(),
            ),
          ),
        );
      }
    }
  }

  void _openWebsite(String websiteUrl) async {
    Uri url;
    if (websiteUrl.startsWith('http')) {
      url = Uri.parse(websiteUrl);
    } else {
      url = Uri.parse('https://$websiteUrl');
    }

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open website')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening website')),
        );
      }
    }
  }
}

class PhotoViewerScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const PhotoViewerScreen({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.photos.length}',
          style: GoogleFonts.inter(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: widget.photos[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.broken_image,
                  color: Theme.of(context).cardTheme.color,
                  size: 64,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}