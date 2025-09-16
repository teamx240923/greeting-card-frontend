import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../models/user.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => 
    const FlutterSecureStorage());

final deviceInfoProvider = Provider<DeviceInfoPlugin>((ref) => DeviceInfoPlugin());

class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo;

  AuthNotifier(this._apiService, this._storage, this._deviceInfo) 
      : super(AuthState()) {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        _apiService.setAuthToken(token);
        // In a real app, you'd validate the token with the server
        // For now, we'll just store it and assume it's valid
        state = state.copyWith(
          token: token,
          isLoading: false,
        );
      } else {
        await _createGuestSession();
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> _createGuestSession() async {
    try {
      final deviceId = await _getDeviceId();
      final response = await _apiService.createGuestSession(
        deviceId: deviceId,
      );
      
      final user = User.fromJson(response['user']);
      final token = response['access_token'];
      
      await _storage.write(key: 'auth_token', value: token);
      _apiService.setAuthToken(token);
      
      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      // Fallback to a random UUID if device info fails
    }
    return 'unknown_device';
  }

  Future<void> upgradeAccount({
    required String authType,
    String? email,
    String? phone,
    String? displayName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.upgradeAccount(
        authType: authType,
        email: email,
        phone: phone,
        displayName: displayName,
      );
      
      final user = User.fromJson(response['user']);
      final token = response['access_token'];
      
      await _storage.write(key: 'auth_token', value: token);
      _apiService.setAuthToken(token);
      
      state = state.copyWith(
        user: user,
        token: token,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _apiService.clearAuthToken();
    state = AuthState();
    await _createGuestSession();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.read(apiServiceProvider),
    ref.read(secureStorageProvider),
    ref.read(deviceInfoProvider),
  );
});
