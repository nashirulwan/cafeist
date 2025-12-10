import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Screen that requests location permission on app startup.
/// Users cannot proceed until permission is granted.
class LocationPermissionScreen extends StatefulWidget {
  final VoidCallback onPermissionGranted;

  const LocationPermissionScreen({
    super.key,
    required this.onPermissionGranted,
  });

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isRequesting = false;
  String _statusMessage = 'Location access is required to find coffee shops near you.';
  bool _isPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _statusMessage = 'Please enable location services on your device.';
      });
      return;
    }

    // Check current permission status
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || 
        permission == LocationPermission.whileInUse) {
      // Permission already granted, proceed
      widget.onPermissionGranted();
    } else if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isPermanentlyDenied = true;
        _statusMessage = 'Location permission is permanently denied. Please enable it in Settings.';
      });
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
      _statusMessage = 'Requesting permission...';
    });

    try {
      // Check if location service is enabled first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isRequesting = false;
          _statusMessage = 'Please enable location services on your device, then try again.';
        });
        return;
      }

      // Request permission
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        // Permission granted!
        widget.onPermissionGranted();
      } else if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isPermanentlyDenied = true;
          _isRequesting = false;
          _statusMessage = 'Location permission is permanently denied. Please enable it in Settings.';
        });
      } else {
        // Permission denied (but not permanently)
        setState(() {
          _isRequesting = false;
          _statusMessage = 'Location permission is required to use this app. Please allow access.';
        });
      }
    } catch (e) {
      setState(() {
        _isRequesting = false;
        _statusMessage = 'Error requesting permission. Please try again.';
      });
    }
  }

  Future<void> _openSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF6F4E37), // Coffee brown
              const Color(0xFF3C2415), // Dark coffee
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                const Text(
                  'Enable Location',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),

                // Status message
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),

                // Action buttons
                if (_isPermanentlyDenied) ...[
                  // Open Settings button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text(
                        'Open App Settings',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6F4E37),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Retry button after settings
                  TextButton(
                    onPressed: _checkInitialPermission,
                    child: const Text(
                      'I\'ve enabled permission, continue',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ] else ...[
                  // Request permission button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isRequesting ? null : _requestPermission,
                      icon: _isRequesting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6F4E37),
                              ),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        _isRequesting ? 'Requesting...' : 'Allow Location Access',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6F4E37),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Enable location services hint
                TextButton.icon(
                  onPressed: _openLocationSettings,
                  icon: const Icon(Icons.gps_fixed, color: Colors.white70, size: 18),
                  label: const Text(
                    'Enable GPS / Location Services',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
