import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  static const String _tokenKey = 'jwt_token';

  // ✅ Add this constant for your deployed backend
  static const String productionBaseUrl = 'https://aura-backend-5j69.onrender.com';

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: _getBaseUrl(),
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: _tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Handle global errors like 401 Unauthorized
        if (e.response?.statusCode == 401) {
          await _storage.delete(key: _tokenKey);
          // TODO: Trigger logout event
        }
        return handler.next(e);
      },
    ));
  }

  String _getBaseUrl() {
    // ✅ FOR PRODUCTION APK - Use deployed backend
    // For release builds, use the production URL
    if (kReleaseMode) {
      return productionBaseUrl;
    }

    // For development/debug builds
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        // For emulator, use 10.0.2.2
        // For physical device on same WiFi, use your local IP
        // return 'http://192.168.1.100:8000'; // Uncomment for local testing
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  String get wsBaseUrl {
    final httpUrl = _getBaseUrl();
    // Replace http:// with ws:// and https:// with wss://
    if (httpUrl.startsWith('https://')) {
      return httpUrl.replaceFirst('https://', 'wss://');
    } else if (httpUrl.startsWith('http://')) {
      return httpUrl.replaceFirst('http://', 'ws://');
    }
    return httpUrl;
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
}