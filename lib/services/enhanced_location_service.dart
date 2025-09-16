import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/location_context.dart';
import 'api_service.dart';

class EnhancedLocationService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final ApiService _apiService = ApiService();

  Future<LocationContext> detectLocation() async {
    try {
      print('🔍 EnhancedLocationService: Starting progressive location detection...');
      
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
      print('❌ EnhancedLocationService: Error in location detection: $e');
      return await _fallbackLocationDetection();
    }
  }

  Future<LocationContext?> _tryGpsLocation() async {
    try {
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

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // Balance between accuracy and speed
        timeLimit: Duration(seconds: 10), // Don't wait too long
      );

      print('📍 GPS coordinates: ${position.latitude}, ${position.longitude}');
      
      // Send GPS coordinates to backend for reverse geocoding
      final response = await _apiService.resolveLocationWithGps(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      
      return LocationContext.fromJson(response['location']);
      
    } catch (e) {
      print('❌ GPS location detection failed: $e');
      return null;
    }
  }

  Future<LocationContext?> _tryTowerLocation() async {
    try {
      // Collect mobile tower signals
      final signals = await _collectTowerSignals();
      print('📱 Tower signals collected: ${signals.toString()}');
      
      // Send to backend for fusion
      final response = await _apiService.resolveLocation(signals);
      return LocationContext.fromJson(response['location']);
      
    } catch (e) {
      print('❌ Tower location detection failed: $e');
      return null;
    }
  }

  Future<ClientLocationSignals> _collectTowerSignals() async {
    try {
      // Get system locale
      final locale = Platform.localeName;
      
      // Get timezone
      final now = DateTime.now();
      final timezone = now.timeZoneName;
      final timezoneOffset = now.timeZoneOffset.inMinutes;
      
      // Try to get carrier info
      final carrierIso = await _getCarrierIso();
      final simIso = await _getSimIso();
      
      // Try to get cell tower info (if available)
      final cellInfo = await _getCellTowerInfo();
      
      return ClientLocationSignals(
        systemLocale: locale,
        timezone: timezone,
        timezoneOffset: timezoneOffset,
        carrierIso: carrierIso,
        simIso: simIso,
        // Add cell tower info if available
        mcc: cellInfo['mcc'],
        mnc: cellInfo['mnc'],
      );
    } catch (e) {
      print('❌ Failed to collect tower signals: $e');
      rethrow;
    }
  }

  Future<Map<String, String?>> _getCellTowerInfo() async {
    try {
      // This would require platform-specific implementation
      // For now, return empty values
      return {
        'mcc': null, // Mobile Country Code
        'mnc': null, // Mobile Network Code
      };
    } catch (e) {
      print('❌ Failed to get cell tower info: $e');
      return {'mcc': null, 'mnc': null};
    }
  }

  Future<String?> _getCarrierIso() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.version.release; // Use version.release instead
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.systemVersion; // This should work for iOS
      }
      return null;
    } catch (e) {
      print('❌ Failed to get carrier ISO: $e');
      return null;
    }
  }

  Future<String?> _getSimIso() async {
    try {
      // This would require platform-specific implementation
      // For now, return null
      return null;
    } catch (e) {
      print('❌ Failed to get SIM ISO: $e');
      return null;
    }
  }

  Future<LocationContext> _fallbackLocationDetection() async {
    // Basic fallback based on system locale
    final locale = Platform.localeName;
    final country = locale.split('_').last;
    
    return LocationContext(
      country: country,
      region: null,
      city: null,
      confidence: 0.3,
      locale: locale,
      source: ['fallback'],
    );
  }
}
