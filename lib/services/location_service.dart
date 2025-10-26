import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Future<bool> hasLocationPermission() async {
    final permission = await Permission.locationWhenInUse.status;
    return permission.isGranted;
  }

  static Future<bool> requestLocationPermission() async {
    final permission = await Permission.locationWhenInUse.request();
    return permission.isGranted;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
  }
}