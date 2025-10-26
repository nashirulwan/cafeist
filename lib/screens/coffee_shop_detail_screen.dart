import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/coffee_shop.dart';
import '../providers/coffee_shop_provider.dart';
import '../widgets/add_visit_dialog.dart';

class CoffeeShopDetailScreen extends StatefulWidget {
  final CoffeeShop coffeeShop;

  const CoffeeShopDetailScreen({super.key, required this.coffeeShop});

  @override
  State<CoffeeShopDetailScreen> createState() => _CoffeeShopDetailScreenState();
}

class _CoffeeShopDetailScreenState extends State<CoffeeShopDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      body: Consumer<CoffeeShopProvider>(
        builder: (context, provider, child) {
          final coffeeShop = provider.getCoffeeShopById(widget.coffeeShop.id) ?? widget.coffeeShop;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(coffeeShop),
              SliverToBoxAdapter(child: _buildHeaderSection(coffeeShop)),
              SliverToBoxAdapter(child: _buildTrackingStatus(coffeeShop)),
              SliverToBoxAdapter(child: _buildActionButtons(coffeeShop)),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(coffeeShop),
                    _buildReviewsTab(coffeeShop),
                    _buildPhotosTab(coffeeShop),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<CoffeeShopProvider>(
        builder: (context, provider, child) {
          final coffeeShop = provider.getCoffeeShopById(widget.coffeeShop.id) ?? widget.coffeeShop;

          if (coffeeShop.trackingStatus == CafeTrackingStatus.notTracked) {
            return FloatingActionButton.extended(
              onPressed: () => _showAddToTrackingDialog(context, coffeeShop),
              icon: const Icon(Icons.add),
              label: const Text('Add to List'),
              backgroundColor: const Color(0xFF6F4E37),
            );
          } else if (coffeeShop.trackingStatus == CafeTrackingStatus.wantToVisit) {
            return FloatingActionButton.extended(
              onPressed: () => _markAsVisited(context, coffeeShop),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark Visited'),
              backgroundColor: Colors.green,
            );
          } else if (coffeeShop.trackingStatus == CafeTrackingStatus.visited) {
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
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // Share functionality
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
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.7),
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
                color: Color(0xFF6F4E37),
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
                  color: Color(0xFF6F4E37),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '${(coffeeShop.distance / 1000).toStringAsFixed(1)} km away',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF6F4E37),
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
      default:
        statusColor = Colors.grey;
        statusText = 'Not Tracked';
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
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
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                _launchMaps(coffeeShop);
              },
              icon: const Icon(Icons.directions),
              label: Text(
                'Directions',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _makeReservation(coffeeShop.phoneNumber);
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                'Reservation',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                foregroundColor: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: const Color(0xFF6F4E37),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const Color(0xFF6F4E37),
      tabs: const [
        Tab(text: 'Overview'),
        Tab(text: 'Reviews'),
        Tab(text: 'Photos'),
      ],
    );
  }

  Widget _buildOverviewTab(CoffeeShop coffeeShop) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
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
      padding: const EdgeInsets.all(16),
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
                    backgroundColor: const Color(0xFF6F4E37),
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
      padding: const EdgeInsets.all(16),
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

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: List.generate(7, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  days[index],
                  style: GoogleFonts.inter(
                    fontWeight: days[index] == _getTodayName()
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: days[index] == _getTodayName()
                        ? const Color(0xFF6F4E37)
                        : Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
                  ),
                ),
                Text(
                  hours[index],
                  style: GoogleFonts.inter(
                    fontWeight: days[index] == _getTodayName()
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: days[index] == _getTodayName()
                        ? const Color(0xFF6F4E37)
                        : Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
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
          ListTile(
            leading: const Icon(Icons.calendar_today, color: Color(0xFF6F4E37)),
            title: Text('Make Reservation'),
            onTap: () => _makeReservation(coffeeShop.phoneNumber),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.language, color: Color(0xFF6F4E37)),
            title: Text('Visit Website'),
            onTap: () => _launchWebsite(coffeeShop.website),
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
                leading: Icon(icon, color: const Color(0xFF6F4E37)),
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

  void _launchMaps(CoffeeShop coffeeShop) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${coffeeShop.latitude},${coffeeShop.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _makeReservation(String phoneNumber) async {
    // Remove any non-digit characters for WhatsApp
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final message = Uri.encodeComponent('Hi! I would like to make a reservation at your coffee shop.');
    final url = 'https://wa.me/$cleanPhone?text=$message';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchWebsite(String website) async {
    if (await canLaunchUrl(Uri.parse(website))) {
      await launchUrl(Uri.parse(website));
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
    final result = await showDialog<String>(
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
      } else if (result == 'visited') {
        _showVisitDetailsDialog(context, coffeeShop);
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
      provider.updateVisitData(
        coffeeShop.id,
        personalRating: result['personalRating'],
        privateReview: result['privateReview'],
        visitDates: result['visitDates'],
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
      provider.addVisitDate(coffeeShop.id, result);

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