import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      // Web platform - use localhost
      return 'http://localhost:8000';
    } else if (Platform.isAndroid || Platform.isIOS) {
      // Mobile platform - use machine IP
      return 'http://192.168.1.4:8000';
    } else {
      // Desktop platform - use localhost
      return 'http://localhost:8000';
    }
  }
  
  static String get feedUrl => '$baseUrl/v1/feed';
  static String get interactionUrl => '$baseUrl/v1/feed/interaction';
  static String get locationUrl => '$baseUrl/v1/loc/resolve';
  static String get healthUrl => '$baseUrl/health';
  
  static void printConfig() {
    // Platform detection for API configuration
    // Web: localhost:8000, Mobile: 192.168.1.4:8000
  }
}
