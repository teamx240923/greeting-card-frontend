import '../config/api_config.dart';

class UrlUtils {
  /// Convert relative image URL to full URL
  static String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    // If it's already a full URL (starts with http), return as is
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    // If it's a relative path, prepend the base URL
    if (imageUrl.startsWith('/')) {
      return '${ApiConfig.baseUrl}$imageUrl';
    }
    
    // If it doesn't start with /, add it
    return '${ApiConfig.baseUrl}/$imageUrl';
  }
  
  /// Convert relative thumbnail URL to full URL
  static String getFullThumbnailUrl(String? thumbUrl) {
    return getFullImageUrl(thumbUrl);
  }
  
  /// Check if URL is valid
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http') || url.startsWith('/');
  }
}
