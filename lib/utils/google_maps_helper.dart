import 'package:url_launcher/url_launcher.dart';
import '../utils/logger.dart';

/// Helper class for Google Maps integration
class GoogleMapsHelper {

  /// Open Google Maps with directions from user's current location to cafe
  static Future<void> openDirections({
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
    double? originLat,
    double? originLng,
  }) async {
    try {
      // Build Google Maps URL - use coordinates only (more reliable)
      Uri url;

      if (originLat != null && originLng != null) {
        // Directions from specific origin
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng'
          '&destination=$destinationLat,$destinationLng'
          '&travelmode=driving'
        );
      } else {
        // Directions from current location
        url = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng'
          '&travelmode=driving'
        );
      }

      AppLogger.info('Opening directions to $destinationName', tag: 'Maps');

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        AppLogger.success('Opened Google Maps directions', tag: 'Maps');
      } else {
        AppLogger.error('Could not launch Google Maps', tag: 'Maps');
      }
    } catch (e) {
      AppLogger.error('Error opening Google Maps directions', error: e, tag: 'Maps');
    }
  }

  /// Share Google Maps link to cafe
  static Future<void> shareLocation({
    required double lat,
    required double lng,
    required String name,
  }) async {
    try {
      // Create Google Maps URL using coordinates
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
      );

      AppLogger.info('Sharing location: $name', tag: 'Maps');

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        AppLogger.success('Opened Google Maps share', tag: 'Maps');
      } else {
        AppLogger.error('Could not launch Google Maps share', tag: 'Maps');
      }
    } catch (e) {
      AppLogger.error('Error sharing Google Maps location', error: e, tag: 'Maps');
    }
  }

  /// Open location in Google Maps (view mode)
  static Future<void> openLocation({
    required double lat,
    required double lng,
    required String name,
  }) async {
    try {
      final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
      );

      AppLogger.info('Opening location in Google Maps: $name', tag: 'Maps');

      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        AppLogger.success('Opened Google Maps location', tag: 'Maps');
      } else {
        AppLogger.error('Could not launch Google Maps location', tag: 'Maps');
      }
    } catch (e) {
      AppLogger.error('Error opening Google Maps location', error: e, tag: 'Maps');
    }
  }

  /// Get shareable Google Maps URL using place_id for proper cafe link
  static String getShareableMapUrl({
    required double lat,
    required double lng,
    required String name,
    String? placeId,
  }) {
    // Use place_id if available for a proper Google Maps link to the cafe
    if (placeId != null && placeId.isNotEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(name)}&query_place_id=$placeId';
    }
    // Fallback to coordinates
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
  }

  /// Get directions URL
  static String getDirectionsUrl({
    required double destinationLat,
    required double destinationLng,
    required String destinationName,
    double? originLat,
    double? originLng,
  }) {
    if (originLat != null && originLng != null) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng'
          '&destination=$destinationLat,$destinationLng&travelmode=driving';
    } else {
      return 'https://www.google.com/maps/dir/?api=1&destination=$destinationLat,$destinationLng'
          '&travelmode=driving';
    }
  }
}