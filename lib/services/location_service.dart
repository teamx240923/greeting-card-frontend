import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_context.dart';
import 'api_service.dart';

class LocationService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final ApiService _apiService = ApiService();
  
  // Simple in-memory cache for location
  LocationContext? _cachedLocation;
  DateTime? _lastLocationUpdate;

  Future<LocationContext> detectLocation() async {
    try {
      print('🔍 LocationService: Starting progressive location detection...');
      
      // Step 1: Try GPS-based detection first (most accurate)
      final gpsLocation = await _tryGpsLocation();
      if (gpsLocation != null) {
        print('✅ GPS location detected successfully');
        return gpsLocation;
      }
      
      // Step 2: Fallback to mobile tower + IP detection
      print('📡 Falling back to mobile tower + IP detection...');
      final towerLocation = await _tryTowerLocation();
      if (towerLocation != null) {
        print('✅ Tower location detected successfully');
        return towerLocation;
      }
      
      // Step 3: Basic locale-based detection
      print('🌐 Using basic locale detection...');
      return await _fallbackLocationDetection();
      
    } catch (e) {
      print('❌ LocationService: Error in location detection: $e');
      return await _fallbackLocationDetection();
    }
  }

  Future<LocationContext?> _tryGpsLocation() async {
    try {
      print('📍 LocationService: Attempting GPS location detection...');
      
      // Check if GPS permission is available
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        print('📱 GPS permission not granted, skipping GPS detection');
        return null;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('📱 Location services disabled, skipping GPS detection');
        return null;
      }

      // Get current position with timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Balance between accuracy and speed
        timeLimit: Duration(seconds: 10), // Don't wait too long
      );

      print('📍 GPS coordinates: ${position.latitude}, ${position.longitude}');
      print('📍 GPS accuracy: ${position.accuracy} meters');
      
      // Send GPS coordinates to backend for reverse geocoding
      final response = await _apiService.resolveLocationWithGps(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
      );
      
      final locationContext = LocationContext.fromJson(response['location']);
      print('🌍 GPS Location resolved:');
      print('   Country: ${locationContext.country}');
      print('   Region: ${locationContext.region}');
      print('   City: ${locationContext.city}');
      print('   Confidence: ${locationContext.confidence}');
      print('   Sources: ${locationContext.source}');
      
      // Log detected city prominently
      if (locationContext.city != null && locationContext.city!.isNotEmpty) {
        print('🏙️ GPS DETECTED CITY: ${locationContext.city}');
        print('🏙️ GPS City Confidence: ${locationContext.confidence}');
        print('🏙️ GPS City Sources: ${locationContext.source}');
      } else {
        print('⚠️ No city detected from GPS coordinates');
        print('📍 GPS Fallback Location: ${locationContext.region ?? locationContext.country}');
      }
      
      return locationContext;
      
    } catch (e) {
      print('❌ GPS location detection failed: $e');
      return null;
    }
  }

  Future<LocationContext?> _tryTowerLocation() async {
    try {
      print('📡 LocationService: Attempting mobile tower + IP detection...');
      
      // Collect client signals
      final signals = await _collectLocationSignals();
      print('📱 LocationService: Collected client signals:');
      print('   System Locale: ${signals.systemLocale}');
      print('   Timezone: ${signals.timezone}');
      print('   Timezone Offset: ${signals.timezoneOffset}');
      print('   Carrier ISO: ${signals.carrierIso}');
      print('   SIM ISO: ${signals.simIso}');
      
      // Send to backend for fusion
      print('🌐 LocationService: Sending signals to backend...');
      final response = await _apiService.resolveLocation(signals);
      print('✅ LocationService: Backend response received');
      
      final locationContext = LocationContext.fromJson(response['location']);
      print('🌍 LocationService: Parsed location context:');
      print('   Country: ${locationContext.country}');
      print('   Region: ${locationContext.region}');
      print('   City: ${locationContext.city}');
      print('   Confidence: ${locationContext.confidence}');
      print('   Locale: ${locationContext.locale}');
      print('   Sources: ${locationContext.source}');
      
      // Log detected city prominently
      if (locationContext.city != null && locationContext.city!.isNotEmpty) {
        print('🏙️ TOWER DETECTED CITY: ${locationContext.city}');
        print('🏙️ Tower City Confidence: ${locationContext.confidence}');
        print('🏙️ Tower City Sources: ${locationContext.source}');
      } else {
        print('⚠️ No city detected from mobile tower + IP');
        print('📍 Tower Fallback Location: ${locationContext.region ?? locationContext.country}');
      }
      
      return locationContext;
      
    } catch (e) {
      print('❌ Tower location detection failed: $e');
      return null;
    }
  }

  Future<ClientLocationSignals> _collectLocationSignals() async {
    try {
      // Get system locale
      final locale = Platform.localeName;
      
      // Get timezone
      final now = DateTime.now();
      final timezone = now.timeZoneName;
      final timezoneOffset = now.timeZoneOffset.inMinutes;
      
      // Try to get carrier info (requires platform channel for detailed info)
      // For now, we'll use basic device info
      final carrierIso = await _getCarrierIso();
      final simIso = await _getSimIso();
      
      return ClientLocationSignals(
        systemLocale: locale,
        timezone: timezone,
        timezoneOffset: timezoneOffset,
        carrierIso: carrierIso,
        simIso: simIso,
      );
    } catch (e) {
      // Handle errors gracefully
      // Silently handle location signal collection failures
      return ClientLocationSignals();
    }
  }

  Future<String?> _getCarrierIso() async {
    try {
      // This would require a platform channel to access TelephonyManager
      // For now, return null - the backend will use IP geolocation
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _getSimIso() async {
    try {
      // This would require a platform channel to access TelephonyManager
      // For now, return null - the backend will use IP geolocation
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<LocationContext> _fallbackLocationDetection() async {
    print('🌐 LocationService: Using basic locale fallback detection...');
    
    // Fallback based on system locale
    final locale = Platform.localeName;
    final country = _extractCountryFromLocale(locale);
    
    print('🌐 Fallback location:');
    print('   Country: $country');
    print('   Locale: $locale');
    print('   Confidence: 0.3 (low)');
    
    return LocationContext(
      source: ['locale'],
      country: country,
      locale: locale,
      confidence: 0.3, // Low confidence for fallback
    );
  }

  String _extractCountryFromLocale(String locale) {
    // Extract country code from locale (e.g., 'hi-IN' -> 'IN')
    if (locale.contains('-')) {
      return locale.split('-').last;
    }
    
    // Default mappings for common locales
    final localeCountryMap = {
      'en': 'US',
      'hi': 'IN',
      'ta': 'IN',
      'te': 'IN',
      'bn': 'IN',
      'mr': 'IN',
      'gu': 'IN',
      'kn': 'IN',
      'ml': 'IN',
      'pa': 'IN',
      'or': 'IN',
      'de': 'DE',
      'fr': 'FR',
      'es': 'ES',
      'it': 'IT',
      'pt': 'PT',
      'ru': 'RU',
      'zh': 'CN',
      'ja': 'JP',
      'ko': 'KR',
    };
    
    final language = locale.split('-').first;
    return localeCountryMap[language] ?? 'US';
  }

  Future<void> cacheLocation(LocationContext location) async {
    print('💾 LocationService: Caching location...');
    print('💾 Cached: ${location.city}, ${location.country} (confidence: ${location.confidence})');
    
    _cachedLocation = location;
    _lastLocationUpdate = DateTime.now();
  }

  Future<LocationContext?> getCachedLocation() async {
    print('💾 LocationService: Getting cached location...');
    if (_cachedLocation != null) {
      print('💾 Cached location found: ${_cachedLocation!.city}, ${_cachedLocation!.country}');
      return _cachedLocation;
    }
    print('💾 No cached location found');
    return null;
  }

  bool shouldRefreshLocation(LocationContext? cachedLocation) {
    if (cachedLocation == null) {
      print('💾 No cached location, should refresh');
      return true;
    }
    
    // Refresh if location is older than 1 hour
    if (_lastLocationUpdate == null) {
      print('💾 No last update time, should refresh');
      return true;
    }
    
    final now = DateTime.now();
    final timeDiff = now.difference(_lastLocationUpdate!);
    final shouldRefresh = timeDiff.inMinutes > 60; // 1 hour
    
    print('💾 Last location update: ${_lastLocationUpdate}');
    print('💾 Time difference: ${timeDiff.inMinutes} minutes');
    print('💾 Should refresh: $shouldRefresh');
    
    return shouldRefresh;
  }
}
