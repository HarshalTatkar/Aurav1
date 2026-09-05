import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/api_client.dart';
import '../data/models.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService();
  ref.onDispose(() {
    service.disconnect();
  });
  return service;
});

class SyncService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  
  final _sensorReadingController = StreamController<SensorReading>.broadcast();
  Stream<SensorReading> get onSensorReading => _sensorReadingController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    final token = await ApiClient().getToken();
    if (token == null) return; // Cannot connect without auth

    final wsUrl = Uri.parse('${ApiClient().wsBaseUrl}/ws/$token');
    
    try {
      _channel = WebSocketChannel.connect(wsUrl);
      _isConnected = true;
      
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      connect();
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      // print('WS Received: $data');
      
      if (data['type'] == 'user_sensor_update') {
        final payload = data['data'];
        final reading = SensorReading(
          deviceId: payload['device_id'] ?? 'unknown',
          timestamp: DateTime.parse(payload['timestamp']),
          heartRate: (payload['heart_rate'] as num?)?.toDouble() ?? 0,
          spo2: (payload['spo2'] as num?)?.toDouble() ?? 0,
          bodyTemperature: (payload['body_temperature'] as num?)?.toDouble() ?? 0,
          ambientTemperature: (payload['ambient_temperature'] as num?)?.toDouble() ?? 0,
          humidity: (payload['humidity'] as num?)?.toDouble() ?? 0,
          pm25: (payload['pm25'] as num?)?.toDouble() ?? 0,
          pm10: (payload['pm10'] as num?)?.toDouble() ?? 0,
          activityLevel: (payload['activity_level'] as num?)?.toDouble() ?? 0,
          fallDetected: payload['fall_detected'] ?? false,
          battery: payload['battery'],
        );
        _sensorReadingController.add(reading);
      }
      // Handle other alerts here...
    } catch (e) {
      print('WS Decode Error: $e');
    }
  }

  void syncReading(SensorReading reading, String deviceId) {
    if (!_isConnected || _channel == null) return;

    final payload = {
      'type': 'sensor_reading',
      'data': {
        'device_id': deviceId,
        'timestamp': reading.timestamp.toIso8601String(),
        'heart_rate': reading.heartRate,
        'spo2': reading.spo2,
        'body_temperature': reading.bodyTemperature,
        'ambient_temperature': reading.ambientTemperature,
        'humidity': reading.humidity,
        'pm25': reading.pm25,
        'pm10': reading.pm10,
        'activity_level': reading.activityLevel,
        'fall_detected': reading.fallDetected,
      }
    };

    _channel!.sink.add(jsonEncode(payload));
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }
  
  void dispose() {
    disconnect();
    _sensorReadingController.close();
  }

  Future<String?> fetchAiRecommendation() async {
    try {
      final response = await ApiClient().dio.post('/risk/analyze');
      return response.data['ai_recommendation'] as String?;
    } catch (e) {
      print('Failed to fetch AI recommendation: $e');
      return null;
    }
  }
}
