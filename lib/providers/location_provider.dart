import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_context.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class LocationState {
  final LocationContext? location;
  final bool isLoading;
  final String? error;
  final bool isDetecting;

  LocationState({
    this.location,
    this.isLoading = false,
    this.error,
    this.isDetecting = false,
  });

  LocationState copyWith({
    LocationContext? location,
    bool? isLoading,
    String? error,
    bool? isDetecting,
  }) {
    return LocationState(
      location: location ?? this.location,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isDetecting: isDetecting ?? this.isDetecting,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(LocationState()) {
    _detectLocationOnStart();
  }

  Future<void> _detectLocationOnStart() async {
    print('🔍 LocationProvider: Starting location detection...');
    state = state.copyWith(isDetecting: true);
    
    try {
      // Check for cached location first
      print('🔍 LocationProvider: Checking for cached location...');
      final cachedLocation = await _locationService.getCachedLocation();
      
      if (cachedLocation != null && !_locationService.shouldRefreshLocation(cachedLocation)) {
        print('🔍 LocationProvider: Using cached location: ${cachedLocation.city}, ${cachedLocation.country}');
        state = state.copyWith(
          location: cachedLocation,
          isDetecting: false,
        );
        return;
      }
      
      // Detect fresh location
      print('🔍 LocationProvider: Detecting fresh location...');
      final location = await _locationService.detectLocation();
      
      // Cache the location
      print('🔍 LocationProvider: Caching new location...');
      await _locationService.cacheLocation(location);
      
      print('🔍 LocationProvider: Location detection completed: ${location.city}, ${location.country}');
      state = state.copyWith(
        location: location,
        isDetecting: false,
      );
    } catch (e) {
      print('❌ LocationProvider: Error in location detection: $e');
      state = state.copyWith(
        error: e.toString(),
        isDetecting: false,
      );
    }
  }

  Future<void> refreshLocation() async {
    print('🔄 LocationProvider: Refreshing location...');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('🔄 LocationProvider: Detecting fresh location...');
      final location = await _locationService.detectLocation();
      
      print('🔄 LocationProvider: Caching refreshed location...');
      await _locationService.cacheLocation(location);
      
      print('🔄 LocationProvider: Location refresh completed: ${location.city}, ${location.country}');
      state = state.copyWith(
        location: location,
        isLoading: false,
      );
    } catch (e) {
      print('❌ LocationProvider: Error refreshing location: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void setLocation(LocationContext location) {
    state = state.copyWith(location: location);
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier(ref.read(locationServiceProvider));
});
