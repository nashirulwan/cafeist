# Cafeist

A Flutter mobile application for coffee shop listing and tracking, inspired by platforms like MyAnimeList and GoodReads. Cafeist combines cafe discovery with personal tracking capabilities, designed for coffee enthusiasts who want to keep a detailed record of their cafe visits and experiences.

## Project Overview

Cafeist is essentially a "cafe list" application that allows users to discover, track, and manage their coffee shop experiences. The app serves as a personal database for cafe visits, similar to how book lovers track their reading or anime fans track their watched series. While currently using sample data from Malang area, the application is designed for real-time API integration to provide live cafe information and user-generated content.

## Features & Pages

### Home Screen
- Interactive search functionality for coffee shops
- Map view placeholder (ready for Google Maps API integration)
- List of nearby coffee shops with distance calculation
- Real-time favorite toggle functionality
- Coffee shop status indicators (open/closed)

### My List Screen
Core tracking system inspired by listing platforms like MyAnimeList and GoodReads:
- Want to Visit: Personal wishlist of cafes to explore
- Visited: Complete history of cafe visits with detailed tracking
- Not Tracked: All available cafes for discovery
- Visit date tracking and chronological history
- Personal ratings and private reviews for each visit
- Visit frequency tracking and statistics

### Favorites Screen
- Quick access to saved coffee shops
- Favorite toggle functionality
- Detailed information cards
- Sortable by distance or rating

### Profile Screen
- User profile interface
- Dark/Light theme toggle
- App preferences and settings
- Support and about sections

## Technical Architecture

### State Management
- Provider pattern for reactive state management
- Separate providers for coffee shop data and theme management
- Real-time UI updates with Consumer widgets

### Data Management
- JSON-based data loading from assets
- Clean data models with proper parsing
- Location-based distance calculations
- Error handling for data loading failures

### UI/UX Design
- Material 3 design system implementation
- Coffee-themed color scheme (#6F4E37 primary brown)
- Responsive layouts for various screen sizes
- Dark mode support with proper theme switching
- Clean typography using Inter font family

## Getting Started

### Prerequisites
- Flutter SDK (version 3.9.0 or higher)
- Dart SDK
- Android Studio or VS Code
- For mobile: Android emulator or physical device
- For desktop: Windows/Linux/macOS development environment

### Installation Steps

1. **Clone the repository**
   ```bash
   git clone <https://github.com/nashirulwan/cafeist.git>
   cd cafeist
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   # For mobile devices
   flutter run

   # For specific platform
   flutter run -d android
   flutter run -d windows
   flutter run -d linux
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

## Project Structure

```
lib/
├── main.dart                    # Application entry point
├── models/
│   └── coffee_shop.dart        # Data models for coffee shops
├── providers/
│   ├── coffee_shop_provider.dart # Coffee shop state management
│   └── theme_provider.dart     # Theme management
├── services/
│   └── location_service.dart   # Location and GPS utilities
├── screens/
│   ├── map_screen_safe.dart    # Home screen with search
│   ├── list_screen.dart        # Coffee shop list management
│   ├── favorites_screen.dart   # Favorite coffee shops
│   ├── profile_screen.dart     # User profile and settings
│   └── coffee_shop_detail_screen.dart # Detailed shop information
├── widgets/
│   └── add_visit_dialog.dart   # Visit tracking dialog
└── assets/
    └── data/
        └── coffee_shops.json   # Sample data file
```

## Sample Data

The application includes sample data for 5 coffee shops in Malang:

- **And Coffee Space Malang**
- **Lafayette Coffee Malang**
- **Motiv Coffee Malang**
- **TW Cafe & Eatery Malang**
- **Lifika Cafe Malang**

Each coffee shop includes:
- Real addresses and coordinates
- Photos and detailed descriptions
- Operating hours
- Customer reviews and ratings
- Contact information
- Distance calculations from user location

## Dependencies

### Core Framework
- `flutter`: Main Flutter framework
- `provider`: State management solution

### UI & Design
- `google_fonts`: Custom typography (Inter font)
- `cached_network_image`: Efficient image loading

### Functionality
- `geolocator`: GPS and location services
- `permission_handler`: Runtime permissions
- `url_launcher`: External app integration

## Configuration Notes

### Google Maps Integration
The app includes a placeholder map view ready for Google Maps API integration. To enable full map functionality:

1. Obtain Google Maps API key from Google Cloud Console
2. Configure platform-specific API key placement
3. Replace map placeholder with actual Google Maps widget

### Theme Customization
The app features a comprehensive theme system:
- Light theme with coffee brown accent colors
- Dark theme optimized for low-light usage
- Theme persistence using SharedPreferences
- Material 3 design system compliance

## Performance Considerations

- Efficient image caching to reduce network requests
- Lazy loading for coffee shop lists
- Optimized state management to prevent unnecessary rebuilds
- Memory-conscious data structures
- Cross-platform compatibility maintained throughout development

## Future Enhancements

### API Integration & Real-time Features
- Live API connection for real-time cafe data updates
- User authentication system for personal accounts
- Community-driven reviews and ratings
- Cafe owner dashboard for information management
- Social features: follow friends, share lists, compare tastes

### Advanced Listing Features
- Detailed visit statistics and analytics
- Cafe recommendation algorithm based on preferences
- Community challenges and achievements
- Integration with social media platforms
- Export/import functionality for cafe lists
- Advanced filtering: by coffee type, atmosphere, price range

## Platform Support

- ✅ Android - Fully tested and functional
- ✅ Windows - Ready for deployment
- ✅ Linux - Ready for deployment
- ✅ iOS - Configuration ready, requires Apple Developer account
- ✅ macOS - Ready for deployment