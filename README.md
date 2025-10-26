# Coffee Finder App

A cross-platform mobile coffee shop finder application built with Flutter, available on Windows, Linux, iOS, and Android. Discover amazing coffee shops near you with detailed information, reviews, and navigation.

## Features

### 🗺️ **Map View**
- Interactive Google Maps with coffee shop locations
- Real-time nearby coffee shop discovery
- Color-coded markers for favorites
- Quick coffee shop cards showing essential info
- Search and filter functionality on map

### 📋 **List View**
- Comprehensive list of nearby coffee shops
- Advanced filtering by features (WiFi, outdoor seating, etc.)
- Sort by distance, rating, or name
- Detailed coffee shop cards with photos
- Pull-to-refresh functionality

### ☕ **Coffee Shop Details**
- Rich photo galleries with zoom functionality
- Customer reviews and ratings
- Operating hours with today's schedule highlighted
- Contact information (phone, website)
- Features and amenities
- One-tap navigation integration

### ⭐ **Favorites System**
- Save your favorite coffee shops
- Quick access to saved locations
- Visual indicators for favorited places

### 🔍 **Search & Discovery**
- Real-time search by name, address, or description
- Advanced filtering by features and amenities
- Distance-based sorting
- Search within selected area

### 🎨 **Modern UI/UX**
- Beautiful, coffee-themed design
- Smooth animations and transitions
- Responsive layout for all screen sizes
- Inter font for clean typography
- Coffee brown color scheme

## Technical Implementation

### Architecture
- **State Management**: Provider pattern for clean state management
- **Navigation**: Tab-based navigation with separate screens
- **Location Services**: Geolocator for GPS positioning
- **Maps Integration**: Google Maps Flutter for interactive maps
- **Image Caching**: Cached network images for optimal performance

### Dependencies
- `flutter`: Core Flutter framework
- `provider`: State management solution
- `google_maps_flutter`: Interactive map integration
- `geolocator`: GPS and location services
- `permission_handler`: Runtime permissions management
- `google_fonts`: Custom typography (Inter font)
- `cached_network_image`: Efficient image loading and caching
- `url_launcher`: External app integration (maps, phone, web)
- `http`: Network requests for future API integration

### Cross-Platform Support
✅ **Android** - Successfully built and tested
✅ **iOS** - Ready for deployment (requires iOS configuration)
✅ **Linux** - Successfully built and tested
✅ **Windows** - Ready for deployment
✅ **macOS** - Ready for deployment

## Sample Data

The app includes realistic sample data for 5 coffee shops in New York City:
- **Artisan Coffee Roasters** - Premium specialty coffee
- **The Daily Grind** - Cozy neighborhood spot
- **Café Lumière** - French-inspired elegant café
- **Brew & Bloom** - Sustainable and plant-based options
- **Central Perk Cafe** - Iconic comfortable seating

Each shop includes:
- Real addresses and coordinates
- Photos and descriptions
- Operating hours
- Customer reviews
- Features and amenities
- Distance calculations

## Getting Started

### Prerequisites
- Flutter SDK (>= 3.9.0)
- Dart SDK
- For mobile: Android Studio / Xcode
- For desktop: Visual Studio Code or similar
- Google Maps API key (for production use)

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd coffee_finder_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Google Maps (for production)**
   - Get a Google Maps API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Add the API key to your platform-specific configuration

4. **Run the app**
```bash
# For mobile
flutter run

# For specific platforms
flutter run -d android
flutter run -d ios
flutter run -d linux
flutter run -d windows
```

### Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Linux
flutter build linux --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

## App Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data models
│   └── coffee_shop.dart        # Coffee shop, review, and hours models
├── providers/                   # State management
│   └── coffee_shop_provider.dart # Coffee shop data provider
├── services/                    # Business logic
│   └── location_service.dart   # GPS and location utilities
├── screens/                     # UI screens
│   ├── map_screen.dart         # Interactive map view
│   ├── list_screen.dart        # Coffee shop list
│   ├── coffee_shop_detail_screen.dart # Detailed shop info
│   ├── favorites_screen.dart   # Saved coffee shops
│   └── profile_screen.dart     # User profile and settings
└── widgets/                     # Reusable components
```

## Design System

### Colors
- **Primary**: `#6F4E37` (Coffee Brown)
- **Background**: `#F8F8F8` (Light Grey)
- **Surface**: `#FFFFFF` (White)
- **Success**: `#4CAF50` (Green)
- **Error**: `#F44336` (Red)

### Typography
- **Font Family**: Inter (via Google Fonts)
- **Weights**: Regular (400), Medium (500), SemiBold (600), Bold (700)

### Components
- **Cards**: Rounded corners (16px), subtle shadows
- **Buttons**: Rounded corners (12px), consistent spacing
- **Icons**: Material Icons with coffee theme colors
- **Maps**: Custom markers with coffee cup styling

## Location Features

### GPS Integration
- Automatic location detection
- Distance calculations to coffee shops
- Location-based sorting
- Permission handling

### Map Functionality
- Interactive markers with coffee shop info
- Quick navigation to coffee shops
- Search and filter on map
- Real-time location updates

## Future Enhancements

### Backend Integration
- [ ] Real-time API integration with coffee shop databases
- [ ] User authentication and profiles
- [ ] Review submission and rating system
- [ ] Coffee shop submission for owners

### Advanced Features
- [ ] Route planning for coffee shop tours
- [ ] Social features (check-ins, sharing)
- [ ] Loyalty programs integration
- [ ] Coffee shop event listings
- [ ] Push notifications for nearby deals
- [ ] Offline maps functionality
- [ ] Augmented reality navigation

### Platform-Specific Features
- [ ] iOS: Apple Watch integration
- [ ] Android: Widget support
- [ ] Desktop: Enhanced keyboard shortcuts
- [ ] Web: Progressive Web App (PWA) version

## API Configuration

For production deployment, configure:

1. **Google Maps API Key**
   - Enable Maps SDK for Android/iOS
   - Enable Places API (for search)
   - Add API key to platform-specific files

2. **Platform Configuration**
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/AppDelegate.swift`
   - Web: `web/index.html`

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter's code style guidelines
- Use Provider pattern for state management
- Write widget tests for new features
- Ensure cross-platform compatibility
- Document new features and changes

## Performance Optimizations

- Image caching with `cached_network_image`
- Efficient list rendering with lazy loading
- Optimized map marker rendering
- Memory-efficient state management
- Tree-shaking for icon fonts (99.6% reduction achieved)

## Troubleshooting

### Common Issues

**Google Maps not showing**
- Ensure you have a valid API key
- Check platform-specific configuration
- Verify required APIs are enabled

**Location permission denied**
- Check app permissions on device
- Ensure location services are enabled
- Review permission handling code

**Build errors**
- Run `flutter clean` and `flutter pub get`
- Check Flutter version compatibility
- Review platform-specific requirements

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Open an issue on GitHub
- Check the [Flutter documentation](https://docs.flutter.dev/)
- Review the troubleshooting section above

---

**Built with ❤️ and ☕ using Flutter**