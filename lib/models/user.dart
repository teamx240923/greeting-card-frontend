class User {
  final String id;
  final DateTime createdAt;
  final bool isGuest;
  final List<String> deviceIds;
  final String authType;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? role;
  final String? avatarUrl;
  final String? brandColor;
  final String qrType;
  final String? qrValue;

  User({
    required this.id,
    required this.createdAt,
    required this.isGuest,
    required this.deviceIds,
    required this.authType,
    this.email,
    this.phone,
    this.displayName,
    this.role,
    this.avatarUrl,
    this.brandColor,
    required this.qrType,
    this.qrValue,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      isGuest: json['is_guest'],
      deviceIds: List<String>.from(json['device_ids'] ?? []),
      authType: json['auth_type'],
      email: json['email'],
      phone: json['phone'],
      displayName: json['display_name'],
      role: json['role'],
      avatarUrl: json['avatar_url'],
      brandColor: json['brand_color'],
      qrType: json['qr_type'] ?? 'none',
      qrValue: json['qr_value'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'is_guest': isGuest,
      'device_ids': deviceIds,
      'auth_type': authType,
      'email': email,
      'phone': phone,
      'display_name': displayName,
      'role': role,
      'avatar_url': avatarUrl,
      'brand_color': brandColor,
      'qr_type': qrType,
      'qr_value': qrValue,
    };
  }

  User copyWith({
    String? id,
    DateTime? createdAt,
    bool? isGuest,
    List<String>? deviceIds,
    String? authType,
    String? email,
    String? phone,
    String? displayName,
    String? role,
    String? avatarUrl,
    String? brandColor,
    String? qrType,
    String? qrValue,
  }) {
    return User(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      isGuest: isGuest ?? this.isGuest,
      deviceIds: deviceIds ?? this.deviceIds,
      authType: authType ?? this.authType,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      brandColor: brandColor ?? this.brandColor,
      qrType: qrType ?? this.qrType,
      qrValue: qrValue ?? this.qrValue,
    );
  }
}
