import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'providers/coffee_shop_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/places_service.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/personal_tracking_service.dart';
import 'utils/logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables first
  try {
    await dotenv.load(fileName: ".env");
    AppLogger.success('Environment variables loaded', tag: 'Initialization');

    // Debug: Check loaded API keys (masked for security)
    final placesKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
    final firebaseKey = dotenv.env['FIREBASE_API_KEY'];

    if (placesKey != null && placesKey.isNotEmpty) {
      AppLogger.sensitive('Google Places API key loaded: $placesKey', tag: 'API');
    } else {
      AppLogger.error('Google Places API key not found or empty', tag: 'API');
    }

    if (firebaseKey != null && firebaseKey.isNotEmpty) {
      AppLogger.sensitive('Firebase API key loaded: $firebaseKey', tag: 'API');
    } else {
      AppLogger.warning('Firebase API key not found or empty', tag: 'API');
    }
  } catch (e) {
    AppLogger.error('Failed to load .env file', error: e, tag: 'Initialization');
    AppLogger.warning('Make sure .env file exists and is in the correct location', tag: 'Initialization');
  }

  // Initialize Firebase second (after env is loaded)
  try {
    await FirebaseService.initialize();
    AppLogger.success('Firebase initialized', tag: 'Initialization');
  } catch (e) {
    AppLogger.error('Firebase initialization failed', error: e, tag: 'Initialization');
    AppLogger.info('Continuing without Firebase...', tag: 'Initialization');
  }

  // Initialize Google Sign-In
  try {
    AuthService.initializeGoogleSignIn();
    AppLogger.success('Google Sign-In initialized', tag: 'Authentication');
  } catch (e) {
    AppLogger.error('Google Sign-In initialization failed', error: e, tag: 'Authentication');
  }

  // Initialize Places service last (after Firebase)
  try {
    PlacesService.initialize();

    // Verify initialization
    if (PlacesService.isInitialized) {
      AppLogger.success('Places API initialized successfully', tag: 'API');
    } else {
      AppLogger.warning('Places API initialization failed - no API key available', tag: 'API');
    }
  } catch (e) {
    AppLogger.error('Places API initialization failed', error: e, tag: 'API');
    AppLogger.info('Using offline data fallback...', tag: 'API');
  }

  // Auto-sync user data on app startup if user is logged in
  await _autoSyncUserData();

  runApp(const CoffeeFinderApp());
}

/// Auto-sync user data from Firebase to local storage on app startup
Future<void> _autoSyncUserData() async {
  try {
    AppLogger.info('Checking for existing user session...', tag: 'Sync');

    // Wait a bit for Firebase to fully initialize
    await Future.delayed(Duration(milliseconds: 500));

    // Check if user is logged in
    if (FirebaseService.isLoggedIn) {
      final userId = FirebaseService.currentUser!.uid;
      AppLogger.success('User session found: $userId', tag: 'Sync');

      // Sync data from Firebase to local storage
      try {
        final trackingService = PersonalTrackingService();
        await trackingService.syncFromCloudToLocal(userId);
        AppLogger.success('User data auto-synced from Firebase', tag: 'Sync');
      } catch (e) {
        AppLogger.warning('Auto-sync failed: $e', tag: 'Sync');
        AppLogger.info('Continuing with local data...', tag: 'Sync');
      }
    } else {
      AppLogger.info('No existing user session found', tag: 'Sync');
    }
  } catch (e) {
    AppLogger.error('Auto-sync error', error: e, tag: 'Sync');
    AppLogger.info('App will continue without auto-sync', tag: 'Sync');
  }
}

class CoffeeFinderApp extends StatelessWidget {
  const CoffeeFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CoffeeShopProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, authProvider, themeProvider, child) {
          return MaterialApp(
            title: 'Cafeist',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: authProvider.isLoggedIn ? const MainScreen() : const AuthScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ListScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoffeeShopProvider>().updateNearbyCoffeeShops();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          body: _screens[_currentIndex],
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: themeProvider.accentColor,
              unselectedItemColor: themeProvider.secondaryTextColor,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list_outlined),
                  activeIcon: Icon(Icons.list),
                  label: 'My List',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite_outline),
                  activeIcon: Icon(Icons.favorite),
                  label: 'Favorites',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}