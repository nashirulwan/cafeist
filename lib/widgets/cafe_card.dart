import 'package:flutter/material.dart';
import '../models/coffee_shop.dart';

class CafeCard extends StatelessWidget {
  final CoffeeShop cafe;
  final VoidCallback? onTap;
  final VoidCallback? onTrack;
  final VoidCallback? onRemove;
  final bool showTrackingStatus;

  const CafeCard({
    super.key,
    required this.cafe,
    this.onTap,
    this.onTrack,
    this.onRemove,
    this.showTrackingStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cafe image or placeholder
            if (cafe.photos.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  cafe.photos.first,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                ),
              )
            else
              _buildImagePlaceholder(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with tracking status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cafe.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showTrackingStatus) _buildTrackingStatus(context),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Cafe description
                  Text(
                    cafe.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Rating and review count
                  if (cafe.rating > 0) _buildRatingRow(context),

                  const SizedBox(height: 12),

                  // Address
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
                          cafe.address,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action buttons
                  if (onTrack != null || onRemove != null) _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.brown[100]!,
            Colors.brown[300]!,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Icon(
        Icons.coffee,
        size: 64,
        color: Colors.brown[700],
      ),
    );
  }

  Widget _buildTrackingStatus(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (cafe.trackingStatus) {
      case CafeTrackingStatus.wantToVisit:
        statusColor = Colors.pink;
        statusIcon = Icons.favorite_border;
        statusText = 'Wishlist';
        break;
      case CafeTrackingStatus.visited:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Visited';
        break;
      case CafeTrackingStatus.notTracked:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(BuildContext context) {
    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 16,
              color: Colors.amber[600],
            ),
            const SizedBox(width: 4),
            Text(
              cafe.rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (cafe.reviewCount > 0) ...[
          const SizedBox(width: 8),
          Text(
            '(${cafe.reviewCount} reviews)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
        if (cafe.isOpen) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Open Now',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (onTrack != null) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onTrack,
              icon: Icon(
                cafe.trackingStatus == CafeTrackingStatus.wantToVisit
                    ? Icons.check_circle
                    : Icons.favorite_border,
                size: 16,
              ),
              label: Text(
                cafe.trackingStatus == CafeTrackingStatus.wantToVisit
                    ? 'Mark Visited'
                    : 'Add to Wishlist',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cafe.trackingStatus == CafeTrackingStatus.wantToVisit
                    ? Colors.green.withValues(alpha:0.1)
                    : Colors.pink.withValues(alpha:0.1),
                foregroundColor: cafe.trackingStatus == CafeTrackingStatus.wantToVisit
                    ? Colors.green
                    : Colors.pink,
                side: BorderSide(
                  color: cafe.trackingStatus == CafeTrackingStatus.wantToVisit
                      ? Colors.green.withValues(alpha:0.3)
                      : Colors.pink.withValues(alpha:0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
        if (onRemove != null) ...[
          if (onTrack != null) const SizedBox(width: 12),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.withValues(alpha:0.1),
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red.withValues(alpha:0.3)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple cafe card for list views
class SimpleCafeCard extends StatelessWidget {
  final CoffeeShop cafe;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;

  const SimpleCafeCard({
    super.key,
    required this.cafe,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.brown[100],
          backgroundImage: cafe.photos.isNotEmpty
              ? NetworkImage(cafe.photos.first)
              : null,
          child: cafe.photos.isEmpty
              ? Icon(Icons.coffee, color: Colors.brown[700])
              : null,
        ),
        title: Text(
          cafe.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cafe.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (cafe.rating > 0)
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 14,
                    color: Colors.amber[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    cafe.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (cafe.reviewCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${cafe.reviewCount})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cafe.isOpen)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[700],
                  ),
                ),
              ),
            if (onFavorite != null) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : null,
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}