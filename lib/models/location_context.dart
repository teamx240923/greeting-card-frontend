class LocationContext {
  final List<String> source;
  final String country;
  final String? region;
  final String? city;
  final String? locale;
  final double confidence;

  LocationContext({
    required this.source,
    required this.country,
    this.region,
    this.city,
    this.locale,
    required this.confidence,
  });

  factory LocationContext.fromJson(Map<String, dynamic> json) {
    return LocationContext(
      source: List<String>.from(json['source'] ?? []),
      country: json['country'] ?? '',
      region: json['region'],
      city: json['city'],
      locale: json['locale'],
      confidence: (json['confidence'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'country': country,
      'region': region,
      'city': city,
      'locale': locale,
      'confidence': confidence,
    };
  }

  String get locationHeader {
    final parts = <String>['country=$country'];
    if (region != null) parts.add('region=$region');
    if (city != null) parts.add('city=$city');
    parts.add('conf=${confidence.toStringAsFixed(2)}');
    return parts.join(';');
  }

  LocationContext copyWith({
    List<String>? source,
    String? country,
    String? region,
    String? city,
    String? locale,
    double? confidence,
  }) {
    return LocationContext(
      source: source ?? this.source,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      locale: locale ?? this.locale,
      confidence: confidence ?? this.confidence,
    );
  }
}

class ClientLocationSignals {
  final String? carrierIso;
  final String? simIso;
  final String? mcc;
  final String? mnc;
  final String? systemLocale;
  final String? timezone;
  final int? timezoneOffset;

  ClientLocationSignals({
    this.carrierIso,
    this.simIso,
    this.mcc,
    this.mnc,
    this.systemLocale,
    this.timezone,
    this.timezoneOffset,
  });

  ClientLocationSignals copyWith({
    String? carrierIso,
    String? simIso,
    String? mcc,
    String? mnc,
    String? systemLocale,
    String? timezone,
    int? timezoneOffset,
  }) {
    return ClientLocationSignals(
      carrierIso: carrierIso ?? this.carrierIso,
      simIso: simIso ?? this.simIso,
      mcc: mcc ?? this.mcc,
      mnc: mnc ?? this.mnc,
      systemLocale: systemLocale ?? this.systemLocale,
      timezone: timezone ?? this.timezone,
      timezoneOffset: timezoneOffset ?? this.timezoneOffset,
    );
  }

  factory ClientLocationSignals.fromJson(Map<String, dynamic> json) {
    return ClientLocationSignals(
      carrierIso: json['carrier_iso'],
      simIso: json['sim_iso'],
      mcc: json['mcc'],
      mnc: json['mnc'],
      systemLocale: json['system_locale'],
      timezone: json['timezone'],
      timezoneOffset: json['timezone_offset'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carrier_iso': carrierIso,
      'sim_iso': simIso,
      'mcc': mcc,
      'mnc': mnc,
      'system_locale': systemLocale,
      'timezone': timezone,
      'timezone_offset': timezoneOffset,
    };
  }
}
