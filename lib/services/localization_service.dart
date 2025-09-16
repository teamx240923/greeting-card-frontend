import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/location_context.dart';

class LocalizationService {
  static const Map<String, Locale> _countryLocaleMap = {
    'IN': Locale('hi', 'IN'),
    'US': Locale('en', 'US'),
    'GB': Locale('en', 'GB'),
    'CA': Locale('en', 'CA'),
    'AU': Locale('en', 'AU'),
    'DE': Locale('de', 'DE'),
    'FR': Locale('fr', 'FR'),
    'ES': Locale('es', 'ES'),
    'IT': Locale('it', 'IT'),
    'PT': Locale('pt', 'PT'),
    'BR': Locale('pt', 'BR'),
    'RU': Locale('ru', 'RU'),
    'CN': Locale('zh', 'CN'),
    'JP': Locale('ja', 'JP'),
    'KR': Locale('ko', 'KR'),
  };

  static const Map<String, String> _countryCurrencyMap = {
    'IN': '₹',
    'US': '\$',
    'GB': '£',
    'EU': '€',
    'JP': '¥',
    'KR': '₩',
    'CN': '¥',
    'RU': '₽',
  };

  static const Map<String, String> _countryDateFormatMap = {
    'IN': 'dd-MMM-yyyy',
    'US': 'MMM dd, yyyy',
    'GB': 'dd MMM yyyy',
    'DE': 'dd.MM.yyyy',
    'FR': 'dd/MM/yyyy',
    'ES': 'dd/MM/yyyy',
    'IT': 'dd/MM/yyyy',
    'JP': 'yyyy/MM/dd',
    'KR': 'yyyy.MM.dd',
    'CN': 'yyyy-MM-dd',
  };

  static Future<void> initialize() async {
    await initializeDateFormatting();
  }

  static Locale getLocaleForLocation(LocationContext? location) {
    if (location?.locale != null) {
      final parts = location!.locale!.split('-');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      }
    }

    if (location?.country != null) {
      return _countryLocaleMap[location!.country] ?? const Locale('en', 'US');
    }

    return const Locale('en', 'US');
  }

  static String getCurrencySymbol(String? country) {
    if (country == null) return '\$';
    return _countryCurrencyMap[country] ?? '\$';
  }

  static String getDateFormat(String? country) {
    if (country == null) return 'MMM dd, yyyy';
    return _countryDateFormatMap[country] ?? 'MMM dd, yyyy';
  }

  static String formatDate(DateTime date, String? country) {
    final format = getDateFormat(country);
    return DateFormat(format).format(date);
  }

  static String formatNumber(double number, String? country) {
    final formatter = NumberFormat.currency(
      symbol: getCurrencySymbol(country),
      decimalDigits: 2,
    );
    return formatter.format(number);
  }

  static String getLocalizedString(String key, String? country) {
    // In a real app, this would load from translation files
    final translations = _getTranslations(country);
    return translations[key] ?? key;
  }

  static Map<String, String> _getTranslations(String? country) {
    // Sample translations - in a real app, these would be loaded from JSON files
    switch (country) {
      case 'IN':
        return {
          'good_morning': 'सुप्रभात',
          'good_evening': 'शुभ संध्या',
          'happy_birthday': 'जन्मदिन की शुभकामनाएं',
          'congratulations': 'बधाई हो',
          'thank_you': 'धन्यवाद',
          'welcome': 'स्वागत है',
          'good_luck': 'शुभकामनाएं',
          'festival_greetings': 'त्योहार की शुभकामनाएं',
        };
      case 'DE':
        return {
          'good_morning': 'Guten Morgen',
          'good_evening': 'Guten Abend',
          'happy_birthday': 'Alles Gute zum Geburtstag',
          'congratulations': 'Herzlichen Glückwunsch',
          'thank_you': 'Danke',
          'welcome': 'Willkommen',
          'good_luck': 'Viel Glück',
          'festival_greetings': 'Festliche Grüße',
        };
      case 'FR':
        return {
          'good_morning': 'Bonjour',
          'good_evening': 'Bonsoir',
          'happy_birthday': 'Joyeux anniversaire',
          'congratulations': 'Félicitations',
          'thank_you': 'Merci',
          'welcome': 'Bienvenue',
          'good_luck': 'Bonne chance',
          'festival_greetings': 'Vœux de fête',
        };
      case 'ES':
        return {
          'good_morning': 'Buenos días',
          'good_evening': 'Buenas tardes',
          'happy_birthday': 'Feliz cumpleaños',
          'congratulations': 'Felicidades',
          'thank_you': 'Gracias',
          'welcome': 'Bienvenido',
          'good_luck': 'Buena suerte',
          'festival_greetings': 'Saludos festivos',
        };
      default:
        return {
          'good_morning': 'Good Morning',
          'good_evening': 'Good Evening',
          'happy_birthday': 'Happy Birthday',
          'congratulations': 'Congratulations',
          'thank_you': 'Thank You',
          'welcome': 'Welcome',
          'good_luck': 'Good Luck',
          'festival_greetings': 'Festival Greetings',
        };
    }
  }

  static List<String> getRegionalOccasions(String? country, String? region) {
    // Regional occasions based on country and region
    final occasions = <String>[];
    
    if (country == 'IN') {
      occasions.addAll([
        'Good Morning',
        'Good Evening',
        'Happy Birthday',
        'Congratulations',
        'Thank You',
        'Welcome',
        'Good Luck',
      ]);
      
      if (region == 'MH') {
        occasions.addAll([
          'Ganesh Chaturthi',
          'Dussehra',
          'Diwali',
        ]);
      } else if (region == 'TN') {
        occasions.addAll([
          'Pongal',
          'Ganesh Chaturthi',
          'Dussehra',
        ]);
      } else if (region == 'KL') {
        occasions.addAll([
          'Onam',
          'Dussehra',
        ]);
      } else if (region == 'PB') {
        occasions.addAll([
          'Gurpurab',
          'Holi',
        ]);
      }
    } else {
      // Global occasions
      occasions.addAll([
        'Good Morning',
        'Good Evening',
        'Happy Birthday',
        'Congratulations',
        'Thank You',
        'Welcome',
        'Good Luck',
        'Christmas',
        'New Year',
        'Valentine\'s Day',
        'Mother\'s Day',
        'Father\'s Day',
      ]);
    }
    
    return occasions;
  }

  static String getRegionalColor(String? country, String? region) {
    // Regional color preferences
    if (country == 'IN') {
      switch (region) {
        case 'MH':
          return '#FF6B6B'; // Orange for Maharashtra
        case 'TN':
          return '#4ECDC4'; // Teal for Tamil Nadu
        case 'KL':
          return '#45B7D1'; // Blue for Kerala
        case 'PB':
          return '#FFA07A'; // Light Salmon for Punjab
        default:
          return '#FF6B6B'; // Default orange
      }
    }
    
    return '#FF6B6B'; // Default color
  }
}
