import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/list_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';
import 'providers/coffee_shop_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'services/simple_places_service.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/personal_tracking_service.dart';
import 'services/error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables first
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Environment variables loaded');

    // Debug: Print loaded API keys (masked for security)
    final placesKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
    final firebaseKey = dotenv.env['FIREBASE_API_KEY'];

    if (placesKey != null && placesKey.isNotEmpty) {
      print('✅ Google Places API key loaded (${placesKey.substring(0, 10)}...)');
    } else {
      print('❌ Google Places API key not found or empty');
    }

    if (firebaseKey != null && firebaseKey.isNotEmpty) {
      print('✅ Firebase API key loaded (${firebaseKey.substring(0, 10)}...)');
    } else {
      print('⚠️ Firebase API key not found or empty');
    }
  } catch (e) {
    print('❌ Failed to load .env file: $e');
    print('⚠️ Make sure .env file exists and is in the correct location');
  }

  // Initialize Firebase second (after env is loaded)
  try {
    await FirebaseService.initialize();
    print('✅ Firebase initialized');
  } catch (e) {
    print('⚠️ Warning: Firebase initialization failed: $e');
    print('🔄 Continuing without Firebase...');
  }

  // Initialize Google Sign-In
  try {
    AuthService.initializeGoogleSignIn();
    print('✅ Google Sign-In initialized');
  } catch (e) {
    print('⚠️ Warning: Google Sign-In initialization failed: $e');
  }

  // Initialize Places service last (after Firebase)
  try {
    SimplePlacesService.initialize();

    // Verify initialization
    if (SimplePlacesService.isInitialized) {
      print('✅ Places API initialized successfully');
    } else {
      print('⚠️ Places API initialization failed - no API key available');
    }
  } catch (e) {
    print('❌ Places API initialization failed: $e');
    print('🔄 Using offline data fallback...');
  }

  // Auto-sync user data on app startup if user is logged in
  await _autoSyncUserData();

  runApp(const CoffeeFinderApp());
}

/// Auto-sync user data from Firebase to local storage on app startup
Future<void> _autoSyncUserData() async {
  try {
    print('🔄 Checking for existing user session...');

    // Wait a bit for Firebase to fully initialize
    await Future.delayed(Duration(milliseconds: 500));

    // Check if user is logged in
    if (FirebaseService.isLoggedIn) {
      final userId = FirebaseService.currentUser!.uid;
      print('✅ User session found: $userId');

      // Sync data from Firebase to local storage
      try {
        final trackingService = PersonalTrackingService();
        await trackingService.syncFromCloudToLocal(userId);
        print('✅ User data auto-synced from Firebase');
      } catch (e) {
        print('⚠️ Warning: Auto-sync failed: $e');
        print('🔄 Continuing with local data...');
      }
    } else {
      print('ℹ️ No existing user session found');
    }
  } catch (e) {
    print('❌ Auto-sync error: $e');
    print('🔄 App will continue without auto-sync');
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

  final List<String> _titles = [
    'Coffee Finder',
    'My List',
    'Favorites',
    'Profile',
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
                  color: Colors.black.withOpacity(0.1),
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